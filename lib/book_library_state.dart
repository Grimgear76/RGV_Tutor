import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/book.dart';
import 'services/book_catalog_service.dart';
import 'services/book_download_service.dart';
import 'services/connectivity_service.dart';

enum LibraryMode {
  online,
  offline;

  static LibraryMode fromId(String? id) {
    return switch (id) {
      'offline' => LibraryMode.offline,
      _ => LibraryMode.online,
    };
  }

  String get id => name;
}

class BookLibraryState extends ChangeNotifier {
  BookLibraryState({
    BookCatalogService? catalogService,
    BookDownloadService? downloadService,
    ConnectivityService? connectivityService,
  })  : _catalogService = catalogService ?? const BookCatalogService(),
         _downloadService = downloadService ?? const BookDownloadService(),
         _connectivityService = connectivityService ?? ConnectivityService();

  static const _boxName = 'book_library';
  static const _booksKey = 'booksById';
  static const _modeKey = 'mode';

  final BookCatalogService _catalogService;
  final BookDownloadService _downloadService;
  final ConnectivityService _connectivityService;

  late final Box _box;
  late final StreamSubscription _connectivitySub;

  Map<String, BookEntry> _booksById = {};
  List<BookEntry> catalog = const [];

  LibraryMode get mode => _mode;
  LibraryMode _mode = LibraryMode.online;

  bool get deviceOnline => _deviceOnline;
  bool _deviceOnline = true;

  bool get isOnline => _mode == LibraryMode.online && _deviceOnline;

  List<BookEntry> get downloaded {
    return _booksById.values.where((b) => b.isDownloaded).toList(growable: false);
  }

  List<BookEntry> get library {
    final items = _booksById.values.toList(growable: false);
    items.sort((a, b) {
      final aT = a.lastOpenedAt ?? a.addedAt;
      final bT = b.lastOpenedAt ?? b.addedAt;
      final byTime = bT.compareTo(aT);
      if (byTime != 0) return byTime;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return items;
  }

  BookEntry? byId(String id) => _booksById[id];

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _booksById = _loadBooks(_box.get(_booksKey, defaultValue: const <String, dynamic>{}));
    catalog = await _catalogService.loadCatalog();

    _mode = LibraryMode.fromId(_box.get(_modeKey) as String?);

    _deviceOnline = await _connectivityService.isOnline;
    _connectivitySub = _connectivityService.changes.listen((_) async {
      _deviceOnline = await _connectivityService.isOnline;
      notifyListeners();
    });

    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    _connectivityService.dispose();
    super.dispose();
  }

  Future<void> setMode(LibraryMode next) async {
    if (_mode == next) return;
    _mode = next;
    await _box.put(_modeKey, next.id);
    notifyListeners();
  }

  Future<void> addFromCatalog(BookEntry book) async {
    if (!isOnline) return;
    if (_booksById.containsKey(book.id)) return;
    final entry = book.copyWith(downloadState: BookDownloadState.notDownloaded);
    _booksById = {..._booksById, entry.id: entry};
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String bookId) async {
    final existing = _booksById[bookId];
    if (existing == null) return;
    await _downloadService.deleteLocalFiles(existing);
    _booksById = Map<String, BookEntry>.from(_booksById)..remove(bookId);
    await _persist();
    notifyListeners();
  }

  Future<void> download(String bookId) async {
    final book = _booksById[bookId];
    if (book == null) return;
    if (!isOnline) return;
    if (kIsWeb) {
      _booksById = {
        ..._booksById,
        bookId: book.copyWith(
          downloadState: BookDownloadState.failed,
          downloadProgress: null,
          error: 'Downloads are not supported on web. Run on Android/iOS/desktop.',
        ),
      };
      await _persist();
      notifyListeners();
      return;
    }

    final targetPath = await _downloadService.resolveBookPath(book);
    _booksById = {
      ..._booksById,
      bookId: book.copyWith(downloadState: BookDownloadState.downloading, downloadProgress: 0, error: null),
    };
    await _persist();
    notifyListeners();

    try {
      await for (final progress in _downloadService.downloadBook(book: book, targetPath: targetPath)) {
        final current = _booksById[bookId];
        if (current == null) return;
        _booksById = {
          ..._booksById,
          bookId: current.copyWith(downloadProgress: progress.fraction ?? 0),
        };
        notifyListeners();
      }

      final bytes = await _downloadService.fileSize(targetPath);
      final coverPath = await _downloadService.downloadCover(book: book);

      final current = _booksById[bookId];
      if (current == null) return;
      _booksById = {
        ..._booksById,
        bookId: current.copyWith(
          downloadState: BookDownloadState.downloaded,
          downloadProgress: 1,
          localPath: targetPath,
          localCoverPath: coverPath ?? current.localCoverPath,
          bytes: bytes,
          error: null,
        ),
      };
      await _persist();
      notifyListeners();
    } catch (e) {
      final current = _booksById[bookId];
      if (current == null) return;
      _booksById = {
        ..._booksById,
        bookId: current.copyWith(downloadState: BookDownloadState.failed, downloadProgress: null, error: e.toString()),
      };
      await _persist();
      notifyListeners();
    }
  }

  Future<String?> prepareOnlineRead(String bookId) async {
    final book = _booksById[bookId];
    if (book == null) return null;
    return prepareOnlineReadEntry(book);
  }

  Future<String?> prepareOnlineReadEntry(BookEntry book) async {
    if (book.isDownloaded) return book.localPath;
    if (!isOnline) return null;
    if (kIsWeb) return book.remoteUrl;
    return _downloadService.downloadToTemp(book);
  }

  Future<void> markOpened({required String bookId, String? progress}) async {
    final book = _booksById[bookId];
    if (book == null) return;

    _booksById = {
      ..._booksById,
      bookId: book.copyWith(lastOpenedAt: DateTime.now(), progress: progress ?? book.progress),
    };
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _box.put(
      _booksKey,
      _booksById.map((k, v) => MapEntry(k, v.toMap())),
    );
  }

  Map<String, BookEntry> _loadBooks(dynamic raw) {
    if (raw is! Map) return {};
    final map = Map<String, dynamic>.from(raw);
    return map.map((key, value) {
      final entry = BookEntry.fromMap(Map<String, dynamic>.from(value as Map));
      return MapEntry(key, entry);
    });
  }
}
