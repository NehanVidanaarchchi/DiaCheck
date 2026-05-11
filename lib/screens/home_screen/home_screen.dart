import 'package:flutter/material.dart';
import '../scan_screen/scan_screen.dart';
import '../report_screen/report_screen.dart';
import '../doctor_list_screen/doctor_list_screen.dart';
import '../bmi_screen/bmi_screen.dart';
import '../diet_suggestion_screen/diet_suggestion_screen.dart';
import '../exercise_recommendation_screen/exercise_recommendation_screen.dart';
import '../language_screen/language_screen.dart';
import '../sugar_chart_screen/sugar_chart_screen.dart';
import '../my_prescriptions_screen/my_prescriptions_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';
import '../../screens/chat_screen/chat_screen.dart' hide AppColors;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Your Health Hub",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Scan reports, track health\nand connect with doctors.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      title: "Scan Report",
                      subtitle: "Upload & analyze\nyour medical reports",
                      icon: Icons.document_scanner_outlined,
                      color: AppColors.primary,
                      onTap: () => _open(context, const ScanScreen()),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ActionCard(
                      title: "Find Doctor",
                      subtitle: "Search specialists\nand appointments",
                      icon: Icons.medical_services_outlined,
                      color: AppColors.accent,
                      onTap: () => _open(context, const DoctorsScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      title: "BMI",
                      subtitle: "Calculate your\nbody mass index",
                      icon: Icons.monitor_weight_outlined,
                      color: Colors.orange,
                      onTap: () => _open(context, const BmiScreen()),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ActionCard(
                      title: "Sugar Chart",
                      subtitle: "View health\nprogress graph",
                      icon: Icons.show_chart_rounded,
                      color: Colors.green,
                      onTap: () => _open(context, const SugarChartScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _ActionCard(
                title: "My Reports",
                subtitle:
                    "View all your past scan results and health summaries",
                icon: Icons.description_outlined,
                color: const Color(0xFF8B5CF6),
                onTap: () => _open(context, const ReportsScreen()),
                wide: true,
              ),

              const SizedBox(height: 14),

              _ActionCard(
                title: "My Prescriptions",
                subtitle: "View medicines and notes added by your doctor",
                icon: Icons.medication_rounded,
                color: Colors.orange,
                onTap: () => _open(context, const MyPrescriptionsScreen()),
                wide: true,
              ),

              const SizedBox(height: 14),

              _ActionCard(
                title: "Diet Suggestions",
                subtitle: "Healthy meal ideas and sugar-control food tips",
                icon: Icons.restaurant_menu_rounded,
                color: Colors.teal,
                onTap: () => _open(context, const DietSuggestionsScreen()),
                wide: true,
              ),

              const SizedBox(height: 14),

              _ActionCard(
                title: "Exercise Recommendations",
                subtitle: "Simple exercise plans for a healthier lifestyle",
                icon: Icons.fitness_center_rounded,
                color: Colors.redAccent,
                onTap: () =>
                    _open(context, const ExerciseRecommendationsScreen()),
                wide: true,
              ),

              const SizedBox(height: 14),

              _ActionCard(
                title: "Language",
                subtitle: "Change app language settings",
                icon: Icons.language_rounded,
                color: Colors.blueGrey,
                onTap: () => _open(context, const LanguageScreen()),
                wide: true,
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),

        Positioned(
          right: 20,
          bottom: 20,
          child: ChatbotLauncherButton(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.75,
                    child: const Center(
                      child: Text(
                        'Your chatbot UI goes here',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool wide;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: wide
            ? Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: color),
                ],
              ),
      ),
    );
  }
}
