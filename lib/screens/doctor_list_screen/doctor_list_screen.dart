import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';

class DoctorsScreen extends StatefulWidget {
  final List<String> possibleIssues;
  const DoctorsScreen({super.key, this.possibleIssues = const []});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  String _search = "";

  List<String> _suggestSpecialties(List<String> issues) {
    final text = issues.join(" ").toLowerCase();
    final set = <String>{};
    if (text.contains("blood pressure") || text.contains("hypertension") || text.contains("cholesterol")) set.add("Cardiologist");
    if (text.contains("sugar") || text.contains("glucose") || text.contains("diabetes") || text.contains("hba1c") || text.contains("thyroid") || text.contains("tsh")) set.add("Endocrinologist");
    if (text.contains("kidney") || text.contains("creatinine") || text.contains("urea") || text.contains("egfr")) set.add("Nephrologist");
    if (text.contains("liver") || text.contains("alt") || text.contains("ast") || text.contains("bilirubin")) set.add("Gastroenterologist");
    if (text.contains("infection") || text.contains("wbc") || text.contains("fever")) set.add("General Physician");
    if (text.contains("anemia") || text.contains("hemoglobin")) { set.add("Hematologist"); set.add("General Physician"); }
    if (set.isEmpty) set.add("General Physician");
    return set.toList();
  }

  bool _matchesSearch(Map<String, dynamic> d, String q) {
    if (q.isEmpty) return true;
    return ["name","specialty","hospital","city"].any(
      (k) => (d[k] ?? "").toString().toLowerCase().contains(q),
    );
  }

  Future<void> _openDoctorPopup(BuildContext context, Map<String, dynamic> d) async {
    String s(dynamic v) => (v ?? "").toString();
    final days = (d["availableDays"] is List) ? (d["availableDays"] as List).map((e) => e.toString()).toList() : <String>[];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const IconBadge(icon: Icons.medical_services_outlined, color: AppColors.accent, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s(d["name"]), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(s(d["specialty"]), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent)),
                    ],
                  ),
                ),
                if (d["rating"] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFDE68A))),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text("${d["rating"]}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFB45309))),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 16),
            if (s(d["hospital"]).isNotEmpty) _DetailRow(Icons.local_hospital_outlined, s(d["hospital"])),
            if (s(d["city"]).isNotEmpty) _DetailRow(Icons.location_on_outlined, s(d["city"])),
            if (d["fee"] != null) _DetailRow(Icons.payments_outlined, "Rs. ${d["fee"]}"),
            if (days.isNotEmpty) _DetailRow(Icons.event_available_outlined, days.join(", ")),
            if (s(d["phone"]).isNotEmpty) _DetailRow(Icons.phone_outlined, s(d["phone"])),
            if (s(d["email"]).isNotEmpty) _DetailRow(Icons.mail_outline_rounded, s(d["email"])),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _doctorCard(BuildContext context, Map<String, dynamic> d) {
    final name = (d["name"] ?? "Doctor").toString();
    final spec = (d["specialty"] ?? "General").toString();
    final hospital = (d["hospital"] ?? "").toString();
    final city = (d["city"] ?? "").toString();
    final location = [hospital, city].where((x) => x.isNotEmpty).join(" • ");

    return AppCard(
      onTap: () => _openDoctorPopup(context, d),
      child: Row(
        children: [
          const IconBadge(icon: Icons.medical_services_outlined, color: AppColors.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(spec, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Expanded(child: Text(location, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (d["rating"] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 3),
                  Text("${d["rating"]}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFFB45309))),
                ],
              ),
            ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestedSpecialties = _suggestSpecialties(widget.possibleIssues);
    final searchLower = _search.trim().toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text("Find Doctors")),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search by name, specialty, city...",
                hintStyle: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                        onPressed: () => setState(() => _search = ""),
                      )
                    : null,
              ),
            ),
          ),

          // Suggested specialty chips
          if (widget.possibleIssues.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 12),
                  const Text("Recommended specialties:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: suggestedSpecialties.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    )).toList(),
                  ),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("doctors").where("active", isEqualTo: true).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snap.hasError) return Center(child: Text("Error: ${snap.error}"));

                final all = (snap.data?.docs ?? [])
                    .map((e) => e.data() as Map<String, dynamic>)
                    .where((d) => _matchesSearch(d, searchLower))
                    .toList();

                final suggested = all.where((d) {
                  final spec = (d["specialty"] ?? "").toString().toLowerCase();
                  return suggestedSpecialties.any((s) => s.toLowerCase() == spec);
                }).toList();

                final suggestedNames = suggested.map((d) => (d["name"] ?? "").toString()).toSet();
                final remaining = all.where((d) => !suggestedNames.contains((d["name"] ?? "").toString())).toList();

                if (all.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 42, color: AppColors.textMuted),
                        SizedBox(height: 10),
                        Text("No doctors found", style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    if (suggested.isNotEmpty) ...[
                      const SectionHeader(title: "Suggested for You", icon: Icons.recommend_outlined),
                      const SizedBox(height: 12),
                      ...suggested.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _doctorCard(context, d),
                      )),
                      const SizedBox(height: 8),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 8),
                    ],
                    const SectionHeader(title: "All Doctors", icon: Icons.people_outline_rounded),
                    const SizedBox(height: 12),
                    if (remaining.isEmpty && suggested.isEmpty)
                      const Text("No results found.", style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600))
                    else
                      ...remaining.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _doctorCard(context, d),
                      )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}