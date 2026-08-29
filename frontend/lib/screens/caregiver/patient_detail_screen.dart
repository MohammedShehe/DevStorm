import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.getPatientDetail(widget.patientId);
      if (result['success'] == true) {
        setState(() {
          _data = Map<String, dynamic>.from(result['data'] as Map);
          _loading = false;
        });
      } else {
        setState(() {
          _error = result['message']?.toString() ?? 'Failed to load';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = Map<String, dynamic>.from(_data?['stats'] as Map? ?? {});
    final medicines = (_data?['medicines'] as List? ?? []);
    final doses = (_data?['doses'] as List? ?? []);

    return Scaffold(
      appBar: AppBar(title: Text(widget.patientName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          _statChip('Taken', stats['taken'] ?? 0, AppColors.success),
                          const SizedBox(width: 8),
                          _statChip('Missed', stats['missed'] ?? 0, AppColors.danger),
                          const SizedBox(width: 8),
                          _statChip('Upcoming', stats['upcoming'] ?? 0, AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Medicines', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      if (medicines.isEmpty)
                        const Text('No medicines.', style: TextStyle(color: AppColors.textSecondaryLight))
                      else
                        ...medicines.map((m) {
                          final med = Map<String, dynamic>.from(m as Map);
                          return Card(
                            child: ListTile(
                              title: Text(med['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text('${med['dosage'] ?? ''} · ${med['frequency'] ?? ''}'),
                            ),
                          );
                        }),
                      const SizedBox(height: 20),
                      const Text('Recent doses', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      if (doses.isEmpty)
                        const Text('No dose history.', style: TextStyle(color: AppColors.textSecondaryLight))
                      else
                        ...doses.take(40).map((d) {
                          final dose = Map<String, dynamic>.from(d as Map);
                          final status = dose['status']?.toString() ?? '';
                          DateTime? time;
                          try {
                            time = DateTime.parse(dose['scheduledTime'].toString());
                          } catch (_) {}
                          Color c = AppColors.textSecondaryLight;
                          if (status == 'taken') c = AppColors.success;
                          if (status == 'missed') c = AppColors.danger;
                          return ListTile(
                            dense: true,
                            title: Text(dose['medicineName']?.toString() ?? ''),
                            subtitle: Text(time != null ? DateFormat.yMMMd().add_jm().format(time) : ''),
                            trailing: Text(status, style: TextStyle(color: c, fontWeight: FontWeight.w700)),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _statChip(String label, dynamic value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text('$value', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}
