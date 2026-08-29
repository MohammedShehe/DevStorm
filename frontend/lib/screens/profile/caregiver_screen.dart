import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class CaregiverScreen extends StatefulWidget {
  const CaregiverScreen({super.key});

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen> {
  final ApiService _api = ApiService();
  List<Map<String, String>> _caregivers = [];
  bool _loading = true;
  String? _error;

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
      final result = await _api.getCaregivers();
      if (result['success'] == true) {
        final list = (result['data']['caregivers'] as List?) ?? [];
        _caregivers = list.map((c) {
          final m = c as Map<String, dynamic>;
          return {
            'id': m['id']?.toString() ?? '',
            'name': m['caregiverName']?.toString() ?? m['name']?.toString() ?? '',
            'relation': 'Caregiver',
            'status': m['status']?.toString() ?? 'Pending',
            'email': m['email']?.toString() ?? '',
          };
        }).toList();
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showInviteSheet() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Invite a Caregiver', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Caregiver Name',
                    controller: nameController,
                    prefixIcon: Icons.person_outline_rounded,
                    validator: Validators.fullName,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Email Address',
                    controller: emailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: sending ? 'Sending…' : 'Send Invitation',
                    onPressed: sending
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheet(() => sending = true);
                            try {
                              await _api.inviteCaregiver(
                                caregiverName: nameController.text.trim(),
                                email: emailController.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _load();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invitation sent successfully')),
                                );
                              }
                            } catch (e) {
                              setSheet(() => sending = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caregiver Linking')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                    ),
                  if (_caregivers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No caregivers yet.\nInvite someone who helps manage your medicines.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondaryLight),
                        ),
                      ),
                    ),
                  ..._caregivers.map((c) {
                    final accepted = (c['status'] ?? '').toLowerCase() == 'accepted';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          child: Text(
                            (c['name'] ?? '?').isNotEmpty ? c['name']![0].toUpperCase() : '?',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${c['email'] ?? ''}\n${c['status'] ?? ''}'),
                        isThreeLine: true,
                        trailing: Icon(
                          accepted ? Icons.check_circle : Icons.hourglass_top_rounded,
                          color: accepted ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Invite New Caregiver',
                    icon: Icons.person_add_alt_1_rounded,
                    onPressed: _showInviteSheet,
                  ),
                ],
              ),
            ),
    );
  }
}
