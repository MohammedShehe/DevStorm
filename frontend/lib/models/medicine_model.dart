import 'package:flutter/material.dart';

enum MedicineForm { tablet, capsule, syrup, injection, drops, inhaler, other }

extension MedicineFormX on MedicineForm {
  String get label {
    switch (this) {
      case MedicineForm.tablet:
        return 'Tablet';
      case MedicineForm.capsule:
        return 'Capsule';
      case MedicineForm.syrup:
        return 'Syrup';
      case MedicineForm.injection:
        return 'Injection';
      case MedicineForm.drops:
        return 'Drops';
      case MedicineForm.inhaler:
        return 'Inhaler';
      case MedicineForm.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case MedicineForm.tablet:
        return Icons.medication_outlined;
      case MedicineForm.capsule:
        return Icons.medication_liquid_outlined;
      case MedicineForm.syrup:
        return Icons.local_drink_outlined;
      case MedicineForm.injection:
        return Icons.vaccines_outlined;
      case MedicineForm.drops:
        return Icons.water_drop_outlined;
      case MedicineForm.inhaler:
        return Icons.air_outlined;
      case MedicineForm.other:
        return Icons.healing_outlined;
    }
  }
}

class Medicine {
  final String id;
  String name;
  String dosage; // e.g. "500 mg"
  MedicineForm form;
  String frequency; // e.g. "Twice a day"
  List<TimeOfDay> times;
  DateTime startDate;
  DateTime? endDate;
  String instructions; // e.g. "After food"
  Color color;
  int stockCount;
  int lowStockThreshold;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.form,
    required this.frequency,
    required this.times,
    required this.startDate,
    this.endDate,
    this.instructions = '',
    required this.color,
    this.stockCount = 30,
    this.lowStockThreshold = 5,
  });

  bool get isLowStock => stockCount <= lowStockThreshold;
}
