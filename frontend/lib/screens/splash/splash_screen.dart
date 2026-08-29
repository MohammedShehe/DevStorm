import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../utils/page_transitions.dart';
import '../auth/login_screen.dart';
import '../main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeIn));
    _controller.forward();
    _boot();
  }

  Future<void> _boot() async {
    final auth = context.read<AuthProvider>();
    // Wait until session restore finishes (or max 3s)
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (auth.isRestoring && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    // Minimum splash time for branding
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToNextScreen() {
    final auth = context.read<AuthProvider>();

    if (auth.isAuthenticated) {
      _loadInitialDataAndNavigate();
    } else {
      Navigator.of(context).pushReplacement(
        FadeSlidePageRoute(page: const LoginScreen()),
      );
    }
  }

  Future<void> _loadInitialDataAndNavigate() async {
    try {
      await Future.wait([
        context.read<MedicineProvider>().loadMedicines(),
        context.read<ReminderProvider>().loadAllData(),
        context.read<ThemeProvider>().loadPreferences(),
      ]);
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        FadeSlidePageRoute(page: const MainNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fade.value,
                child: Transform.scale(scale: _scale.value, child: child),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 96, showBackground: true, borderRadius: 28),
                const SizedBox(height: 24),
                const Text(
                  'MediTrack',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your Medicine, On Time, Every Time',
                  style: TextStyle(color: Colors.white70, fontSize: 13.5),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
