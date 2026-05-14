import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  User? get _user => FirebaseAuth.instance.currentUser;

  DateTime _selectedDay = DateTime.now();
  bool _loading = true;

  List<Map<String, dynamic>> _allAppointments = [];
  List<Map<String, dynamic>> _eventsForSelectedDay = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Map<String, dynamic>> _eventsForDay(DateTime day) {
    return _allAppointments.where((data) {
      final ts = data["dateTime"];
      if (ts is! Timestamp) return false;
      return _sameDay(ts.toDate(), day);
    }).toList();
  }

  Future<void> _loadAppointments() async {
    final user = _user;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection("appointments")
          .where("uid", isEqualTo: user.uid)
          .get();

      final items = snap.docs
          .map((doc) {
            return {"id": doc.id, ...doc.data()};
          })
          .where((data) {
            return (data["uid"] ?? "").toString() == user.uid;
          })
          .toList();

      items.sort((a, b) {
        final at = a["dateTime"];
        final bt = b["dateTime"];

        if (at is Timestamp && bt is Timestamp) {
          return at.toDate().compareTo(bt.toDate());
        }

        return 0;
      });

      if (!mounted) return;

      setState(() {
        _allAppointments = items;
        _eventsForSelectedDay = _eventsForDay(_selectedDay);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Load appointments failed: $e")));
    }
  }

  Future<void> _openAddAppointmentPopup() async {
    final user = _user;
    if (user == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AddAppointmentPopup(user: user);
      },
    );

    if (result == true) {
      await _loadAppointments();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Appointment saved ✅")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Calendar"), centerTitle: true),
        body: const Center(
          child: Text(
            "Please login to view calendar.",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddAppointmentPopup,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
              color: Colors.white,
            ),
            child: CalendarDatePicker(
              initialDate: _selectedDay,
              firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
              onDateChanged: (date) {
                setState(() {
                  _selectedDay = _dateOnly(date);
                  _eventsForSelectedDay = _eventsForDay(date);
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Text(
                  "Appointments on ${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, "0")}-${_selectedDay.day.toString().padLeft(2, "0")}",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 16,
                child: Text(
                  "${_eventsForSelectedDay.length}",
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_eventsForSelectedDay.isEmpty)
            const Text(
              "No appointments for this day.",
              style: TextStyle(fontWeight: FontWeight.w700),
            )
          else
            ..._eventsForSelectedDay.map((e) {
              final ts = e["dateTime"] as Timestamp?;
              final dt = ts?.toDate();

              final time = dt == null
                  ? "Unknown time"
                  : "${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}";

              final doctor = (e["doctorName"] ?? "Doctor").toString();
              final note = (e["note"] ?? "").toString();
              final status = (e["status"] ?? "pending").toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available, color: Colors.deepPurple),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$time • $doctor",
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Status: $status",
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (note.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(note),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}

class AddAppointmentPopup extends StatefulWidget {
  final User user;

  const AddAppointmentPopup({super.key, required this.user});

  @override
  State<AddAppointmentPopup> createState() => _AddAppointmentPopupState();
}

class _AddAppointmentPopupState extends State<AddAppointmentPopup> {
  final TextEditingController _noteCtrl = TextEditingController();

  bool _loadingDoctors = true;
  bool _saving = false;

  DateTime pickedDate = DateTime.now();
  TimeOfDay pickedTime = TimeOfDay.now();

  String? selectedDoctorId;
  String? selectedDoctorName;

  List<Map<String, String>> doctors = [];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("doctors")
          .where("active", isEqualTo: true)
          .get();

      final list = snap.docs.map((doc) {
        final data = doc.data();

        return {
          "id": doc.id,
          "name": (data["name"] ?? "Doctor").toString(),
          "specialty": (data["specialty"] ?? "").toString(),
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        doctors = list;
        _loadingDoctors = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingDoctors = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Doctor load failed: $e")));
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: pickedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (d != null && mounted) {
      setState(() => pickedDate = d);
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: pickedTime);

    if (t != null && mounted) {
      setState(() => pickedTime = t);
    }
  }

  Future<void> _saveAppointment() async {
    if (selectedDoctorId == null || selectedDoctorName == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a doctor")));
      return;
    }

    setState(() => _saving = true);

    try {
      final dateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      await FirebaseFirestore.instance.collection("appointments").add({
        "uid": widget.user.uid,
        "email": widget.user.email ?? "",
        "doctorId": selectedDoctorId,
        "doctorName": selectedDoctorName,
        "note": _noteCtrl.text.trim(),
        "status": "pending",
        "dateTime": Timestamp.fromDate(dateTime),
        "createdAt": FieldValue.serverTimestamp(),
      });

      try {
        await FirebaseFirestore.instance.collection("notifications").add({
          "uid": widget.user.uid,
          "type": "appointment",
          "title": "Appointment Added",
          "message": "Appointment with $selectedDoctorName has been added.",
          "createdAt": FieldValue.serverTimestamp(),
          "read": false,
        });
      } catch (_) {}

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Appointment save failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingDoctors) {
      return const AlertDialog(
        content: SizedBox(
          height: 90,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (doctors.isEmpty) {
      return AlertDialog(
        title: const Text("Add Appointment"),
        content: const Text("No active doctors found."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Close"),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text("Add Appointment"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedDoctorId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Select Doctor",
                prefixIcon: Icon(Icons.medical_services_outlined),
              ),
              items: doctors.map((doctor) {
                return DropdownMenuItem<String>(
                  value: doctor["id"],
                  child: Text(
                    "${doctor["name"]} - ${doctor["specialty"]}",
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      final doctor = doctors.firstWhere(
                        (d) => d["id"] == value,
                      );

                      setState(() {
                        selectedDoctorId = value;
                        selectedDoctorName = doctor["name"];
                      });
                    },
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _noteCtrl,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: "Note",
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _pickDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, "0")}-${pickedDate.day.toString().padLeft(2, "0")}",
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      "${pickedTime.hour.toString().padLeft(2, "0")}:${pickedTime.minute.toString().padLeft(2, "0")}",
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _saveAppointment,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Save"),
        ),
      ],
    );
  }
}
