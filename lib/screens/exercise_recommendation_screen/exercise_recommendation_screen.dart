import 'package:flutter/material.dart';

class ExerciseRecommendationsScreen extends StatelessWidget {
  const ExerciseRecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exercises = [
      {
        "title": "Walking",
        "time": "20–30 minutes",
        "desc":
            "A simple daily walk can help improve fitness and support blood sugar control.",
        "icon": Icons.directions_walk,
      },
      {
        "title": "Stretching",
        "time": "10 minutes",
        "desc": "Light stretching helps flexibility and reduces stiffness.",
        "icon": Icons.accessibility_new,
      },
      {
        "title": "Cycling",
        "time": "15–25 minutes",
        "desc": "Low-impact cardio exercise suitable for many people.",
        "icon": Icons.directions_bike,
      },
      {
        "title": "Light Strength Training",
        "time": "2–3 days/week",
        "desc":
            "Bodyweight exercises like squats or wall push-ups can improve strength.",
        "icon": Icons.fitness_center,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Exercise Recommendations"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Start slowly and stop if you feel unwell. Ask a doctor before heavy exercise.",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          ...exercises.map((e) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.12),
                    child: Icon(e["icon"] as IconData, color: Colors.green),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e["title"].toString(),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e["time"].toString(),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(e["desc"].toString()),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      backgroundColor: const Color(0xFFF6F8FC),
    );
  }
}
