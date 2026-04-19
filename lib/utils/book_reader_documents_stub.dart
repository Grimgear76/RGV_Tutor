import 'package:epub_view/epub_view.dart';
import 'package:pdfx/pdfx.dart';

Future<EpubBook> epubDocumentFromPath(String path) {
  return Future.error(
      UnsupportedError('Local file reading is not supported on web.'));
}

Future<PdfDocument> pdfDocumentFromPath(String path) {
  return Future.error(
      UnsupportedError('Local file reading is not supported on web.'));
}
