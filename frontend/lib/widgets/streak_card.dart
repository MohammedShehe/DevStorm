import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../theme/app_colors.dart';

class StreakAndAdherenceCard extends StatelessWidget {
  final int streakDays;
  final double adherence; // 0.0 - 1.0

  const StreakAndAdherenceCard({super.key, required this.streakDays, required this.adherence});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 6),
                    Text(
                      '$streakDays-day streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Keep it going! Consistency\nimproves treatment outcomes.',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
          CircularPercentIndicator(
            radius: 38,
            lineWidth: 8,
            percent: adherence.clamp(0.0, 1.0),
            animation: true,
            animationDuration: 900,
            backgroundColor: Colors.white.withOpacity(0.25),
            progressColor: Colors.white,
            circularStrokeCap: CircularStrokeCap.round,
            center: Text(
              '${(adherence * 100).round()}%',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
