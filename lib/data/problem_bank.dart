import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/problem.dart';

class ProblemBank {
  const ProblemBank();

  Future<List<Problem>> load() async {
    final raw = await rootBundle.loadString('assets/problems.json');
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => Problem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
