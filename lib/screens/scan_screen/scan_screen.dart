import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  XFile? _image;
  bool _loading = false;
  String? _error;
  String? _groqApiKey;

  Future<void> _takePhoto() async {
    setState(() => _error = null);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (file == null) return;
      setState(() => _image = file);
    } catch (_) {
      setState(
        () => _error = "Camera permission denied or camera not available.",
      );
    }
  }

  Future<String> _getGroqApiKey() async {
    final doc = await FirebaseFirestore.instance
        .collection('secrets')
        .doc('groq')
        .get();
    return doc.data()?['apikey'] ?? '';
  }

  Future<void> _saveReportToFirestore(Map<String, dynamic> ai) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("You must login to save reports.");
    List<String> asList(dynamic v) =>
        (v is List) ? v.map((e) => e.toString()).toList() : [];
    await FirebaseFirestore.instance.collection("reports").add({
      "uid": user.uid,
      "email": user.email ?? "",
      "createdAt": FieldValue.serverTimestamp(),
      "summary": (ai["summary"] ?? "").toString(),
      "possible_issues": asList(ai["possible_issues"]),
      "urgent_flags": asList(ai["urgent_flags"]),
      "recommendations": asList(ai["recommendations"]),
    });
  }

  Future<void> _analyzeWithGroq() async {
    if (_image == null) {
      setState(() => _error = "Please take a photo first.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_groqApiKey == null) {
        _groqApiKey = await _getGroqApiKey();
        if (_groqApiKey!.isEmpty) {
          throw Exception("API key not found in database.");
        }
      }
      final resp = await http.post(
        Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $_groqApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "meta-llama/llama-4-scout-17b-16e-instruct",
          "temperature": 0.2,
          "messages": [
            {
              "role": "system",
              "content":
                  "You are a medical report summarizer. Do NOT diagnose. Return ONLY valid JSON with schema: {\"summary\":string,\"possible_issues\":string[],\"urgent_flags\":string[],\"recommendations\":string[]}. Use soft language like 'may indicate'. If image unclear, return empty arrays.",
            },
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text":
                      "Analyze this medical report image and output JSON only.",
                },
                {
                  "type": "image_url",
                  "image_url": {"url": "data:image/jpeg;base64"},
                },
              ],
            },
          ],
        }),
      );
      if (resp.statusCode != 200) {
        throw Exception("Groq error ${resp.statusCode}: ${resp.body}");
      }
      final decoded = jsonDecode(resp.body);
      final content = decoded["choices"]?[0]?["message"]?["content"];
      if (content == null) {
        throw Exception("Empty AI response.");
      }
      final ai = Map<String, dynamic>.from(jsonDecode(content));
      await _saveReportToFirestore(ai);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Report saved ✅"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll("Exception: ", ""));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text("Scan Report")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instruction card
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tips_and_updates_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Scanning Tips",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Keep the paper flat, ensure good lighting, and include the full page for accurate results.",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Image preview
            GestureDetector(
              onTap: _loading ? null : _takePhoto,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _image != null
                      ? Colors.transparent
                      : AppColors.primaryLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _image != null
                        ? AppColors.primary.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.2),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            "Tap to open camera",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Take a photo of your report",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(_image!.path), fit: BoxFit.cover),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: _loading ? null : _takePhoto,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text(
                      "Camera",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    label: _loading ? "Analyzing..." : "Analyze",
                    icon: _loading ? null : Icons.auto_awesome_rounded,
                    loading: _loading,
                    onPressed: _image != null ? _analyzeWithGroq : null,
                  ),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
