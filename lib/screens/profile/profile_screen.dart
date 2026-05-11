import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';
import '../login & signup_screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = "";
  String _email = "";
  bool _loadingName = true;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _email = user?.email ?? "";
    _fullName = user?.displayName ?? "";
    _loadProfileFast();
  }

  Future<void> _loadProfileFast() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loadingName = false);
      return;
    }
    try {
      final cached = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get(const GetOptions(source: Source.cache));
      final cachedName = (cached.data()?["fullName"] ?? "").toString().trim();
      if (cachedName.isNotEmpty && mounted)
        setState(() {
          _fullName = cachedName;
          _loadingName = false;
        });
      final server = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));
      final serverName = (server.data()?["fullName"] ?? "").toString().trim();
      if (mounted)
        setState(() {
          if (serverName.isNotEmpty) _fullName = serverName;
          _loadingName = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingName = false);
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.clear();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Logout failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _fullName.isNotEmpty ? _fullName : "User";
    final initials = name
        .trim()
        .split(" ")
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : "")
        .take(2)
        .join();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text("Profile"),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile header
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials.isEmpty ? "U" : initials,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (_loadingName)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Account info
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: "Account Information",
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 14),
                  _InfoRow(
                    label: "Full Name",
                    value: name,
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: "Email",
                    value: _email,
                    icon: Icons.mail_outline_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Settings
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: "Settings",
                    icon: Icons.settings_outlined,
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.security_outlined,
                    label: "Privacy & Security",
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Coming soon!")),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    label: "Help & Support",
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Coming soon!")),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Logout
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        "Sign Out",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      content: const Text("Are you sure you want to sign out?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: const Text(
                            "Sign Out",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) await _logout();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text(
                  "Sign Out",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
