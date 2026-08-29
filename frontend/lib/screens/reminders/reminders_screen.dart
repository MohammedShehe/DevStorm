import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/dose_log_model.dart';
import '../../providers/reminder_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/dose_tile.dart';
import '../../widgets/section_header.dart';
import 'notification_settings_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  
  // FIXED: Store day logs as state
  List<DoseLog> _dayLogs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDayLogs(_selectedDay);
  }

  // FIXED: Load logs for the selected day
  Future<void> _loadDayLogs(DateTime day) async {
    setState(() => _isLoading = true);
    final reminders = context.read<ReminderProvider>();
    final logs = await reminders.logsForDay(day);
    setState(() {
      _dayLogs = logs;
      _isLoading = false;
    });
  }

  // FIXED: Handle day selection
  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
    });
    _loadDayLogs(selected);
  }

  @override
  Widget build(BuildContext context) {
    final reminders = context.watch<ReminderProvider>();
    final missedCount = reminders.allLogs.where((d) => d.status == DoseStatus.missed).length;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Reminders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  IconButton(
                    onPressed: () => pushFadeSlide(context, const NotificationSettingsScreen()),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Icon(Icons.tune_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (missedCount > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You missed $missedCount dose${missedCount > 1 ? 's' : ''} this week. Review your schedule.',
                          style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                startingDayOfWeek: StartingDayOfWeek.monday,
                onFormatChanged: (format) => setState(() => _calendarFormat = format),
                onDaySelected: _onDaySelected, // FIXED: Use the new method
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  formatButtonTextStyle: TextStyle(color: Colors.white, fontSize: 12),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                  weekendTextStyle: const TextStyle(color: AppColors.textSecondaryLight),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: SectionHeader(
                title: isSameDay(_selectedDay, DateTime.now())
                    ? "Today's Doses"
                    : '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year} Doses',
              ),
            ),
          ),
          // FIXED: Use _dayLogs instead of dayLogs Future
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (_dayLogs.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: Text('No doses scheduled for this day.'),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final dose = _dayLogs[index];
                    return DoseTile(
                      dose: dose,
                      onTake: dose.status == DoseStatus.upcoming
                          ? () async {
                              await context.read<ReminderProvider>().markTaken(dose.id);
                              if (mounted) await _loadDayLogs(_selectedDay);
                            }
                          : null,
                      onSkip: dose.status == DoseStatus.upcoming
                          ? () async {
                              await context.read<ReminderProvider>().markSkipped(dose.id);
                              if (mounted) await _loadDayLogs(_selectedDay);
                            }
                          : null,
                    );
                  },
                  childCount: _dayLogs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}