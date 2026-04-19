enum BookFormat {
  epub,
  pdf;

  static BookFormat fromId(String value) {
    return BookFormat.values.firstWhere(
      (row) => row.id == value,
      orElse: () => BookFormat.epub,
    );
  }

  String get id => name;

  String get fileExtension {
    return switch (this) {
      BookFormat.epub => 'epub',
      BookFormat.pdf => 'pdf',
    };
  }
}

enum BookSource {
  gutenberg,
  standardEbooks,
  openLibrary;

  static BookSource fromId(String value) {
    return BookSource.values.firstWhere(
      (row) => row.id == value,
      orElse: () => BookSource.gutenberg,
    );
  }

  String get id {
    return switch (this) {
      BookSource.standardEbooks => 'standardebooks',
      _ => name,
    };
  }
}

enum BookDownloadState {
  notDownloaded,
  downloading,
  downloaded,
  failed;

  static BookDownloadState fromId(String value) {
    return BookDownloadState.values.firstWhere(
      (row) => row.id == value,
      orElse: () => BookDownloadState.notDownloaded,
    );
  }

  String get id => name;
}

class BookEntry {
  const BookEntry({
    required this.id,
    required this.title,
    required this.author,
    required this.format,
    required this.source,
    required this.remoteUrl,
    required this.coverUrl,
    required this.downloadState,
    required this.addedAt,
    this.localPath,
    this.localCoverPath,
    this.bytes,
    this.lastOpenedAt,
    this.progress,
    this.downloadProgress,
    this.error,
  });

  final String id;
  final String title;
  final String author;
  final BookFormat format;
  final BookSource source;
  final String remoteUrl;
  final String? coverUrl;

  final String? localPath;
  final String? localCoverPath;
  final int? bytes;

  final BookDownloadState downloadState;
  final double? downloadProgress;
  final String? error;

  final DateTime addedAt;
  final DateTime? lastOpenedAt;
  final String? progress;

  bool get isDownloaded => downloadState == BookDownloadState.downloaded && localPath != null;

  String get resolvedRemoteUrl {
    if (source != BookSource.standardEbooks) return remoteUrl;
    if (format != BookFormat.epub) return remoteUrl;

    final uri = Uri.tryParse(remoteUrl);
    if (uri == null) return remoteUrl;

    if (!uri.path.toLowerCase().endsWith('.epub')) return remoteUrl;

    if (uri.queryParameters.containsKey('source')) return remoteUrl;

    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'source': 'download',
    }).toString();
  }

  BookEntry copyWith({
    String? localPath,
    String? localCoverPath,
    int? bytes,
    BookDownloadState? downloadState,
    double? downloadProgress,
    String? error,
    DateTime? lastOpenedAt,
    String? progress,
  }) {
    return BookEntry(
      id: id,
      title: title,
      author: author,
      format: format,
      source: source,
      remoteUrl: remoteUrl,
      coverUrl: coverUrl,
      localPath: localPath ?? this.localPath,
      localCoverPath: localCoverPath ?? this.localCoverPath,
      bytes: bytes ?? this.bytes,
      downloadState: downloadState ?? this.downloadState,
      downloadProgress: downloadProgress,
      error: error,
      addedAt: addedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'format': format.id,
      'source': source.id,
      'remoteUrl': remoteUrl,
      'coverUrl': coverUrl,
      'localPath': localPath,
      'localCoverPath': localCoverPath,
      'bytes': bytes,
      'downloadState': downloadState.id,
      'downloadProgress': downloadProgress,
      'error': error,
      'addedAt': addedAt.toIso8601String(),
      'lastOpenedAt': lastOpenedAt?.toIso8601String(),
      'progress': progress,
    };
  }

  static BookEntry fromMap(Map<String, dynamic> map) {
    return BookEntry(
      id: map['id'] as String,
      title: map['title'] as String,
      author: (map['author'] as String?) ?? '',
      format: BookFormat.fromId((map['format'] as String?) ?? 'epub'),
      source: BookSource.fromId((map['source'] as String?) ?? 'gutenberg'),
      remoteUrl: map['remoteUrl'] as String,
      coverUrl: map['coverUrl'] as String?,
      localPath: map['localPath'] as String?,
      localCoverPath: map['localCoverPath'] as String?,
      bytes: map['bytes'] as int?,
      downloadState: BookDownloadState.fromId((map['downloadState'] as String?) ?? 'notDownloaded'),
      downloadProgress: (map['downloadProgress'] as num?)?.toDouble(),
      error: map['error'] as String?,
      addedAt: DateTime.parse(map['addedAt'] as String),
      lastOpenedAt: map['lastOpenedAt'] == null ? null : DateTime.parse(map['lastOpenedAt'] as String),
      progress: map['progress'] as String?,
    );
  }

  static BookEntry fromCatalogMap(Map<String, dynamic> map) {
    return BookEntry(
      id: map['id'] as String,
      title: map['title'] as String,
      author: (map['author'] as String?) ?? '',
      format: BookFormat.fromId((map['format'] as String?) ?? 'epub'),
      source: BookSource.fromId((map['source'] as String?) ?? 'gutenberg'),
      remoteUrl: map['remoteUrl'] as String,
      coverUrl: map['coverUrl'] as String?,
      downloadState: BookDownloadState.notDownloaded,
      addedAt: DateTime.now(),
    );
  }
}
