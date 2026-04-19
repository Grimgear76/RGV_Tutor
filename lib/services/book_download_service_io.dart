import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';

class BookDownloadProgress {
  const BookDownloadProgress({required this.receivedBytes, required this.totalBytes});

  final int receivedBytes;
  final int? totalBytes;

  double? get fraction {
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    return receivedBytes / total;
  }
}

class BookDownloadService {
  const BookDownloadService();

  Future<Directory> _booksDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}books');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _coversDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}covers');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Stream<BookDownloadProgress> downloadBook({required BookEntry book, required String targetPath}) async* {
    final url = book.resolvedRemoteUrl;
    final request = http.Request('GET', Uri.parse(url));
    final response = await request.send().timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Failed with status ${response.statusCode}');
    }

    final contentLength = response.contentLength;
    final totalBytes = (contentLength != null && contentLength > 0) ? contentLength : null;

    final file = File(targetPath);
    final sink = file.openWrite();

    var receivedBytes = 0;
    try {
      await for (final chunk in response.stream) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        yield BookDownloadProgress(receivedBytes: receivedBytes, totalBytes: totalBytes);
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  Future<String> resolveBookPath(BookEntry book) async {
    final dir = await _booksDir();
    return '${dir.path}${Platform.pathSeparator}${book.id}.${book.format.fileExtension}';
  }

  Future<String?> downloadCover({required BookEntry book}) async {
    final url = book.coverUrl;
    if (url == null || url.isEmpty) return null;

    http.Response response;
    try {
      response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    } catch (_) {
      return null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final dir = await _coversDir();
    final path = '${dir.path}${Platform.pathSeparator}${book.id}.jpg';
    final file = File(path);
    await file.writeAsBytes(response.bodyBytes);
    return path;
  }

  Future<int> fileSize(String path) async {
    return File(path).length();
  }

  Future<String?> downloadToTemp(BookEntry book) async {
    final temp = await Directory.systemTemp.createTemp('rgv_books_');
    final tempPath = '${temp.path}${Platform.pathSeparator}${book.id}.${book.format.fileExtension}';
    await for (final _ in downloadBook(book: book, targetPath: tempPath)) {}
    return tempPath;
  }

  Future<void> deleteLocalFiles(BookEntry book) async {
    final localPath = book.localPath;
    if (localPath != null) {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    final coverPath = book.localCoverPath;
    if (coverPath != null) {
      final file = File(coverPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
