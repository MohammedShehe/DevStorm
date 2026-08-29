import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/page_transitions.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../main_navigation.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0; // 0 = role, 1 = details
  String _role = 'patient';
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  DateTime? _dob;
  String _gender = 'Male';
  bool _agree = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Privacy Policy')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      password: _passwordCtrl.text,
      confirmPassword: _confirmCtrl.text,
      dateOfBirth: _dob,
      gender: _gender,
      role: _role,
    );
    if (ok && mounted) {
      try {
        await Future.wait([
          context.read<MedicineProvider>().loadMedicines(),
          context.read<ReminderProvider>().loadAllData(),
          context.read<ThemeProvider>().loadPreferences(),
        ]);
      } catch (_) {}
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          FadeSlidePageRoute(page: const MainNavigation()),
          (_) => false,
        );
      }
    } else if (mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_step == 0 ? 'Welcome' : 'Create account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else {
              Navigator.of(context).pushReplacement(
                FadeSlidePageRoute(page: const LoginScreen()),
              );
            }
          },
        ),
      ),
      body: SafeArea(
        child: _step == 0 ? _buildRoleStep() : _buildDetailsStep(auth),
      ),
    );
  }

  Widget _buildRoleStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Who are you?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose how you will use MediTrack. You can link patients and caregivers later.',
            style: TextStyle(color: AppColors.textSecondaryLight, height: 1.4),
          ),
          const SizedBox(height: 28),
          _roleCard(
            title: 'I am a Patient',
            subtitle: 'Track my medicines, doses, and reminders',
            icon: Icons.person_rounded,
            selected: _role == 'patient',
            onTap: () => setState(() => _role = 'patient'),
          ),
          const SizedBox(height: 14),
          _roleCard(
            title: 'I am a Caregiver',
            subtitle: 'Monitor linked patients and their routines',
            icon: Icons.health_and_safety_rounded,
            selected: _role == 'caregiver',
            onTap: () => setState(() => _role = 'caregiver'),
          ),
          const Spacer(),
          PrimaryButton(
            label: 'Continue',
            onPressed: () => setState(() => _step = 1),
          ),
        ],
      ),
    );
  }

  Widget _roleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
          color: selected ? AppColors.primary.withOpacity(0.08) : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppColors.primary : AppColors.borderLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsStep(AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _role == 'caregiver' ? 'Caregiver details' : 'Patient details',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _nameCtrl,
              label: 'Full name',
              validator: (v) => Validators.required(v, field: 'Name'),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _emailCtrl,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _phoneCtrl,
              label: 'Phone',
              keyboardType: TextInputType.phone,
              validator: (v) => Validators.required(v, field: 'Phone'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDob,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of birth',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _dob == null
                      ? 'Select date'
                      : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _gender = v ?? _gender),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _passwordCtrl,
              label: 'Password',
              obscureText: true,
              validator: Validators.password,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _confirmCtrl,
              label: 'Confirm password',
              obscureText: true,
              validator: (v) {
                if (v != _passwordCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _agree,
              onChanged: (v) => setState(() => _agree = v ?? false),
              title: const Text('I agree to the Terms & Privacy Policy', style: TextStyle(fontSize: 13)),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: auth.isLoading ? 'Creating…' : 'Create account',
              isLoading: auth.isLoading,
              onPressed: auth.isLoading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
