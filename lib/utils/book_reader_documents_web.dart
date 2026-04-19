import 'dart:typed_data';

import 'package:epub_view/epub_view.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

const _proxyBaseUrl = String.fromEnvironment('BOOK_PROXY_URL');

Future<Uint8List> _getBytes(Uri uri) async {
  final response = await http.get(uri);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError('Request failed (${response.statusCode}).');
  }
  return Uint8List.fromList(response.bodyBytes);
}

bool _looksLikeZip(Uint8List bytes) {
  return bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B;
}

String _previewText(Uint8List bytes) {
  final len = bytes.length < 180 ? bytes.length : 180;
  final slice = bytes.sublist(0, len);
  return String.fromCharCodes(slice.where((b) => b == 0x0A || (b >= 0x20 && b <= 0x7E))).trim();
}

Future<Uint8List> _fetchViaProxyIfNeeded({required Uri target, bool expectZip = false}) async {
  try {
    final bytes = await _getBytes(target);
    if (expectZip && !_looksLikeZip(bytes)) {
      throw FormatException('Response was not a ZIP/EPUB payload: ${_previewText(bytes)}');
    }
    return bytes;
  } catch (error) {
    if (_proxyBaseUrl.isEmpty) {
      throw StateError(
        'Web cannot fetch this URL (likely CORS). '
        'Run on Android/iOS/desktop, or provide a proxy via --dart-define=BOOK_PROXY_URL=http://localhost:8080/api/proxy. '
        'Original error: $error',
      );
    }

    final proxied = Uri.parse(_proxyBaseUrl).replace(
      queryParameters: {'url': target.toString()},
    );
    final bytes = await _getBytes(proxied);
    if (expectZip && !_looksLikeZip(bytes)) {
      throw FormatException('Response was not a ZIP/EPUB payload: ${_previewText(bytes)}');
    }
    return bytes;
  }
}

Future<EpubBook> epubDocumentFromPath(String path) async {
  final uri = Uri.tryParse(path);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    return Future.error(UnsupportedError('Web reader only supports http(s) URLs.'));
  }

  final bytes = await _fetchViaProxyIfNeeded(target: uri, expectZip: true);
  return EpubDocument.openData(bytes);
}

Future<PdfDocument> pdfDocumentFromPath(String path) async {
  final uri = Uri.tryParse(path);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    return Future.error(UnsupportedError('Web reader only supports http(s) URLs.'));
  }

  final bytes = await _fetchViaProxyIfNeeded(target: uri);
  return PdfDocument.openData(bytes);
}
