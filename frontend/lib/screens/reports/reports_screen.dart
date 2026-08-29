import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/dose_log_model.dart';
import '../../providers/reminder_provider.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/datetime_utils.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showExportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
              ),
              const Text('Export Patient Medicine History', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Includes medicine start dates, patient age, adherence and dose history.',
                  style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
              const SizedBox(height: 20),
              _exportTile(context, icon: Icons.picture_as_pdf_outlined, label: 'Export medicine history (PDF)', color: AppColors.danger),
              const SizedBox(height: 12),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exportTile(BuildContext context, {required IconData icon, required String label, required Color color}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        Navigator.pop(context);
        final api = ApiService();
        try {
          final result = await api.exportPdf();
          if (!context.mounted) return;
          if (result['success'] != true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message']?.toString() ?? 'Export failed')),
            );
            return;
          }
          final data = result['data'] as Map<String, dynamic>? ?? {};
          final summary = Map<String, dynamic>.from(data['summary'] as Map? ?? {});
          final history = (data['medicineHistory'] as List? ?? []);
          final buf = StringBuffer();
          buf.writeln('PATIENT MEDICINE HISTORY');
          buf.writeln('========================');
          buf.writeln('Patient: ${summary['patientName'] ?? ''}');
          buf.writeln('Email: ${summary['email'] ?? ''}');
          buf.writeln('DOB: ${summary['dateOfBirth'] ?? ''}');
          buf.writeln('Age: ${summary['age'] ?? ''}');
          buf.writeln('Gender: ${summary['gender'] ?? ''}');
          buf.writeln('Generated: ${summary['generatedAt'] ?? ''}');
          buf.writeln('');
          buf.writeln('Totals — taken: ${summary['taken']}, missed: ${summary['missed']}, skipped: ${summary['skipped']}');
          buf.writeln('');
          buf.writeln('MEDICINES');
          for (final m in history) {
            final med = Map<String, dynamic>.from(m as Map);
            buf.writeln('- ${med['name']} | ${med['dosage']} | start: ${med['startDate']} | adherence: ${med['adherence']}% | taken: ${med['taken']} missed: ${med['missed']}');
          }
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Medicine History PDF'),
              content: SingleChildScrollView(child: SelectableText(buf.toString())),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              ],
            ),
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: Text('Reports & History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    onPressed: () => _showExportSheet(context),
                    tooltip: 'Export patient medicine history',
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Material(
                elevation: 0,
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    padding: const EdgeInsets.all(4),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    indicator: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondaryLight,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    tabs: const [
                      Tab(text: 'Charts'),
                      Tab(text: 'Logs'),
                      Tab(text: 'Caregiver Notes'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _ChartsTab(),
                  _LogsTab(),
                  _CaregiverNotesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartsTab extends StatefulWidget {
  const _ChartsTab();

  @override
  State<_ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends State<_ChartsTab> {
  int _range = 1; // 0 = daily(week), 1 = weekly, 2 = monthly

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderProvider>().loadAdherenceData();
      context.read<ReminderProvider>().loadTodayDoses();
      context.read<ReminderProvider>().loadStatusSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reminders = context.watch<ReminderProvider>();
    final weekly = reminders.weeklyAdherence.isEmpty
        ? List<double>.filled(7, 0)
        : reminders.weeklyAdherence;
    final monthly = reminders.monthlyAdherence.isEmpty
        ? List<double>.filled(4, 0)
        : reminders.monthlyAdherence;
    final taken = reminders.takenCount;
    final missed = reminders.missedCount;
    final skipped = reminders.skippedCount;
    final totalCounts = taken + missed + skipped;
    final takenPct = totalCounts > 0 ? (taken * 100 / totalCounts) : 0.0;
    final missedPct = totalCounts > 0 ? (missed * 100 / totalCounts) : 0.0;
    final skippedPct = totalCounts > 0 ? (skipped * 100 / totalCounts) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (i) {
              final labels = ['Daily', 'Weekly', 'Monthly'];
              final selected = _range == i;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(labels[i]),
                  selected: selected,
                  onSelected: (_) => setState(() => _range = i),
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: selected ? AppColors.primary : AppColors.borderLight),
                  ),
                  backgroundColor: Colors.transparent,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Adherence Overview', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      maxY: 1.0,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final labels = _range == 2
                                  ? ['W1', 'W2', 'W3', 'W4']
                                  : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              if (value.toInt() >= labels.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(labels[value.toInt()],
                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate((_range == 2 ? monthly : weekly).length, (i) {
                        final value = (_range == 2 ? monthly : weekly)[i];
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: value,
                              width: 18,
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 90,
                  width: 90,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 26,
                      sections: totalCounts == 0
                          ? [
                              PieChartSectionData(
                                  value: 1, color: AppColors.borderLight, radius: 20, showTitle: false),
                            ]
                          : [
                              if (taken > 0)
                                PieChartSectionData(
                                    value: taken.toDouble(),
                                    color: AppColors.success,
                                    radius: 20,
                                    showTitle: false),
                              if (missed > 0)
                                PieChartSectionData(
                                    value: missed.toDouble(),
                                    color: AppColors.danger,
                                    radius: 20,
                                    showTitle: false),
                              if (skipped > 0)
                                PieChartSectionData(
                                    value: skipped.toDouble(),
                                    color: AppColors.warning,
                                    radius: 20,
                                    showTitle: false),
                            ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _legendRow(AppColors.success, 'Taken', '${takenPct.toStringAsFixed(0)}%'),
                      _legendRow(AppColors.danger, 'Missed', '${missedPct.toStringAsFixed(0)}%'),
                      _legendRow(AppColors.warning, 'Skipped', '${skippedPct.toStringAsFixed(0)}%'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(height: 10, width: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _LogsTab extends StatelessWidget {
  const _LogsTab();

  Color _statusColor(DoseStatus s) {
    switch (s) {
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

  @override
  Widget build(BuildContext context) {
    final reminders = context.watch<ReminderProvider>();
    final logs = reminders.allLogs.where((l) => l.status != DoseStatus.upcoming).toList().reversed.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(color: _statusColor(log.status).withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(
                  log.status == DoseStatus.taken
                      ? Icons.check_rounded
                      : log.status == DoseStatus.missed
                          ? Icons.close_rounded
                          : Icons.remove_rounded,
                  color: _statusColor(log.status),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.medicineName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      DateFormat('MMM d, h:mm a').format(log.scheduledTime),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              Text(
                log.status.name[0].toUpperCase() + log.status.name.substring(1),
                style: TextStyle(color: _statusColor(log.status), fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CaregiverNotesTab extends StatefulWidget {
  const _CaregiverNotesTab();

  @override
  State<_CaregiverNotesTab> createState() => _CaregiverNotesTabState();
}

class _CaregiverNotesTabState extends State<_CaregiverNotesTab> {
  final _api = ApiService();
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;
  String? _error;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.getCaregiverNotes();
      if (result['success'] == true) {
        final list = (result['data']['notes'] as List?) ?? [];
        _notes = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  String _relativeTime(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = parseServerDateTime(raw);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${(diff.inDays / 7).floor()} weeks ago';
    } catch (_) {
      return '';
    }
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    try {
      await _api.addCaregiverNote(text);
      _noteController.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Add a caregiver note…',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _addNote,
                style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                icon: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _notes.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      Center(
                        child: Text(
                          'No caregiver notes yet.\nAdd one above or invite a caregiver first.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondaryLight),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      final name = (note['caregiverName'] ?? 'Caregiver').toString();
                      final body = (note['note'] ?? '').toString();
                      final time = _relativeTime(note['createdAt']);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.secondary.withOpacity(0.15),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                  ),
                                ),
                                Text(
                                  time,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(body, style: const TextStyle(fontSize: 13.5, height: 1.4)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
