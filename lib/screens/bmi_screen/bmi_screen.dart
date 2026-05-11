import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  final weightCtrl = TextEditingController();
  final heightCtrl = TextEditingController();

  double? bmi;
  String result = "";

  void calculateBmi() {
    final weight = double.tryParse(weightCtrl.text.trim());
    final heightCm = double.tryParse(heightCtrl.text.trim());

    if (weight == null || heightCm == null || weight <= 0 || heightCm <= 0) {
      setState(() {
        bmi = null;
        result = "Please enter valid weight and height.";
      });
      return;
    }

    final heightM = heightCm / 100;
    final value = weight / pow(heightM, 2);

    String category;
    if (value < 18.5) {
      category = "Underweight";
    } else if (value < 25) {
      category = "Normal";
    } else if (value < 30) {
      category = "Overweight";
    } else {
      category = "Obese";
    }

    setState(() {
      bmi = value;
      result = category;
    });
  }

  @override
  void dispose() {
    weightCtrl.dispose();
    heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BMI Calculator"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(18),
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
                Icon(Icons.monitor_weight, color: Colors.white, size: 42),
                SizedBox(height: 12),
                Text(
                  "Check Your BMI",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "BMI is a simple health indicator, not a medical diagnosis.",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: weightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Weight (kg)",
              prefixIcon: Icon(Icons.scale),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: heightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Height (cm)",
              prefixIcon: Icon(Icons.height),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: calculateBmi,
            child: const Text("Calculate BMI"),
          ),
          const SizedBox(height: 18),
          if (bmi != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                children: [
                  Text(
                    bmi!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    result,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
          else if (result.isNotEmpty)
            Text(result, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
