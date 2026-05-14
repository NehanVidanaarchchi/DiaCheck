import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  String _formatDate(dynamic ts) {
    if (ts is! Timestamp) return "";
    final d = ts.toDate();
    return "${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")} "
        "${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}";
  }

  IconData _iconForType(String type) {
    switch (type) {
      case "appointment":
        return Icons.calendar_month_rounded;
      case "prescription":
        return Icons.medication_rounded;
      case "report":
        return Icons.description_rounded;
      case "message":
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const AlertDialog(content: Text("Please login."));
    }

    final stream = FirebaseFirestore.instance
        .collection("notifications")
        .where("uid", isEqualTo: user.uid)
        .snapshots();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Notifications",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 380,
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        "Failed to load notifications:\n${snap.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }

                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];

                final notifications = docs.map((doc) {
                  return {
                    "id": doc.id,
                    "ref": doc.reference,
                    ...(doc.data() as Map<String, dynamic>),
                  };
                }).toList();

                notifications.sort((a, b) {
                  final at = a["createdAt"];
                  final bt = b["createdAt"];

                  if (at is Timestamp && bt is Timestamp) {
                    return bt.toDate().compareTo(at.toDate());
                  }

                  return 0;
                });

                if (notifications.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 42,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "No notifications yet",
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final data = notifications[i];

                    final title = (data["title"] ?? "Notification").toString();
                    final message = (data["message"] ?? "").toString();
                    final type = (data["type"] ?? "").toString();
                    final read = data["read"] == true;
                    final ref = data["ref"] as DocumentReference;

                    return InkWell(
                      onTap: () async {
                        try {
                          await ref.update({"read": true});
                        } catch (_) {}
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: read ? Colors.white : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: read
                                ? AppColors.border
                                : AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: read
                                    ? AppColors.surface
                                    : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _iconForType(type),
                                color: read
                                    ? AppColors.textMuted
                                    : AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: read
                                          ? FontWeight.w600
                                          : FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),

                                  if (message.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      message,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 5),

                                  Text(
                                    _formatDate(data["createdAt"]),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted.withOpacity(
                                        0.7,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (!read)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
