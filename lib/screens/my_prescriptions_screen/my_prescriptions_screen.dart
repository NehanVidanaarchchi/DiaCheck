import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyPrescriptionsScreen extends StatelessWidget {
  const MyPrescriptionsScreen({super.key});

  String _formatDate(dynamic ts) {
    if (ts is! Timestamp) return "Unknown date";

    final d = ts.toDate();

    return "${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")} "
        "${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}";
  }

  void _openPrescriptionPopup(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text((data["title"] ?? "Prescription").toString()),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Doctor: ${data["doctorName"] ?? "Doctor"}",
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  "Date: ${_formatDate(data["createdAt"])}",
                  style: TextStyle(color: Colors.black.withOpacity(0.6)),
                ),
                const SizedBox(height: 16),

                const Text(
                  "Medicines",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text((data["medicines"] ?? "No medicines added").toString()),

                const SizedBox(height: 16),

                const Text(
                  "Doctor Note",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text((data["note"] ?? "No note added").toString()),

                const SizedBox(height: 16),

                const Text(
                  "Note: Follow your doctor’s instructions. Contact your doctor if you feel unwell.",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Prescriptions")),
        body: const Center(
          child: Text(
            "Please login to view prescriptions.",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection("prescriptions")
        .where("patientId", isEqualTo: user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("My Prescriptions"), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          final prescriptions = docs.map((d) {
            return {"id": d.id, ...(d.data() as Map<String, dynamic>)};
          }).toList();

          prescriptions.sort((a, b) {
            final at = a["createdAt"];
            final bt = b["createdAt"];

            if (at is Timestamp && bt is Timestamp) {
              return bt.toDate().compareTo(at.toDate());
            }

            return 0;
          });

          if (prescriptions.isEmpty) {
            return const Center(
              child: Text(
                "No prescriptions found.",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: prescriptions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final data = prescriptions[i];

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _openPrescriptionPopup(context, data),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.medication_rounded,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (data["title"] ?? "Prescription").toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Doctor: ${data["doctorName"] ?? "Doctor"}",
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.65),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(data["createdAt"]),
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Icon(
                        Icons.chevron_right,
                        color: Colors.black.withOpacity(0.35),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      backgroundColor: const Color(0xFFF6F8FC),
    );
  }
}
