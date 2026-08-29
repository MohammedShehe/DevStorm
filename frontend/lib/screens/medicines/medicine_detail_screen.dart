import 'package:flutter/material.dart';
import '../../models/medicine_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/primary_button.dart';
import 'add_medicine_screen.dart';

class MedicineDetailScreen extends StatelessWidget {
  final Medicine medicine;
  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => pushFadeSlide(context, AddMedicineScreen(existing: medicine)),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  height: 88,
                  width: 88,
                  decoration: BoxDecoration(
                    color: medicine.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(medicine.form.icon, color: medicine.color, size: 42),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(medicine.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
              Center(
                child: Text(
                  '${medicine.dosage} • ${medicine.form.label}',
                  style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
                ),
              ),
              const SizedBox(height: 28),
              _infoCard(
                context,
                children: [
                  _infoRow(Icons.repeat_rounded, 'Frequency', medicine.frequency),
                  _infoRow(Icons.access_time_rounded, 'Reminder Times',
                      medicine.times.map((t) => t.format(context)).join(', ')),
                  _infoRow(Icons.info_outline_rounded, 'Instructions',
                      medicine.instructions.isEmpty ? 'None specified' : medicine.instructions),
                  _infoRow(Icons.event_outlined, 'Start Date',
                      '${medicine.startDate.day}/${medicine.startDate.month}/${medicine.startDate.year}'),
                ],
              ),
              const SizedBox(height: 16),
              _infoCard(
                context,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Stock Remaining', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        '${medicine.stockCount} units',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: medicine.isLowStock ? AppColors.danger : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (medicine.stockCount / 30).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: AppColors.borderLight,
                      color: medicine.isLowStock ? AppColors.danger : AppColors.success,
                    ),
                  ),
                  if (medicine.isLowStock) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Running low! Consider refilling soon.',
                      style: TextStyle(color: AppColors.danger, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 30),
              PrimaryButton(
                label: 'Edit Medicine',
                icon: Icons.edit_outlined,
                onPressed: () => pushFadeSlide(context, AddMedicineScreen(existing: medicine)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
