import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../screens/auth/login_screen.dart';
import '../screens/legal/legal_screen.dart';
import '../utils/page_transitions.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _openLegal(BuildContext context, LegalDocType type) {
    Navigator.of(context).pop(); // close drawer
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalScreen(type: type)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    child: Text(
                      user?.initials ?? '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Guest User',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _drawerTile(context, icon: Icons.help_outline_rounded, label: 'FAQs', onTap: () => _openLegal(context, LegalDocType.faqs)),
            _drawerTile(context, icon: Icons.info_outline_rounded, label: 'About the App', onTap: () => _openLegal(context, LegalDocType.about)),
            _drawerTile(context, icon: Icons.support_agent_rounded, label: 'Contact Support', onTap: () => _openLegal(context, LegalDocType.support)),
            _drawerTile(context, icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () => _openLegal(context, LegalDocType.privacy)),
            _drawerTile(context, icon: Icons.description_outlined, label: 'Terms of Service', onTap: () => _openLegal(context, LegalDocType.terms)),
            _drawerTile(
              context,
              icon: Icons.star_outline_rounded,
              label: 'Rate this App',
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thanks for your support! Rating will open when the app is published.')),
                );
              },
            ),
            const Spacer(),
            Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            _drawerTile(
              context,
              icon: Icons.logout_rounded,
              label: 'Log Out',
              color: AppColors.danger,
              onTap: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    FadeSlidePageRoute(page: const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondaryLight),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
      onTap: onTap,
    );
  }
}
