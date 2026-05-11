import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'signup_screen.dart';
import '../main_screen/main_screen.dart';
import '../doctor_screen/doctor_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String kRememberUntil = "remember_until_ms";

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _autoLoginIfValid();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _goToCorrectScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doctorDoc = await FirebaseFirestore.instance
        .collection("doctors")
        .doc(user.uid)
        .get();

    if (!mounted) return;

    if (doctorDoc.exists &&
        doctorDoc.data()?["active"] == true &&
        doctorDoc.data()?["approved"] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DoctorScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  Future<void> _autoLoginIfValid() async {
    final prefs = await SharedPreferences.getInstance();
    final untilMs = prefs.getInt(kRememberUntil) ?? 0;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (untilMs == 0) {
      await FirebaseAuth.instance.signOut();
      return;
    }

    if (DateTime.now().millisecondsSinceEpoch > untilMs) {
      await FirebaseAuth.instance.signOut();
      await prefs.remove(kRememberUntil);
      return;
    }

    await _goToCorrectScreen();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty) {
      _toast("Please enter email");
      return;
    }

    if (pass.isEmpty) {
      _toast("Please enter password");
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final prefs = await SharedPreferences.getInstance();

      if (_rememberMe) {
        await prefs.setInt(
          kRememberUntil,
          DateTime.now().add(const Duration(days: 2)).millisecondsSinceEpoch,
        );
      } else {
        await prefs.setInt(kRememberUntil, 0);
      }

      await _goToCorrectScreen();
    } on FirebaseAuthException catch (e) {
      _toast(
        e.code == "wrong-password" || e.code == "invalid-credential"
            ? "Invalid email or password"
            : e.message ?? "Login failed",
      );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                "Welcome back",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Sign in to continue your health journey",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 36),

              AppTextField(
                controller: _emailCtrl,
                label: "Email Address",
                hint: "Enter your email",
                prefixIcon: Icons.mail_outline_rounded,
                keyboard: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              AppTextField(
                controller: _passCtrl,
                label: "Password",
                hint: "Enter your password",
                prefixIcon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _rememberMe
                                ? AppColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _rememberMe
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: _rememberMe
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Remember me",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _toast("Forgot password not added yet"),
                    child: const Text(
                      "Forgot password?",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              GradientButton(
                label: "Login",
                onPressed: _login,
                loading: _loading,
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
