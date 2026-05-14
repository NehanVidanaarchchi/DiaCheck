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
    setState(() {
      _error = null;
    });

    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (file == null) return;

      setState(() {
        _image = file;
      });
    } catch (_) {
      setState(() {
        _error = "Camera permission denied or camera not available.";
      });
    }
  }

  Future<String> _getGroqApiKey() async {
    final doc = await FirebaseFirestore.instance
        .collection("secrets")
        .doc("groq")
        .get();

    final data = doc.data();

    return (data?["apikey"] ?? data?["api_key"] ?? "").toString();
  }

  Future<String> _imageToDataUrl(XFile image) async {
    final bytes = await File(image.path).readAsBytes();
    final base64Image = base64Encode(bytes);
    return "data:image/jpeg;base64,$base64Image";
  }

  String _cleanJson(String text) {
    String cleaned = text
        .replaceAll("```json", "")
        .replaceAll("```JSON", "")
        .replaceAll("```", "")
        .trim();

    final start = cleaned.indexOf("{");
    final end = cleaned.lastIndexOf("}");

    if (start != -1 && end != -1 && end > start) {
      cleaned = cleaned.substring(start, end + 1);
    }

    return cleaned;
  }

  List<String> _asList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  double? _extractSugarLevel(Map<String, dynamic> ai) {
    final value =
        ai["sugarLevel"] ??
        ai["sugar_level"] ??
        ai["glucose"] ??
        ai["glucoseLevel"] ??
        ai["bloodSugar"] ??
        ai["blood_sugar"];

    if (value is num) return value.toDouble();

    if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ""));
    }

    return null;
  }

  String _riskLevel(double? sugar) {
    if (sugar == null) return "Unknown";
    if (sugar < 100) return "Normal";
    if (sugar < 126) return "Pre-diabetic";
    return "High risk";
  }

  Future<void> _saveReportToFirestore(Map<String, dynamic> ai) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("Login session expired. Please login again.");
    }

    final sugar = _extractSugarLevel(ai);

    await FirebaseFirestore.instance.collection("reports").add({
      "uid": user.uid,
      "email": user.email ?? "",
      "createdAt": FieldValue.serverTimestamp(),
      "summary": (ai["summary"] ?? "").toString(),
      "possible_issues": _asList(ai["possible_issues"]),
      "urgent_flags": _asList(ai["urgent_flags"]),
      "recommendations": _asList(ai["recommendations"]),
      "sugarLevel": sugar,
      "riskLevel": _riskLevel(sugar),
    });
  }

  Future<void> _showResultPopup(Map<String, dynamic> ai) async {
    if (!mounted) return;

    final summary = (ai["summary"] ?? "No summary").toString();
    final issues = _asList(ai["possible_issues"]);
    final urgent = _asList(ai["urgent_flags"]);
    final recs = _asList(ai["recommendations"]);
    final sugar = _extractSugarLevel(ai);
    final risk = _riskLevel(sugar);

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Scan Result"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Summary",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(summary),

                const SizedBox(height: 14),
                const Text(
                  "Sugar Level",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(sugar == null ? "Not found" : sugar.toString()),

                const SizedBox(height: 14),
                const Text(
                  "Risk Level",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(risk),

                const SizedBox(height: 14),
                const Text(
                  "Possible Issues",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                if (issues.isEmpty)
                  const Text("—")
                else
                  ...issues.map((x) => Text("• $x")),

                const SizedBox(height: 14),
                const Text(
                  "Urgent Flags",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                if (urgent.isEmpty)
                  const Text("—")
                else
                  ...urgent.map((x) => Text("• $x")),

                const SizedBox(height: 14),
                const Text(
                  "Recommendations",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                if (recs.isEmpty)
                  const Text("—")
                else
                  ...recs.map((x) => Text("• $x")),

                const SizedBox(height: 14),
                const Text(
                  "Note: This is not a diagnosis. Please contact a doctor for medical advice.",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _analyzeWithGroq() async {
    if (_image == null) {
      setState(() {
        _error = "Please take a photo first.";
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _error = "Login session expired. Please login again.";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      _groqApiKey ??= await _getGroqApiKey();

      if (_groqApiKey == null || _groqApiKey!.isEmpty) {
        throw Exception("API key not found in Firebase.");
      }

      final imageUrl = await _imageToDataUrl(_image!);

      final response = await http.post(
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
                  "You are a medical report image checker and summarizer. "
                  "First check whether the image is a medical/lab report. "
                  "Do not diagnose. "
                  "Return raw JSON only. Do not use markdown. Do not use ```json code blocks. "
                  "Schema: {"
                  "\"is_medical_report\": boolean,"
                  "\"reason\": string,"
                  "\"summary\": string,"
                  "\"sugarLevel\": number|null,"
                  "\"possible_issues\": string[],"
                  "\"urgent_flags\": string[],"
                  "\"recommendations\": string[]"
                  "}. "
                  "If image is not a medical report, set is_medical_report false, explain reason, and keep arrays empty.",
            },
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text":
                      "Analyze this image. If it is not a medical report, tell me to capture a medical report.",
                },
                {
                  "type": "image_url",
                  "image_url": {"url": imageUrl},
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Scan failed. Please try again.");
      }

      final decoded = jsonDecode(response.body);
      final content = decoded["choices"]?[0]?["message"]?["content"];

      if (content == null) {
        throw Exception("Empty AI response.");
      }

      final cleanContent = _cleanJson(content.toString());
      final ai = Map<String, dynamic>.from(jsonDecode(cleanContent));

      final isReport = ai["is_medical_report"] == true;

      if (!isReport) {
        setState(() {
          _error =
              "This image does not look like a medical report. Please capture a clear medical/lab report.";
        });
        return;
      }

      await _saveReportToFirestore(ai);

      if (!mounted) return;

      await _showResultPopup(ai);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Report saved successfully ✅"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
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
          children: [
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
                    child: Text(
                      "Keep the paper flat, use good lighting, and capture the full medical report.",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: _loading ? null : _takePhoto,
              child: Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _image == null
                      ? AppColors.primaryLight.withOpacity(0.5)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.25),
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _image == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              color: AppColors.primary,
                              size: 42,
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Tap to capture medical report",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Image.file(File(_image!.path), fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text("Camera"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    label: _loading ? "Analyzing..." : "Analyze",
                    icon: _loading ? null : Icons.auto_awesome_rounded,
                    loading: _loading,
                    onPressed: _image == null || _loading
                        ? null
                        : _analyzeWithGroq,
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
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
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
