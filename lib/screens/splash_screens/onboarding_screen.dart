import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../login & signup_screens/login_screen.dart';
import '../login & signup_screens/signup_screen.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      image: 'assets/images/doctor1.png',
      title: 'Consult only with a doctor\nyou trust',
    ),
    _OnboardingData(
      image: 'assets/images/doctor2.png',
      title: 'Find a lot of specialist\ndoctors in one place',
    ),
    _OnboardingData(
      image: 'assets/images/doctor3.png',
      title: 'Get connected with our\nOnline Consultation',
    ),
  ];

  void _goNext() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginSingupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with "Skip"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 50),
                  TextButton(
                    onPressed: _goToLogin,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _OnboardingSlide(data: page, onNext: _goNext);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  final bool isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    height: 8,
                    width: isActive ? 28 : 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isActive
                          ? AppColors.primary
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data model for each onboarding slide
class _OnboardingData {
  final String image;
  final String title;

  const _OnboardingData({required this.image, required this.title});
}

/// Single slide widget (image + rounded white card + arrow button)
class _OnboardingSlide extends StatelessWidget {
  final _OnboardingData data;
  final VoidCallback onNext;

  const _OnboardingSlide({required this.data, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Doctor image
          Positioned.fill(
            child: Column(
              children: [
                Expanded(child: Image.asset(data.image, fit: BoxFit.contain)),
                const SizedBox(height: 80), // space for bottom card
              ],
            ),
          ),

          // Bottom white rounded card
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Text
                Expanded(
                  child: Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Circular arrow button
                InkWell(
                  onTap: onNext,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    height: 52,
                    width: 52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------- LOGIN SCREEN (last image) ----------------
class LoginSingupScreen extends StatelessWidget {
  const LoginSingupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo placeholder
                Image.asset(
                  'assets/images/icon.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                const Text(
                  'DiaCheck',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  "Let's get started!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Login to enjoy the features we've provided,\n"
                  "and stay healthy!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 40),

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),

                // Sign up button (outlined)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(color: AppColors.primary, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
