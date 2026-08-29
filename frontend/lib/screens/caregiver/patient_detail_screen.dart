import 'package:fl_chart/fl_chart.dart';
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
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await _api.getPatientDetail(widget.patientId);
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = Map<String, dynamic>.from(_data?['stats'] as Map? ?? {});
    final medicines = (_data?['medicines'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) {
        final ad = _parseDate(a['startDate'] ?? a['createdAt']);
        final bd = _parseDate(b['startDate'] ?? b['createdAt']);
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
    final rawDoses = (_data?['doses'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    rawDoses.sort((a, b) {
      final ad = _parseDate(a['scheduledTime']);
      final bd = _parseDate(b['scheduledTime']);
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });

    final doses = rawDoses.take(100).toList();
    final taken = _asInt(stats['taken']);
    final missed = _asInt(stats['missed']);
    final skipped = _asInt(stats['skipped']);
    final upcoming = _asInt(stats['upcoming']);
    final completed = taken + missed + skipped;
    final adherence = completed == 0 ? 0.0 : taken / completed;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientName),
        actions: [
          IconButton(onPressed: _load, tooltip: 'Refresh', icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: AppColors.danger))))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _buildHeaderCard(context, adherence, completed),
                      const SizedBox(height: 16),
                      _buildStatGrid(taken, missed, skipped, upcoming),
                      const SizedBox(height: 18),
                      _sectionTitle('Adherence overview', 'Completed doses by status'),
                      const SizedBox(height: 10),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _buildAdherenceChart(context, taken, missed, skipped)),
                      const SizedBox(height: 18),
                      _sectionTitle('7-day activity', 'Dose outcomes by day'),
                      const SizedBox(height: 10),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _buildWeeklyChart(doses)),
                      const SizedBox(height: 18),
                      _sectionTitle('Current medicines', '${medicines.length} active record${medicines.length == 1 ? '' : 's'}'),
                      const SizedBox(height: 10),
                      if (medicines.isEmpty)
                        _emptyCard('No medicines have been added yet.')
                      else
                        ...medicines.map((m) => _medicineCard(Map<String, dynamic>.from(m as Map))),
                      const SizedBox(height: 18),
                      _sectionTitle('Dose history', '${doses.length} most recent entries · newest first'),
                      const SizedBox(height: 10),
                      if (doses.isEmpty)
                        _emptyCard('No dose history is available.')
                      else
                        _buildDoseHistory(doses),
                    ],
                  ),
                ),
    );
  }

  int _asInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

  Widget _buildHeaderCard(BuildContext context, double adherence, int completed) {
    final patient = Map<String, dynamic>.from(_data?['patient'] as Map? ?? {});
    final email = patient['email']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.20), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: Colors.white.withOpacity(0.20),
            child: Text(
              widget.patientName.isEmpty ? '?' : widget.patientName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 23),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.patientName, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              Text('$completed completed doses', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: adherence, strokeWidth: 7, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(Colors.white)),
                Text('${(adherence * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(int taken, int missed, int skipped, int upcoming) {
    return Row(
      children: [
        _statCard('Taken', taken, AppColors.success, Icons.check_circle_rounded),
        const SizedBox(width: 8),
        _statCard('Missed', missed, AppColors.danger, Icons.cancel_rounded),
        const SizedBox(width: 8),
        _statCard('Skipped', skipped, AppColors.secondary, Icons.remove_circle_rounded),
        const SizedBox(width: 8),
        _statCard('Upcoming', upcoming, AppColors.primary, Icons.schedule_rounded),
      ],
    );
  }

  Widget _statCard(String label, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 5),
        decoration: BoxDecoration(color: color.withOpacity(0.09), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.12))),
        child: Column(children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(height: 5),
          Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
        ])),
      ],
    );
  }

  Widget _card(Widget child, {EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: child,
    );
  }

  Widget _buildAdherenceChart(BuildContext context, int taken, int missed, int skipped) {
    final total = taken + missed + skipped;
    if (total == 0) return _emptyCard('Not enough completed doses to calculate adherence yet.');
    final sections = <PieChartSectionData>[];
    void add(int value, Color color, String label) {
      if (value == 0) return;
      sections.add(PieChartSectionData(value: value.toDouble(), color: color, radius: 62, title: '$value', titleStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800), badgeWidget: null));
    }
    add(taken, AppColors.success, 'Taken');
    add(missed, AppColors.danger, 'Missed');
    add(skipped, AppColors.secondary, 'Skipped');
    return _card(
      Row(
        children: [
          SizedBox(height: 150, width: 150, child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 34, sectionsSpace: 3, borderData: FlBorderData(show: false)))),
          const SizedBox(width: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _legend('Taken', taken, AppColors.success),
            const SizedBox(height: 10),
            _legend('Missed', missed, AppColors.danger),
            const SizedBox(height: 10),
            _legend('Skipped', skipped, AppColors.secondary),
            const SizedBox(height: 12),
            Text('${(taken / total * 100).round()}% successful', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ])),
        ],
      ),
    );
  }

  Widget _legend(String label, int value, Color color) {
    return Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5))), Text('$value', style: TextStyle(fontWeight: FontWeight.w800, color: color))]);
  }

  Widget _buildWeeklyChart(List<Map<String, dynamic>> doses) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
    final values = days.map((day) {
      final dayDoses = doses.where((d) {
        final date = _parseDate(d['scheduledTime']);
        return date != null && date.year == day.year && date.month == day.month && date.day == day.day;
      }).toList();
      return [
        dayDoses.where((d) => d['status']?.toString() == 'taken').length,
        dayDoses.where((d) => d['status']?.toString() == 'missed').length,
        dayDoses.where((d) => d['status']?.toString() == 'skipped').length,
      ];
    }).toList();
    final maxY = values.fold<double>(1, (max, v) => [v[0], v[1], v[2]].fold<double>(max, (m, x) => x > m ? x.toDouble() : m));
    return _card(
      SizedBox(
        height: 230,
        child: BarChart(
          BarChartData(
            maxY: maxY + 1,
            minY: 0,
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= days.length) return const SizedBox.shrink();
                return Padding(padding: const EdgeInsets.only(top: 8), child: Text(DateFormat('E').format(days[index]).substring(0, 2), style: const TextStyle(fontSize: 10)));
              })),
            ),
            barGroups: List.generate(values.length, (i) {
              final v = values[i];
              return BarChartGroupData(x: i, barsSpace: 2, barRods: [
                BarChartRodData(toY: v[0].toDouble(), width: 7, color: AppColors.success, borderRadius: BorderRadius.circular(4)),
                BarChartRodData(toY: v[1].toDouble(), width: 7, color: AppColors.danger, borderRadius: BorderRadius.circular(4)),
                BarChartRodData(toY: v[2].toDouble(), width: 7, color: AppColors.secondary, borderRadius: BorderRadius.circular(4)),
              ]);
            }),
          ),
        ),
      ),
    );
  }

  Widget _medicineCard(Map<String, dynamic> med) {
    final startDate = _parseDate(med['startDate'] ?? med['createdAt']);
    final endDate = _parseDate(med['endDate']);
    final dateText = startDate == null
        ? 'Start date not available'
        : 'Started ${DateFormat('MMM d, yyyy').format(startDate)}${endDate != null ? ' · Ends ${DateFormat('MMM d, yyyy').format(endDate)}' : ''}';
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.borderLight)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.10), shape: BoxShape.circle), child: const Icon(Icons.medication_rounded, color: AppColors.primary)),
        title: Text(med['name']?.toString() ?? 'Medicine', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text('${med['dosage'] ?? 'Dosage not set'} · ${med['frequency'] ?? 'Schedule not set'}\n$dateText')),
      ),
    );
  }

  Widget _buildDoseHistory(List<Map<String, dynamic>> doses) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final dose in doses) {
      final date = _parseDate(dose['scheduledTime']);
      final key = date == null ? 'Unknown date' : DateFormat('yyyy-MM-dd').format(date);
      groups.putIfAbsent(key, () => []).add(dose);
    }
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return Column(
      children: keys.map((key) {
        final dayDoses = groups[key]!;
        dayDoses.sort((a, b) => (_parseDate(b['scheduledTime']) ?? DateTime(1900)).compareTo(_parseDate(a['scheduledTime']) ?? DateTime(1900)));
        DateTime? headerDate;
        try { headerDate = DateTime.parse(key); } catch (_) {}
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.borderLight)),
          child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.06), borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
              child: Row(children: [const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.primary), const SizedBox(width: 8), Text(headerDate == null ? key : DateFormat('EEEE, MMM d, yyyy').format(headerDate), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))]),
            ),
            ...dayDoses.map(_doseTile),
          ]),
        );
      }).toList(),
    );
  }

  Widget _doseTile(Map<String, dynamic> dose) {
    final status = dose['status']?.toString().toLowerCase() ?? 'upcoming';
    final time = _parseDate(dose['scheduledTime']);
    final Color color = status == 'taken' ? AppColors.success : status == 'missed' ? AppColors.danger : status == 'skipped' ? AppColors.secondary : AppColors.primary;
    final icon = status == 'taken' ? Icons.check_circle_rounded : status == 'missed' ? Icons.cancel_rounded : status == 'skipped' ? Icons.remove_circle_rounded : Icons.schedule_rounded;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      leading: Icon(icon, color: color, size: 22),
      title: Text(dose['medicineName']?.toString() ?? 'Medicine', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      subtitle: Text('${dose['dosage'] ?? ''}${time != null ? ' · ${DateFormat.jm().format(time)}' : ''}'),
      trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10)), child: Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11))),
    );
  }

  Widget _emptyCard(String text) => _card(Row(children: [const Icon(Icons.info_outline_rounded, color: AppColors.textSecondaryLight, size: 20), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondaryLight)))]));
}
