import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../utils/validators.dart';

class CaregiverScreen extends StatefulWidget {
  const CaregiverScreen({super.key});

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen> {
  final _api = ApiService();
  final _emailCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _caregivers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.getCaregivers();
      if (result['success'] == true) {
        final list = (result['data']['caregivers'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _caregivers = list;
          _loading = false;
        });
      } else {
        setState(() {
          _error = result['message']?.toString();
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

  Future<void> _link() async {
    final email = _emailCtrl.text.trim();
    final err = Validators.email(email);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await _api.inviteCaregiver(email: email);
      if (result['success'] == true) {
        _emailCtrl.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Caregiver linked successfully')),
          );
        }
        await _load();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']?.toString() ?? 'Failed to link')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    if (mounted) setState(() => _saving = false);
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
                  const Text(
                    'Add a caregiver by their registered caregiver account email. They will see your medicine routine on their dashboard.',
                    style: TextStyle(color: AppColors.textSecondaryLight, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _emailCtrl,
                    label: 'Caregiver email',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: _saving ? 'Linking…' : 'Link Caregiver',
                    isLoading: _saving,
                    onPressed: _saving ? null : _link,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                    ),
                  const SizedBox(height: 24),
                  const Text('Linked caregivers', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (_caregivers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No caregivers linked yet.', style: TextStyle(color: AppColors.textSecondaryLight)),
                    )
                  else
                    ..._caregivers.map((c) {
                      final accepted = (c['status'] ?? '').toString().toLowerCase() == 'accepted';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.15),
                            child: const Icon(Icons.person, color: AppColors.primary),
                          ),
                          title: Text(c['caregiverName']?.toString() ?? c['name']?.toString() ?? 'Caregiver',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${c['email'] ?? ''}\n${c['status'] ?? ''}'),
                          isThreeLine: true,
                          trailing: Icon(
                            accepted ? Icons.check_circle : Icons.hourglass_top_rounded,
                            color: accepted ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
