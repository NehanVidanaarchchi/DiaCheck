import 'package:flutter/material.dart';

class DietSuggestionsScreen extends StatelessWidget {
  const DietSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      {
        "title": "Balanced Plate",
        "text":
            "Fill half your plate with vegetables, one quarter with protein, and one quarter with whole grains.",
        "icon": Icons.restaurant,
      },
      {
        "title": "Reduce Added Sugar",
        "text": "Limit sugary drinks, sweets, and highly processed snacks.",
        "icon": Icons.no_drinks,
      },
      {
        "title": "Choose Whole Grains",
        "text":
            "Use brown rice, oats, whole wheat bread, and high-fiber foods where possible.",
        "icon": Icons.grain,
      },
      {
        "title": "Hydration",
        "text":
            "Drink enough water during the day. Avoid replacing water with sweet drinks.",
        "icon": Icons.water_drop,
      },
      {
        "title": "Regular Meals",
        "text":
            "Try to eat meals at consistent times to help maintain stable energy levels.",
        "icon": Icons.schedule,
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Diet Suggestions"), centerTitle: true),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = suggestions[i];

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF2F6BFF).withOpacity(0.12),
                  child: Icon(
                    item["icon"] as IconData,
                    color: const Color(0xFF2F6BFF),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["title"].toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item["text"].toString(),
                        style: const TextStyle(height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      backgroundColor: const Color(0xFFF6F8FC),
    );
  }
}
