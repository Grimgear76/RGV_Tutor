import 'dart:io';

import 'package:epub_view/epub_view.dart';
import 'package:pdfx/pdfx.dart';

Future<EpubBook> epubDocumentFromPath(String path) {
  return EpubDocument.openFile(File(path));
}

Future<PdfDocument> pdfDocumentFromPath(String path) {
  return PdfDocument.openFile(path);
}
