import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SugarChartScreen extends StatefulWidget {
  const SugarChartScreen({super.key});

  @override
  State<SugarChartScreen> createState() => _SugarChartScreenState();
}

class _SugarChartScreenState extends State<SugarChartScreen> {
  final user = FirebaseAuth.instance.currentUser;

  double? _getSugarValue(Map<String, dynamic> data) {
    final keys = [
      "sugarLevel",
      "sugar_level",
      "glucose",
      "glucoseLevel",
      "bloodSugar",
      "blood_sugar",
    ];

    for (final key in keys) {
      final value = data[key];

      if (value is num) return value.toDouble();

      if (value is String) {
        final parsed = double.tryParse(
          value.replaceAll(RegExp(r'[^0-9.]'), ''),
        );
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  String _formatDate(dynamic ts) {
    if (ts is! Timestamp) return "";
    final d = ts.toDate();
    return "${d.month}/${d.day}";
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Sugar Level Chart")),
        body: const Center(child: Text("Please login.")),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection("reports")
        .where("uid", isEqualTo: user!.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Sugar Level Chart"), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];

          final items = docs
              .map((d) => d.data() as Map<String, dynamic>)
              .where((data) => _getSugarValue(data) != null)
              .toList();

          items.sort((a, b) {
            final at = a["createdAt"];
            final bt = b["createdAt"];

            if (at is Timestamp && bt is Timestamp) {
              return at.toDate().compareTo(bt.toDate());
            }

            return 0;
          });

          final spots = <FlSpot>[];

          for (int i = 0; i < items.length; i++) {
            final sugar = _getSugarValue(items[i]);
            if (sugar != null) {
              spots.add(FlSpot((i + 1).toDouble(), sugar));
            }
          }

          final hasData = spots.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sugar Progress",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Chart is loaded from your saved report data.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Container(
                height: 320,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black12),
                ),
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: hasData ? (spots.length + 1).toDouble() : 7,
                    minY: 70,
                    maxY: 220,
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: const AxisTitles(
                        axisNameWidget: Text(
                          "Sugar",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text(
                          "Reports",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt() - 1;

                            if (!hasData ||
                                index < 0 ||
                                index >= items.length) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _formatDate(items[index]["createdAt"]),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: hasData ? spots : const [],
                        isCurved: true,
                        barWidth: 4,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              if (!hasData)
                const Text(
                  "No sugar values found in your reports yet. Chart axes are shown ready for data.",
                  style: TextStyle(fontWeight: FontWeight.w700),
                )
              else
                Text(
                  "Showing ${spots.length} report value(s).",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),

              const SizedBox(height: 12),

              const Text(
                "Note: This chart is for progress tracking only. For medical decisions, contact a doctor.",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          );
        },
      ),
      backgroundColor: AppColors.surface,
    );
  }
}
