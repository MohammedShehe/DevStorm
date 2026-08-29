import 'package:flutter/material.dart';
import '../models/medicine_model.dart';
import '../services/api_service.dart';

class MedicineProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Medicine> _medicines = [];
  bool _isLoading = false;
  String? _error;

  List<Medicine> get medicines => List.unmodifiable(_medicines);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Medicine> get lowStockMedicines =>
      _medicines.where((m) => m.isLowStock).toList();

  Future<void> loadMedicines({String? search}) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _apiService.getMedicines(search: search);
      if (result['success'] == true) {
        final data = result['data']['medicines'] as List;
        _medicines = data.map((json) => _medicineFromJson(json)).toList();
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> addMedicine(Medicine medicine) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _apiService.addMedicine(_medicineToJson(medicine));
      if (result['success'] == true) {
        final data = result['data']['medicine'];
        _medicines.add(_medicineFromJson(data));
        _setLoading(false);
        return true;
      } else {
        _error = result['message'];
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateMedicine(Medicine medicine) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _apiService.updateMedicine(
        id: medicine.id,
        data: _medicineToJson(medicine),
      );
      if (result['success'] == true) {
        final index = _medicines.indexWhere((m) => m.id == medicine.id);
        if (index != -1) {
          final data = result['data']['medicine'];
          _medicines[index] = _medicineFromJson(data);
        }
        _setLoading(false);
        return true;
      } else {
        _error = result['message'];
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteMedicine(String id) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _apiService.deleteMedicine(id);
      if (result['success'] == true) {
        _medicines.removeWhere((m) => m.id == id);
        _setLoading(false);
        return true;
      } else {
        _error = result['message'];
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// AI-style name suggestions while typing.
  Future<List<Map<String, dynamic>>> suggestMedicines(String query) async {
    try {
      final result = await _apiService.suggestMedicines(query);
      if (result['success'] == true) {
        final list = (result['data']['suggestions'] as List?) ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      _error = e.toString();
    }
    return [];
  }

  /// Uses / side effects / when to take for a selected name.
  Future<Map<String, dynamic>?> getMedicineInfo(String name) async {
    try {
      final result = await _apiService.getMedicineInfo(name);
      if (result['success'] == true) {
        return Map<String, dynamic>.from(result['data']['info'] as Map);
      }
      _error = result['message']?.toString();
    } catch (e) {
      _error = e.toString();
    }
    return null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

Map<String, dynamic> _medicineToJson(Medicine medicine) {
  return {
    'name': medicine.name,
    'dosage': medicine.dosage,
    'form': medicine.form.name,
    'frequency': medicine.frequency,
    'times': medicine.times.map((t) => {'hour': t.hour, 'minute': t.minute}).toList(),
    'startDate': medicine.startDate.toIso8601String().split('T').first,
    'endDate': medicine.endDate?.toIso8601String().split('T').first,
    'instructions': medicine.instructions,
    'color':
        '#${medicine.color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'stockCount': medicine.stockCount,
    'lowStockThreshold': medicine.lowStockThreshold,
  };
}

Medicine _medicineFromJson(Map<String, dynamic> json) {
  return Medicine(
    id: json['id'].toString(),
    name: json['name'],
    dosage: json['dosage'],
    form: MedicineForm.values.firstWhere(
      (e) => e.name == json['form'],
      orElse: () => MedicineForm.tablet,
    ),
    frequency: json['frequency'],
    times: (json['times'] as List? ?? [])
        .map((t) => TimeOfDay(
              hour: t['hour'] ?? 9,
              minute: t['minute'] ?? 0,
            ))
        .toList(),
    startDate: DateTime.parse(json['startDate'].toString()),
    endDate:
        json['endDate'] != null ? DateTime.parse(json['endDate'].toString()) : null,
    instructions: json['instructions'] ?? '',
    color: Color(int.parse(
      (json['color']?.toString() ?? '#0EA5A0').replaceFirst('#', 'FF'),
      radix: 16,
    )),
    stockCount: json['stockCount'] ?? 30,
    lowStockThreshold: json['lowStockThreshold'] ?? 5,
  );
}
