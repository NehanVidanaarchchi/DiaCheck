import 'dart:math';

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
    if (ts is! Timestamp) return "No date";
    final d = ts.toDate();
    return "${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}";
  }

  String _shortDate(dynamic ts) {
    if (ts is! Timestamp) return "";
    final d = ts.toDate();
    return "${d.month}/${d.day}";
  }

  String _risk(double value) {
    if (value < 100) return "Normal";
    if (value < 126) return "Pre-diabetic";
    return "High risk";
  }

  Color _riskColor(String risk) {
    if (risk == "Normal") return Colors.green;
    if (risk == "Pre-diabetic") return Colors.orange;
    return Colors.red;
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
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          final items = docs
              .map((d) => {"id": d.id, ...(d.data() as Map<String, dynamic>)})
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
          final values = <double>[];

          for (int i = 0; i < items.length; i++) {
            final sugar = _getSugarValue(items[i]);
            if (sugar != null) {
              values.add(sugar);
              spots.add(FlSpot((i + 1).toDouble(), sugar));
            }
          }

          final hasData = spots.isNotEmpty;

          final latest = hasData ? values.last : 0.0;
          final avg = hasData
              ? values.reduce((a, b) => a + b) / values.length
              : 0.0;
          final highest = hasData ? values.reduce(max) : 0.0;
          final lowest = hasData ? values.reduce(min) : 0.0;

          final minY = hasData ? max(0, (lowest - 20)).floorToDouble() : 70.0;
          final maxY = hasData ? (highest + 20).ceilToDouble() : 220.0;

          final latestRisk = hasData ? _risk(latest) : "No data";
          final latestColor = hasData ? _riskColor(latestRisk) : Colors.grey;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
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
                            "Loaded from your saved report data.",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        hasData ? latestRisk : "No data",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (hasData)
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: "Latest",
                        value: latest.toStringAsFixed(0),
                        icon: Icons.bloodtype_rounded,
                        color: latestColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        title: "Average",
                        value: avg.toStringAsFixed(0),
                        icon: Icons.analytics_rounded,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),

              if (hasData) const SizedBox(height: 10),

              if (hasData)
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: "Highest",
                        value: highest.toStringAsFixed(0),
                        icon: Icons.trending_up_rounded,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        title: "Lowest",
                        value: lowest.toStringAsFixed(0),
                        icon: Icons.trending_down_rounded,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 18),

              Container(
                height: 340,
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
                    minY: minY,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: 20,
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.black.withOpacity(0.08),
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (_) => FlLine(
                        color: Colors.black.withOpacity(0.04),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.black12),
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) {
                          return spots.map((spot) {
                            final index = spot.x.toInt() - 1;
                            final date = index >= 0 && index < items.length
                                ? _formatDate(items[index]["createdAt"])
                                : "";
                            return LineTooltipItem(
                              "Sugar: ${spot.y.toStringAsFixed(0)}\n$date",
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
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
                          interval: 20,
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
                                _shortDate(items[index]["createdAt"]),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
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
                        color: hasData ? latestColor : Colors.grey,
                        belowBarData: BarAreaData(
                          show: hasData,
                          color: latestColor.withOpacity(0.12),
                        ),
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              if (!hasData)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: const Text(
                    "No sugar values found in your reports yet. Scan reports that include glucose/sugar values to build your chart.",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
              else
                Text(
                  "Showing ${spots.length} report value(s). Tap the chart dots to view details.",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),

              const SizedBox(height: 18),

              if (hasData) ...[
                const Text(
                  "Recent Readings",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 10),
                ...items.reversed.map((data) {
                  final sugar = _getSugarValue(data)!;
                  final risk = _risk(sugar);
                  final color = _riskColor(risk);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withOpacity(0.12),
                          child: Icon(Icons.bloodtype, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${sugar.toStringAsFixed(0)} mg/dL",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _formatDate(data["createdAt"]),
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.55),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
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
                        ),
                      ],
                    ),
                  );
                }),
              ],

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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
