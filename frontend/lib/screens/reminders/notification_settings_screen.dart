import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/reminder_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final reminders = context.read<ReminderProvider>();
    // Snapshot current UI values from prefs (mutated by switches)
    final snapshot = reminders.prefs.copyWith(
      soundEnabled: reminders.prefs.soundEnabled,
      vibrationEnabled: reminders.prefs.vibrationEnabled,
      snoozeMinutes: reminders.prefs.snoozeMinutes,
      missedDoseAlerts: reminders.prefs.missedDoseAlerts,
      soundName: reminders.prefs.soundName,
    );
    bool ok = false;
    try {
      ok = await reminders.updateNotificationSettings(snapshot);
    } catch (e) {
      ok = false;
      reminders.clearError();
    }
    try {
      await NotificationService.instance.init();
      await NotificationService.instance.syncDoseReminders(reminders.allLogs);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Notification preferences saved' : (reminders.error ?? 'Preferences updated')),
        backgroundColor: ok ? null : Colors.orange.shade800,
      ),
    );
  }

  Future<void> _testNotification() async {
    await NotificationService.instance.init();
    await NotificationService.instance.showInstant(
      title: 'MediTrack test alert',
      body: 'Notifications are working. You will get alerts at scheduled dose times.',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test notification sent — check your notification tray')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reminders = context.watch<ReminderProvider>();
    final prefs = reminders.prefs;

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionCard(
            context,
            title: 'Alert Preferences',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.volume_up_outlined, color: AppColors.primary),
                title: const Text('Sound', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(prefs.soundName),
                value: prefs.soundEnabled,
                onChanged: (v) => setState(() => prefs.soundEnabled = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.vibration_rounded, color: AppColors.primary),
                title: const Text('Vibration', style: TextStyle(fontWeight: FontWeight.w600)),
                value: prefs.vibrationEnabled,
                onChanged: (v) => setState(() => prefs.vibrationEnabled = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.report_gmailerrorred_rounded, color: AppColors.primary),
                title: const Text('Missed Dose Alerts', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Get notified if you miss a scheduled dose'),
                value: prefs.missedDoseAlerts,
                onChanged: (v) => setState(() => prefs.missedDoseAlerts = v),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionCard(
            context,
            title: 'Snooze Duration',
            children: [
              Text('${prefs.snoozeMinutes} minutes', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Slider(
                value: prefs.snoozeMinutes.toDouble(),
                min: 5,
                max: 30,
                divisions: 5,
                activeColor: AppColors.primary,
                label: '${prefs.snoozeMinutes} min',
                onChanged: (v) => setState(() => prefs.snoozeMinutes = v.round()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionCard(
            context,
            title: 'Notification Sound',
            children: ['Chime', 'Bell', 'Soft Beep', 'Gentle Alarm'].map((s) {
              return RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: s,
                groupValue: prefs.soundName,
                activeColor: AppColors.primary,
                title: Text(s),
                onChanged: (v) => setState(() => prefs.soundName = v ?? prefs.soundName),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: _saving ? 'Saving…' : 'Save Preferences',
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Send Test Notification',
            icon: Icons.notifications_active_outlined,
            outlined: true,
            onPressed: _testNotification,
          ),
          const SizedBox(height: 12),
          const Text(
            'Phone notifications are scheduled for upcoming doses when you open the app or refresh schedules. Allow notifications when prompted by the system.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
