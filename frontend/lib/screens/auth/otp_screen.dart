import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/page_transitions.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import 'login_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _secondsLeft = 60;
  bool _verified = false;

  final _resetFormKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _otpValue => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    final auth = context.read<AuthProvider>();
    if (_otpValue.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter all 6 digits')));
      return;
    }
    final success = await auth.verifyOtp(_otpValue);
    if (success) {
      setState(() => _verified = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Invalid or expired OTP. Please request a new OTP.')),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Password reset failed')),
      );
      return;
    }
    if (success && mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppColors.success),
              SizedBox(width: 10),
              Text('Success'),
            ],
          ),
          content: const Text('Your password has been reset successfully. Please log in with your new password.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  FadeSlidePageRoute(page: const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: _verified ? _buildResetPasswordForm(auth) : _buildOtpForm(auth),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpForm(AuthProvider auth) {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.12), shape: BoxShape.circle),
          child: const Icon(Icons.sms_outlined, color: AppColors.secondary, size: 34),
        ),
        const SizedBox(height: 24),
        Text('Verify OTP', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'We sent a 6-digit code to ',
            style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
            children: [
              TextSpan(text: widget.email, style: const TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) => _otpBox(index)),
        ),
        const SizedBox(height: 24),
        Center(
          child: _secondsLeft > 0
              ? Text('Resend code in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13))
              : TextButton(
                  onPressed: () async {
                    final ok = await auth.resendOtp();
                    if (ok) {
                      _startTimer();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('OTP resent')),
                        );
                      }
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(auth.error ?? 'Failed to resend OTP')),
                      );
                    }
                  },
                  child: const Text('Resend OTP'),
                ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Verify', onPressed: _verify, isLoading: auth.isLoading),
      ],
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 46,
      height: 54,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildResetPasswordForm(AuthProvider auth) {
    return Form(
      key: _resetFormKey,
      child: Column(
        key: const ValueKey('reset'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), shape: BoxShape.circle),
            child: const Icon(Icons.password_rounded, color: AppColors.success, size: 34),
          ),
          const SizedBox(height: 24),
          Text('Set New Password', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Your new password must be different from previously used passwords.',
            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
          ),
          const SizedBox(height: 28),
          CustomTextField(
            label: 'New Password',
            controller: _newPasswordController,
            hint: 'Min. 8 characters',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            validator: Validators.password,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Confirm New Password',
            controller: _confirmPasswordController,
            hint: 'Re-enter new password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            validator: (v) => Validators.confirmPassword(v, _newPasswordController.text),
          ),
          const SizedBox(height: 28),
          PrimaryButton(label: 'Reset Password', onPressed: _resetPassword, isLoading: auth.isLoading),
        ],
      ),
    );
  }
}
