import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  User? get _user => FirebaseAuth.instance.currentUser;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  List<Map<String, dynamic>> _eventsForSelectedDay = [];

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _loadEventsForDay(_selectedDay);
  }

  Future<void> _loadEventsForDay(DateTime day) async {
    final user = _user;
    if (user == null) return;

    debugPrint("LOGGED USER UID: ${user.uid}");

    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    try {
      final snap = await FirebaseFirestore.instance
          .collection("appointments")
          .where("uid", isEqualTo: user.uid)
          .get();

      final items = <Map<String, dynamic>>[];

      for (final doc in snap.docs) {
        final data = doc.data();

        debugPrint("APPOINTMENT DOC: ${doc.id}");
        debugPrint("APPOINTMENT UID: ${data["uid"]}");

        if ((data["uid"] ?? "").toString() != user.uid) continue;

        final ts = data["dateTime"];
        if (ts is! Timestamp) continue;

        final dt = ts.toDate();
        if (!dt.isBefore(start) && dt.isBefore(end)) {
          items.add({"id": doc.id, ...data});
        }
      }

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
        _eventsForSelectedDay = items;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Load appointments failed: $e")));
    }
  }

  Future<void> _addAppointmentDialog() async {
    final user = _user;
    if (user == null) return;

    final noteCtrl = TextEditingController();

    DateTime pickedDate = _selectedDay;
    TimeOfDay pickedTime = TimeOfDay.now();

    String? selectedDoctorId;
    String? selectedDoctorName;

    List<Map<String, String>> doctors = [];

    try {
      final doctorSnap = await FirebaseFirestore.instance
          .collection("doctors")
          .where("active", isEqualTo: true)
          .get();

      doctors = doctorSnap.docs.map((doc) {
        final data = doc.data();

        return {
          "id": doc.id,
          "name": (data["name"] ?? "Doctor").toString(),
          "specialty": (data["specialty"] ?? "").toString(),
          "hospital": (data["hospital"] ?? "").toString(),
        };
      }).toList();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Doctor load failed: $e")));
      return;
    }

    if (doctors.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No active doctors found.")));
      return;
    }

    Future<void> pickDate(StateSetter setDialogState) async {
      final d = await showDatePicker(
        context: context,
        initialDate: pickedDate,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      );

      if (d != null) {
        setDialogState(() => pickedDate = d);
      }
    }

    Future<void> pickTime(StateSetter setDialogState) async {
      final t = await showTimePicker(context: context, initialTime: pickedTime);

      if (t != null) {
        setDialogState(() => pickedTime = t);
      }
    }

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add Appointment"),
              content: SingleChildScrollView(
                child: Column(
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
                      onChanged: (value) {
                        final doctor = doctors.firstWhere(
                          (d) => d["id"] == value,
                        );

                        setDialogState(() {
                          selectedDoctorId = value;
                          selectedDoctorName = doctor["name"];
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteCtrl,
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
                            onPressed: () => pickDate(setDialogState),
                            icon: const Icon(Icons.calendar_month),
                            label: Text(
                              "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, "0")}-${pickedDate.day.toString().padLeft(2, "0")}",
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickTime(setDialogState),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedDoctorId == null ||
                        selectedDoctorName == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a doctor")),
                      );
                      return;
                    }

                    try {
                      final dateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );

                      await FirebaseFirestore.instance
                          .collection("appointments")
                          .add({
                            "uid": user.uid,
                            "email": user.email ?? "",
                            "doctorId": selectedDoctorId,
                            "doctorName": selectedDoctorName,
                            "note": noteCtrl.text.trim(),
                            "status": "pending",
                            "dateTime": Timestamp.fromDate(dateTime),
                            "createdAt": FieldValue.serverTimestamp(),
                          });

                      await FirebaseFirestore.instance
                          .collection("notifications")
                          .add({
                            "uid": user.uid,
                            "type": "appointment",
                            "title": "Appointment Added",
                            "message":
                                "Appointment with $selectedDoctorName has been added.",
                            "createdAt": FieldValue.serverTimestamp(),
                            "read": false,
                          });

                      if (!mounted) return;

                      Navigator.pop(context);
                      await _loadEventsForDay(_selectedDay);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Appointment saved ✅")),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Save failed: $e")),
                      );
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );

    noteCtrl.dispose();
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

    final appointmentsStream = FirebaseFirestore.instance
        .collection("appointments")
        .where("uid", isEqualTo: user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAppointmentDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: appointmentsStream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }

          final allDocs = snap.data?.docs ?? [];
          final Map<DateTime, int> countByDay = {};

          for (final doc in allDocs) {
            final data = doc.data() as Map<String, dynamic>;

            if ((data["uid"] ?? "").toString() != user.uid) continue;

            final ts = data["dateTime"];
            if (ts is Timestamp) {
              final day = _dateOnly(ts.toDate());
              countByDay[day] = (countByDay[day] ?? 0) + 1;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                  color: Colors.white,
                ),
                child: TableCalendar(
                  firstDay: DateTime.now().subtract(
                    const Duration(days: 365 * 2),
                  ),
                  lastDay: DateTime.now().add(const Duration(days: 365 * 3)),
                  focusedDay: _focusedDay,
                  calendarFormat: _format,
                  selectedDayPredicate: (day) {
                    return isSameDay(day, _selectedDay);
                  },
                  onFormatChanged: (f) {
                    setState(() => _format = f);
                  },
                  onDaySelected: (selected, focused) async {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });

                    await _loadEventsForDay(selected);
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      final count = countByDay[_dateOnly(day)] ?? 0;

                      if (count == 0) return null;

                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.redAccent,
                          ),
                          child: Text(
                            "$count",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Appointments on ${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, "0")}-${_selectedDay.day.toString().padLeft(2, "0")}",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
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
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.deepPurple.withOpacity(0.10),
                          ),
                          child: const Icon(
                            Icons.event_available,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$time • $doctor",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Status: $status",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
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
          );
        },
      ),
      backgroundColor: Colors.white,
    );
  }
}
