import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _members = [];
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
      final result = await _api.getFamilyMembers();
      if (result['success'] == true) {
        final list = (result['data']['members'] as List?) ??
            (result['data']['members'] as List?) ??
            [];
        _members = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showAddSheet() {
    final emailController = TextEditingController();
    final relationController = TextEditingController();
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
                  const Text('Add Family Member', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Email',
                    controller: emailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Relation (e.g. Son, Mother)',
                    controller: relationController,
                    prefixIcon: Icons.people_outline,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: sending ? 'Adding…' : 'Add Member',
                    onPressed: sending
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheet(() => sending = true);
                            try {
                              await _api.addFamilyMember(
                                email: emailController.text.trim(),
                                relation: relationController.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _load();
                            } catch (e) {
                              setSheet(() => sending = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
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

  Future<void> _delete(String id) async {
    try {
      await _api.deleteFamilyMember(id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Members')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: AppColors.danger)),
                  if (_members.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No family members linked yet.',
                          style: TextStyle(color: AppColors.textSecondaryLight),
                        ),
                      ),
                    ),
                  ..._members.map((m) {
                    final id = m['id']?.toString() ?? '';
                    final email = m['email']?.toString() ?? m['fullName']?.toString() ?? m['familyMember']?['email']?.toString() ?? 'Member';
                    final relation = m['relation']?.toString() ?? '';
                    final status = m['status']?.toString() ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        title: Text(email, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('$relation • $status'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                          onPressed: id.isEmpty ? null : () => _delete(id),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Add Family Member',
                    icon: Icons.person_add_alt_1_rounded,
                    onPressed: _showAddSheet,
                  ),
                ],
              ),
            ),
    );
  }
}
