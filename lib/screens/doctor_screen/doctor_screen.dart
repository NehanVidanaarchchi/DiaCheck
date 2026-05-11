import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login & signup_screens/login_screen.dart';
import '../prescription_screen/prescription_screen.dart';
import '../patient_history_screen/patient_history_screen.dart';


class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final user = FirebaseAuth.instance.currentUser;

  String doctorDocId = "";
  String doctorName = "Doctor";
  String specialty = "";
  String hospital = "";

  int appointmentsCount = 0;
  int reportCount = 0;
  int patientCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _loadDoctorData();
    await _loadCounts();
  }

  Future<void> _loadDoctorData() async {
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

    if (!mounted) return;

    if (doctorDoc != null) {
      final data = doctorDoc.data() ?? {};
      setState(() {
        doctorDocId = doctorDoc!.id;
        doctorName = (data["name"] ?? "Doctor").toString();
        specialty = (data["specialty"] ?? "").toString();
        hospital = (data["hospital"] ?? "").toString();
      });
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getAppointments() async {
    if (doctorDocId.isEmpty) throw Exception("Doctor profile not found");

    return FirebaseFirestore.instance
        .collection("appointments")
        .where("doctorId", isEqualTo: doctorDocId)
        .get();
  }

  Future<void> _loadCounts() async {
    if (doctorDocId.isEmpty) return;

    final apptSnap = await _getAppointments();

    final reportSnap = await FirebaseFirestore.instance
        .collection("reports")
        .where("doctorId", isEqualTo: doctorDocId)
        .get();

    final patientIds = <String>{};

    for (final doc in apptSnap.docs) {
      final uid = doc.data()["uid"];
      if (uid != null && uid.toString().isNotEmpty) {
        patientIds.add(uid.toString());
      }
    }

    if (!mounted) return;

    setState(() {
      appointmentsCount = apptSnap.size;
      reportCount = reportSnap.size;
      patientCount = patientIds.length;
    });
  }

  String _formatDate(dynamic ts) {
    if (ts is! Timestamp) return "Unknown date";
    final d = ts.toDate();
    return "${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")} "
        "${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}";
  }

  Widget _riskBadge(String risk) {
    Color color;

    if (risk == "Normal") {
      color = Colors.green;
    } else if (risk == "Pre-diabetic") {
      color = Colors.orange;
    } else if (risk == "High risk") {
      color = Colors.red;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        risk,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _showAppointmentsPopup() async {
    final snap = await _getAppointments();

    final appointments = snap.docs.map((d) {
      return {"id": d.id, ...d.data()};
    }).toList();

    appointments.sort((a, b) {
      final at = a["dateTime"];
      final bt = b["dateTime"];
      if (at is Timestamp && bt is Timestamp) {
        return at.toDate().compareTo(bt.toDate());
      }
      return 0;
    });

    if (!mounted) return;

    _showListPopup(
      title: "Appointments",
      emptyText: "No appointments found.",
      children: appointments.map((data) {
        final patientEmail = (data["email"] ?? "Patient").toString();
        final note = (data["note"] ?? "").toString();
        final status = (data["status"] ?? "pending").toString();
        final date = _formatDate(data["dateTime"]);

        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.calendar_month)),
          title: Text(patientEmail),
          subtitle: Text("$date\nStatus: $status${note.isEmpty ? "" : "\n$note"}"),
          isThreeLine: true,
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              await FirebaseFirestore.instance
                  .collection("appointments")
                  .doc(data["id"])
                  .update({"status": value});

              if (!mounted) return;
              Navigator.pop(context);
              await _loadAllData();
              _showAppointmentsPopup();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: "accepted", child: Text("Accept")),
              PopupMenuItem(value: "completed", child: Text("Complete")),
              PopupMenuItem(value: "cancelled", child: Text("Cancel")),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showPatientsPopup() async {
    final snap = await _getAppointments();
    final patientMap = <String, Map<String, dynamic>>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      final uid = (data["uid"] ?? "").toString();
      if (uid.isNotEmpty) {
        patientMap[uid] = {
          "uid": uid,
          "email": data["email"] ?? "Patient",
        };
      }
    }

    if (!mounted) return;

    _showListPopup(
      title: "Patients",
      emptyText: "No patients found.",
      children: patientMap.values.map((p) {
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(p["email"].toString()),
          subtitle: Text("UID: ${p["uid"]}"),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientHistoryScreen(
                  doctorId: doctorDocId,
                  patientId: p["uid"],
                  patientEmail: p["email"],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Future<void> _showReportsPopup() async {
    final snap = await FirebaseFirestore.instance
        .collection("reports")
        .where("doctorId", isEqualTo: doctorDocId)
        .get();

    if (!mounted) return;

    _showListPopup(
      title: "Reports",
      emptyText: "No reports assigned.",
      children: snap.docs.map((doc) {
        final data = doc.data();
        final risk = (data["riskLevel"] ?? "Unknown").toString();

        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.description)),
          title: Text((data["email"] ?? "Patient").toString()),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatDate(data["createdAt"])),
              const SizedBox(height: 6),
              _riskBadge(risk),
              const SizedBox(height: 6),
              Text(
                (data["summary"] ?? "No summary").toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          isThreeLine: true,
        );
      }).toList(),
    );
  }

  void _showListPopup({
    required String title,
    required String emptyText,
    required List<Widget> children,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: children.isEmpty
              ? Text(emptyText)
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: children.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) => children[i],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (specialty.isNotEmpty) specialty,
      if (hospital.isNotEmpty) hospital,
    ].join(" • ");

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text("Doctor Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF2F6BFF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.medical_services_rounded,
                        color: Color(0xFF2F6BFF), size: 34),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome, $doctorName",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(
                          subtitle.isEmpty
                              ? "Manage patients, reports and appointments"
                              : subtitle,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.05,
              children: [
                _DoctorTile(
                  title: "Patients",
                  subtitle: "$patientCount patients",
                  icon: Icons.people_alt_rounded,
                  color: Colors.blue,
                  onTap: _showPatientsPopup,
                ),
                _DoctorTile(
                  title: "Reports",
                  subtitle: "$reportCount reports",
                  icon: Icons.description_rounded,
                  color: Colors.deepPurple,
                  onTap: _showReportsPopup,
                ),
                _DoctorTile(
                  title: "Appointments",
                  subtitle: "$appointmentsCount total",
                  icon: Icons.calendar_month_rounded,
                  color: Colors.redAccent,
                  onTap: _showAppointmentsPopup,
                ),
                _DoctorTile(
                  title: "Prescriptions",
                  subtitle: "Add medicines",
                  icon: Icons.medication_rounded,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrescriptionScreen(),
                      ),
                    );
                  },
                ),
                _DoctorTile(
                  title: "History",
                  subtitle: "Patient reports",
                  icon: Icons.timeline_rounded,
                  color: Colors.green,
                  onTap: _showPatientsPopup,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DoctorTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const Spacer(),
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}