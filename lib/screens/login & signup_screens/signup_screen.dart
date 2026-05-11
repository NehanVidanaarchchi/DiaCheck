import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import '../main_screen/main_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _passObscure = true;
  bool _confirmObscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      await FirebaseFirestore.instance
          .collection("users")
          .doc(cred.user!.uid)
          .set({
            "uid": cred.user!.uid,
            "fullName": _nameCtrl.text.trim(),
            "email": _emailCtrl.text.trim(),
            "createdAt": FieldValue.serverTimestamp(),
          });
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? "Signup failed");
    } catch (e) {
      _toast("Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/icon.png',
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "DiaCheck",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                const Text(
                  "Create account",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Start monitoring your health today",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 36),

                AppTextField(
                  controller: _nameCtrl,
                  label: "Full Name",
                  hint: "Enter your full name",
                  prefixIcon: Icons.person_outline_rounded,
                  keyboard: TextInputType.name,
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? "Enter your name" : null,
                ),

                const SizedBox(height: 20),

                AppTextField(
                  controller: _emailCtrl,
                  label: "Email Address",
                  hint: "Enter your email",
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboard: TextInputType.emailAddress,
                  validator: (v) {
                    final s = (v ?? "").trim();
                    if (s.isEmpty) return "Enter your email";
                    if (!s.contains("@")) return "Enter a valid email";
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                AppTextField(
                  controller: _passCtrl,
                  label: "Password",
                  hint: "Min. 6 characters",
                  prefixIcon: Icons.lock_outline_rounded,
                  obscure: _passObscure,
                  suffix: IconButton(
                    icon: Icon(
                      _passObscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _passObscure = !_passObscure),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Enter your password";
                    if (v.length < 6) return "Min 6 characters";
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                AppTextField(
                  controller: _confirmCtrl,
                  label: "Confirm Password",
                  hint: "Re-enter your password",
                  prefixIcon: Icons.lock_outline_rounded,
                  obscure: _confirmObscure,
                  suffix: IconButton(
                    icon: Icon(
                      _confirmObscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _confirmObscure = !_confirmObscure),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Confirm your password";
                    if (v != _passCtrl.text) return "Passwords do not match";
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                GradientButton(
                  label: "Create Account",
                  onPressed: _signUp,
                  loading: _loading,
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Text(
                        "Sign In",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
