import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String selectedLanguage = "English";

  final languages = const ["English", "Sinhala", "Tamil"];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedLanguage = prefs.getString("app_language") ?? "English";
    });
  }

  Future<void> _saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("app_language", lang);

    setState(() {
      selectedLanguage = lang;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Language changed to $lang")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Language"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: languages.map((lang) {
          final active = lang == selectedLanguage;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF2F6BFF).withOpacity(0.10)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active ? const Color(0xFF2F6BFF) : Colors.black12,
              ),
            ),
            child: ListTile(
              leading: Icon(
                Icons.language,
                color: active ? const Color(0xFF2F6BFF) : Colors.grey,
              ),
              title: Text(
                lang,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              trailing: active
                  ? const Icon(Icons.check_circle, color: Color(0xFF2F6BFF))
                  : null,
              onTap: () => _saveLanguage(lang),
            ),
          );
        }).toList(),
      ),
      backgroundColor: const Color(0xFFF6F8FC),
    );
  }
}
