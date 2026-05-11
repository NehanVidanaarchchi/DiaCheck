import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../home_screen/home_screen.dart';
import '../profile/profile_screen.dart';
import '../notification_screen/notification_screen.dart';
import '../calendar_screen/calendar_screen.dart';
import '../../theme/app_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _name = "";
  bool _loading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => _loading = false); return; }
    try {
      final snap = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      setState(() {
        _name = (snap.data()?["fullName"] ?? "").toString();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good morning";
    if (h < 17) return "Good afternoon";
    return "Good evening";
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tabs = [
      const HomeScreen(),
      const CalendarScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar (only on home/calendar tabs)
            if (_tabIndex != 2)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${_greet()},",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            _name.isNotEmpty ? _name : "User",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => const NotificationScreen(),
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("notifications")
                            .where("uid", isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                            .where("read", isEqualTo: false)
                            .snapshots(),
                        builder: (ctx, snap) {
                          final unread = snap.data?.docs.length ?? 0;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              if (unread > 0)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        unread > 9 ? "9+" : "$unread",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(child: tabs[_tabIndex]),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: BottomNavigationBar(
              currentIndex: _tabIndex,
              onTap: (i) => setState(() => _tabIndex = i),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
                BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: "Calendar"),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}