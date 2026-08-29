import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/dose_log_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/dose_tile.dart';
import '../../widgets/section_header.dart';
import '../../widgets/streak_card.dart';
import '../reminders/notification_settings_screen.dart';
import '../../utils/page_transitions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final r = context.read<ReminderProvider>();
      r.loadTodayDoses();
      r.loadUpcomingDoses();
      r.loadStatusSummary();
      r.loadAdherenceData();
      context.read<MedicineProvider>().loadMedicines();
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final reminders = context.watch<ReminderProvider>();
    final medicines = context.watch<MedicineProvider>();
    final todayLogs = reminders.todayLogs;
    final upcoming = reminders.upcomingLogs;
    final takenCount = todayLogs.where((d) => d.status == DoseStatus.taken).length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          final r = context.read<ReminderProvider>();
          await Future.wait([
            r.loadTodayDoses(),
            r.loadUpcomingDoses(),
            r.loadStatusSummary(),
            r.loadAdherenceData(),
            context.read<MedicineProvider>().loadMedicines(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(), style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        auth.currentUser?.fullName.split(' ').first ?? 'there',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () => pushFadeSlide(context, const NotificationSettingsScreen()),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: const Icon(Icons.notifications_outlined),
                        ),
                      ),
                      if (medicines.lowStockMedicines.isNotEmpty)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            height: 9,
                            width: 9,
                            decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: StreakAndAdherenceCard(
                streakDays: reminders.currentStreak,
                adherence: reminders.todayAdherence,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _statTile(
                      context,
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                      label: 'Taken Today',
                      value: '$takenCount/${todayLogs.length}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statTile(
                      context,
                      icon: Icons.medication_outlined,
                      color: AppColors.secondary,
                      label: 'Active Meds',
                      value: '${medicines.medicines.length}',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: SectionHeader(title: "Today's Schedule (${DateFormat('MMM d').format(DateTime.now())})"),
            ),
          ),
          if (todayLogs.isEmpty)
            SliverToBoxAdapter(child: _emptyState('No doses scheduled for today.'))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final dose = todayLogs[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + index * 60),
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(offset: Offset(0, (1 - value) * 10), child: child),
                      ),
                      child: DoseTile(
                        dose: dose,
                        onTake: dose.status == DoseStatus.upcoming
                            ? () => context.read<ReminderProvider>().markTaken(dose.id)
                            : null,
                        onSkip: dose.status == DoseStatus.upcoming
                            ? () => context.read<ReminderProvider>().markSkipped(dose.id)
                            : null,
                      ),
                    );
                  },
                  childCount: todayLogs.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: SectionHeader(title: 'Upcoming Reminders'),
            ),
          ),
          if (upcoming.isEmpty)
            SliverToBoxAdapter(child: _emptyState('All caught up! No upcoming doses.'))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final dose = upcoming[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: dose.color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule_rounded, color: dose.color, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('${dose.medicineName} • ${dose.dosage}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                          ),
                          Text(
                            DateFormat('h:mm a').format(dose.scheduledTime),
                            style: TextStyle(color: dose.color, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: upcoming.length,
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _statTile(BuildContext context,
      {required IconData icon, required Color color, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: Text(message, style: const TextStyle(color: AppColors.textSecondaryLight)),
      ),
    );
  }
}