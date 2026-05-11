import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const AlertDialog(content: Text("Please login."));
    }

    final stream = FirebaseFirestore.instance
        .collection("notifications")
        .where("uid", isEqualTo: user.uid)
        .orderBy("createdAt", descending: true)
        .snapshots();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
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

          // Body
          SizedBox(
            height: 360,
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
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
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final title = (data["title"] ?? "").toString();
                    final message = (data["message"] ?? "").toString();
                    final read = data["read"] == true;

                    return InkWell(
                      onTap: () => docs[i].reference.update({"read": true}),
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
                                Icons.notifications_rounded,
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
                                  if (message.isNotEmpty &&
                                      !message.startsWith("appt_")) ...[
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
