import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class GroqChatService {
  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _model = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: 'llama-3.1-8b-instant',
  );

  String? _apiKey;

  Future<String> _loadApiKey() async {
    final doc = await FirebaseFirestore.instance
        .collection('secrets')
        .doc('groq')
        .get();
    final key = doc.data()?['apikey'] as String? ?? '';
    if (key.isEmpty) {
      throw Exception('Groq API key not found in Firestore.');
    }
    return key;
  }

  Future<String> sendMessage({
    required String userInput,
    required List<ChatMessage> history,
  }) async {
    _apiKey ??= await _loadApiKey();

    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception(
        'Groq API key is missing. Make sure it exists in Firestore at secrets/groq.',
      );
    }

    // Convert your existing messages into Groq format
    final List<Map<String, String>> messages = [
      {
        'role': 'system',
        'content':
            'You are "Doctor Assist AI", a friendly assistant focused on '
            'heart health and general wellbeing. '
            'Use simple language, keep answers under ~200 words, '
            'never give a final diagnosis, and always suggest speaking to a doctor.',
      },
      ...history.map(
        (m) => {
          'role': m.role == 'user' ? 'user' : 'assistant',
          'content': m.text,
        },
      ),
      {'role': 'user', 'content': userInput},
    ];

    final body = jsonEncode({
      'model': _model,
      'messages': messages,
      'temperature': 0.3,
    });

    final resp = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: body,
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Groq error ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final content =
        (data['choices'] as List).first['message']['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw Exception('Empty response from Groq');
    }
    return content.trim();
  }
}
