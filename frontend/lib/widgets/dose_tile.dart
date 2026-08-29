import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dose_log_model.dart';
import '../theme/app_colors.dart';

class DoseTile extends StatelessWidget {
  final DoseLog dose;
  final VoidCallback? onTake;
  final VoidCallback? onSkip;

  const DoseTile({super.key, required this.dose, this.onTake, this.onSkip});

  Color get _statusColor {
    switch (dose.status) {
      case DoseStatus.taken:
        return AppColors.success;
      case DoseStatus.missed:
        return AppColors.danger;
      case DoseStatus.skipped:
        return AppColors.warning;
      case DoseStatus.upcoming:
        return AppColors.info;
    }
  }

  String get _statusLabel {
    switch (dose.status) {
      case DoseStatus.taken:
        return 'Taken';
      case DoseStatus.missed:
        return 'Missed';
      case DoseStatus.skipped:
        return 'Skipped';
      case DoseStatus.upcoming:
        return 'Upcoming';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('h:mm a').format(dose.scheduledTime);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(color: dose.color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeStr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dose.medicineName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(
                  dose.dosage,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (dose.status == DoseStatus.upcoming && onTake != null)
            Row(
              children: [
                _iconButton(icon: Icons.close_rounded, color: AppColors.danger, onTap: onSkip),
                const SizedBox(width: 8),
                _iconButton(icon: Icons.check_rounded, color: AppColors.success, onTap: onTake),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _statusLabel,
                style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconButton({required IconData icon, required Color color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
