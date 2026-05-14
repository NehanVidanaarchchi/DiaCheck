import 'dart:async';
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

    if (!doc.exists) {
      throw Exception('Firestore document secrets/groq does not exist.');
    }

    final data = doc.data();

    if (data == null) {
      throw Exception('Firestore document secrets/groq has no data.');
    }

    var key = data['api_key']?.toString() ?? '';

    key = key
        .trim()
        .replaceFirst(RegExp(r'^Bearer\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), '');

    if (key.isEmpty) {
      throw Exception(
        'Groq API key not found. Make sure Firestore has field api_key in secrets/groq.',
      );
    }

    if (!key.startsWith('gsk_')) {
      throw Exception(
        'Invalid Groq API key format. It should start with gsk_.',
      );
    }

    return key;
  }

  Future<String> sendMessage({
    required String userInput,
    required List<ChatMessage> history,
  }) async {
    final input = userInput.trim();

    if (input.isEmpty) {
      throw Exception('Message cannot be empty.');
    }

    _apiKey ??= await _loadApiKey();

    final List<Map<String, String>> messages = [
      {
        'role': 'system',
        'content':
            'You are "Doctor Assist AI", a friendly assistant focused on '
            'heart health, risk factors, lifestyle, and general wellbeing. '
            'Use simple language. Keep answers under 200 words. '
            'Do not give a final diagnosis. '
            'Do not prescribe medicine. '
            'Always suggest speaking with a doctor for personal medical advice.',
      },

      ...history
          .where((m) => m.text.trim().isNotEmpty)
          .map(
            (m) => {
              'role': m.role == 'user' ? 'user' : 'assistant',
              'content': m.text.trim(),
            },
          ),

      {'role': 'user', 'content': input},
    ];

    final body = jsonEncode({
      'model': _model,
      'messages': messages,
      'temperature': 0.3,
      'max_tokens': 400,
    });

    final http.Response resp;

    try {
      resp = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw Exception('Groq request timed out. Please try again.');
    } catch (e) {
      throw Exception('Could not connect to Groq: $e');
    }

    if (resp.statusCode == 401) {
      throw Exception(
        'Groq 401: Invalid API key. Create a new Groq key and save it in Firestore field api_key.',
      );
    }

    if (resp.statusCode == 429) {
      throw Exception(
        'Groq 429: Too many requests. Please wait a little and try again.',
      );
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Groq error ${resp.statusCode}: ${resp.body}');
    }

    final Map<String, dynamic> data;

    try {
      data = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Invalid JSON response from Groq.');
    }

    final choices = data['choices'];

    if (choices is! List || choices.isEmpty) {
      throw Exception('No response choices returned from Groq.');
    }

    final firstChoice = choices.first;

    if (firstChoice is! Map<String, dynamic>) {
      throw Exception('Invalid Groq response format.');
    }

    final message = firstChoice['message'];

    if (message is! Map<String, dynamic>) {
      throw Exception('Invalid Groq message format.');
    }

    final content = message['content']?.toString().trim();

    if (content == null || content.isEmpty) {
      throw Exception('Empty response from Groq.');
    }

    return content;
  }
}
