import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/book.dart';

class BookCatalogService {
  const BookCatalogService();

  Future<List<BookEntry>> loadCatalog() async {
    final jsonString = await rootBundle.loadString('assets/books.json');
    final decoded = jsonDecode(jsonString);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((row) => BookEntry.fromCatalogMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }
}
