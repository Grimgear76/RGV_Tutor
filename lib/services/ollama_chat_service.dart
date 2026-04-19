import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/platform_info.dart';

class OllamaChatService {
  OllamaChatService({this.model = 'llama3.2:1b', String? baseUrl})
      : baseUrl = baseUrl ?? _defaultBaseUrl;

  final String baseUrl;
  final String model;

  static String get _defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:11434';
    if (platformInfo.isAndroid) return 'http://10.0.2.2:11434';
    return 'http://localhost:11434';
  }

  Future<String> chat({required List<OllamaMessage> messages}) async {
    final uri = Uri.parse('$baseUrl/api/chat');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'stream': false,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Ollama error (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final message = decoded is Map<String, dynamic> ? decoded['message'] : null;
    final content = message is Map<String, dynamic> ? message['content'] : null;
    if (content is String) return content;

    throw Exception('Unexpected Ollama response: ${response.body}');
  }
}

class OllamaMessage {
  const OllamaMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
