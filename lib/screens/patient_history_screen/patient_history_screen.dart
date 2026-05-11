import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PatientHistoryScreen extends StatelessWidget {
  final String doctorId;
  final String patientId;
  final String patientEmail;

  const PatientHistoryScreen({
    super.key,
    required this.doctorId,
    required this.patientId,
    required this.patientEmail,
  });

  double? _getSugar(Map<String, dynamic> data) {
    final keys = [
      "sugarLevel",
      "sugar_level",
      "glucose",
      "glucoseLevel",
      "bloodSugar",
      "blood_sugar",
    ];

    for (final key in keys) {
      final v = data[key];
      if (v is num) return v.toDouble();
      if (v is String) {
        final p = double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), ''));
        if (p != null) return p;
      }
    }

    return null;
  }

  String _formatDate(dynamic ts) {
    if (ts is! Timestamp) return "Unknown date";
    final d = ts.toDate();
    return "${d.month}/${d.day}";
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
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection("reports")
        .where("uid", isEqualTo: patientId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Patient History"), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snap.data!.docs
              .map((d) => d.data() as Map<String, dynamic>)
              .toList();

          reports.sort((a, b) {
            final at = a["createdAt"];
            final bt = b["createdAt"];
            if (at is Timestamp && bt is Timestamp) {
              return at.toDate().compareTo(bt.toDate());
            }
            return 0;
          });

          final spots = <FlSpot>[];

          for (int i = 0; i < reports.length; i++) {
            final sugar = _getSugar(reports[i]);
            if (sugar != null) {
              spots.add(FlSpot((i + 1).toDouble(), sugar));
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                patientEmail,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                height: 280,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black12),
                ),
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: spots.isEmpty ? 7 : (spots.length + 1).toDouble(),
                    minY: 70,
                    maxY: 220,
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(
                        axisNameWidget: Text("Sugar"),
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 42),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: Text("Reports"),
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 4,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text("Reports",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 10),
              if (reports.isEmpty)
                const Text("No reports found.")
              else
                ...reports.reversed.map((data) {
                  final risk = (data["riskLevel"] ?? "Unknown").toString();

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.description)),
                      title: Text(_formatDate(data["createdAt"])),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          _riskBadge(risk),
                          const SizedBox(height: 6),
                          Text(
                            (data["summary"] ?? "No summary").toString(),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
      backgroundColor: const Color(0xFFF6F8FC),
    );
  }
}