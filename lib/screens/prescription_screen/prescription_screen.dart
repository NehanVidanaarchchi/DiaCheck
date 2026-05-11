import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final user = FirebaseAuth.instance.currentUser;

  String doctorDocId = "";
  String doctorName = "Doctor";

  String? selectedPatientId;
  String? selectedPatientEmail;

  final titleCtrl = TextEditingController();
  final medicinesCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  bool loading = true;
  bool saving = false;

  List<Map<String, dynamic>> patients = [];

  @override
  void initState() {
    super.initState();
    _loadDoctorAndPatients();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    medicinesCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorAndPatients() async {
    if (user == null) return;

    DocumentSnapshot<Map<String, dynamic>>? doctorDoc;

    final byUid = await FirebaseFirestore.instance
        .collection("doctors")
        .doc(user!.uid)
        .get();

    if (byUid.exists) {
      doctorDoc = byUid;
    } else if (user!.email != null) {
      final byEmail = await FirebaseFirestore.instance
          .collection("doctors")
          .where("email", isEqualTo: user!.email)
          .limit(1)
          .get();

      if (byEmail.docs.isNotEmpty) doctorDoc = byEmail.docs.first;
    }

    if (doctorDoc == null) {
      if (!mounted) return;
      setState(() => loading = false);
      return;
    }

    doctorDocId = doctorDoc.id;
    doctorName = (doctorDoc.data()?["name"] ?? "Doctor").toString();

    final apptSnap = await FirebaseFirestore.instance
        .collection("appointments")
        .where("doctorId", isEqualTo: doctorDocId)
        .get();

    final map = <String, Map<String, dynamic>>{};

    for (final doc in apptSnap.docs) {
      final data = doc.data();
      final uid = (data["uid"] ?? "").toString();
      if (uid.isNotEmpty) {
        map[uid] = {
          "uid": uid,
          "email": (data["email"] ?? "Patient").toString(),
        };
      }
    }

    if (!mounted) return;

    setState(() {
      patients = map.values.toList();
      loading = false;
    });
  }

  Future<void> _savePrescription() async {
    if (selectedPatientId == null || titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select patient and enter title")),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await FirebaseFirestore.instance.collection("prescriptions").add({
        "doctorId": doctorDocId,
        "doctorName": doctorName,
        "patientId": selectedPatientId,
        "patientEmail": selectedPatientEmail ?? "",
        "title": titleCtrl.text.trim(),
        "medicines": medicinesCtrl.text.trim(),
        "note": noteCtrl.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection("notifications").add({
        "uid": selectedPatientId,
        "type": "prescription",
        "title": "New Prescription",
        "message": "$doctorName added a prescription for you.",
        "createdAt": FieldValue.serverTimestamp(),
        "read": false,
      });

      titleCtrl.clear();
      medicinesCtrl.clear();
      noteCtrl.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Prescription saved ✅")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Save failed: $e")));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String _formatDate(dynamic ts) {
    if (ts is! Timestamp) return "Unknown date";
    final d = ts.toDate();
    return "${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}";
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final stream = FirebaseFirestore.instance
        .collection("prescriptions")
        .where("doctorId", isEqualTo: doctorDocId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Prescriptions"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: selectedPatientId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: "Select Patient",
              border: OutlineInputBorder(),
            ),
            items: patients.map((p) {
              return DropdownMenuItem<String>(
                value: p["uid"],
                child: Text(p["email"]),
              );
            }).toList(),
            onChanged: (value) {
              final p = patients.firstWhere((x) => x["uid"] == value);
              setState(() {
                selectedPatientId = value;
                selectedPatientEmail = p["email"];
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(
              labelText: "Title",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: medicinesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Medicines",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Doctor Note",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: saving ? null : _savePrescription,
            icon: const Icon(Icons.save),
            label: Text(saving ? "Saving..." : "Save Prescription"),
          ),
          const SizedBox(height: 20),
          const Text(
            "Previous Prescriptions",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snap.data!.docs;

              if (docs.isEmpty) {
                return const Text("No prescriptions yet.");
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.medication),
                      ),
                      title: Text(data["title"] ?? "Prescription"),
                      subtitle: Text(
                        "${data["patientEmail"] ?? "Patient"}\n${_formatDate(data["createdAt"])}",
                      ),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
