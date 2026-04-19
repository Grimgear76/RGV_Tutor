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

  Stream<BookDownloadProgress> downloadBook({required BookEntry book, required String targetPath}) {
    throw UnsupportedError('Book downloads are not supported on this platform.');
  }

  Future<String> resolveBookPath(BookEntry book) {
    throw UnsupportedError('Local file storage is not supported on this platform.');
  }

  Future<String?> downloadCover({required BookEntry book}) {
    return Future.value(null);
  }

  Future<int> fileSize(String path) {
    throw UnsupportedError('Local file storage is not supported on this platform.');
  }

  Future<String?> downloadToTemp(BookEntry book) {
    return Future.value(null);
  }

  Future<void> deleteLocalFiles(BookEntry book) async {}
}
