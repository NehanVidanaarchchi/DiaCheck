import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../doctor_list_screen/doctor_list_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  User? get _user => FirebaseAuth.instance.currentUser;

  String _formatDate(dynamic ts) {
    if (ts == null) return "Unknown date";
    try {
      final dt = (ts as Timestamp).toDate();
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "Unknown date";
    }
  }

  Future<void> _openReportPopup(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    List<String> list(dynamic v) =>
        (v is List) ? v.map((e) => e.toString()).toList() : [];

    final summary = (data["summary"] ?? "No summary").toString();
    final issues = list(data["possible_issues"]);
    final urgent = list(data["urgent_flags"]);
    final recs = list(data["recommendations"]);
    final createdAt = _formatDate(data["createdAt"]);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        "Report Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          createdAt,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider, height: 1),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [
                  _ReportSection(
                    title: "Summary",
                    icon: Icons.summarize_outlined,
                    color: AppColors.primary,
                    content: summary,
                    isList: false,
                  ),
                  if (issues.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ReportSection(
                      title: "Possible Issues",
                      icon: Icons.warning_amber_outlined,
                      color: AppColors.warning,
                      items: issues,
                      isList: true,
                    ),
                  ],
                  if (urgent.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ReportSection(
                      title: "Urgent Warning Signs",
                      icon: Icons.error_outline_rounded,
                      color: AppColors.error,
                      items: urgent,
                      isList: true,
                    ),
                  ],
                  if (recs.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ReportSection(
                      title: "Next Steps",
                      icon: Icons.checklist_rounded,
                      color: AppColors.success,
                      items: recs,
                      isList: true,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "This is informational only. If you feel unwell, please contact a doctor.",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (issues.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    GradientButton(
                      label: "View Suggested Doctors",
                      icon: Icons.medical_services_outlined,
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DoctorsScreen(possibleIssues: issues),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Reports")),
        body: const Center(
          child: Text(
            "Please login.",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text("My Reports")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("reports")
            .where("uid", isEqualTo: user.uid)
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text("Error: ${snap.error}"));
          if (snap.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 52,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "No reports yet",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Scan a medical report to get started",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final summary = (data["summary"] ?? "No summary").toString();
              final createdAt = _formatDate(data["createdAt"]);
              final urgent =
                  (data["urgent_flags"] is List &&
                  (data["urgent_flags"] as List).isNotEmpty);

              return AppCard(
                onTap: () => _openReportPopup(context, data),
                child: Row(
                  children: [
                    IconBadge(
                      icon: Icons.description_outlined,
                      color: urgent ? AppColors.error : const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "Report",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (urgent) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    "Urgent",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            createdAt,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isList;
  final String content;
  final List<String> items;

  const _ReportSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.isList,
    this.content = "",
    this.items = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!isList)
            Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            )
          else
            ...items.map(
              (x) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6, right: 10),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        x,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
