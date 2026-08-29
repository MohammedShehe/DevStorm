import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/page_transitions.dart';
import 'edit_profile_screen.dart';
import 'caregiver_screen.dart';
import 'accessibility_screen.dart';
import '../legal/legal_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.currentUser;

    return SafeArea(
      child: Builder(
        builder: (context) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu_rounded),
                    ),
                    const Text('Profile & Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        child: Text(
                          user?.initials ?? '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.fullName ?? '',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                            const SizedBox(height: 4),
                            Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => pushFadeSlide(context, const EditProfileScreen()),
                        icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text('Account', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSecondaryLight, fontSize: 13)),
              ),
            ),
            SliverToBoxAdapter(
              child: _menuGroup(context, [
                _MenuItemData(
                  icon: Icons.person_outline_rounded,
                  label: 'Edit Profile',
                  onTap: () => pushFadeSlide(context, const EditProfileScreen()),
                ),
                _MenuItemData(
                  icon: Icons.link_rounded,
                  label: 'Caregiver Linking',
                  onTap: () => pushFadeSlide(context, const CaregiverScreen()),
                ),
              ]),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text('Preferences', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSecondaryLight, fontSize: 13)),
              ),
            ),
            SliverToBoxAdapter(
              child: _menuGroup(context, [
                _MenuItemData(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark Mode',
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    activeColor: AppColors.primary,
                    onChanged: (v) => context.read<ThemeProvider>().toggleDarkMode(v),
                  ),
                ),
                _MenuItemData(
                  icon: Icons.accessibility_new_rounded,
                  label: 'Accessibility Options',
                  onTap: () => pushFadeSlide(context, const AccessibilityScreen()),
                ),
                _MenuItemData(
                  icon: Icons.language_rounded,
                  label: 'Language',
                  trailingText: 'English',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Additional languages coming soon.')),
                    );
                  },
                ),
              ]),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text('Support', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSecondaryLight, fontSize: 13)),
              ),
            ),
            SliverToBoxAdapter(
              child: _menuGroup(context, [
                _MenuItemData(icon: Icons.help_outline_rounded, label: 'Help & FAQs', onTap: () => pushFadeSlide(context, const LegalScreen(type: LegalDocType.faqs))),
                _MenuItemData(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () => pushFadeSlide(context, const LegalScreen(type: LegalDocType.privacy))),
                _MenuItemData(
                  icon: Icons.logout_rounded,
                  label: 'Log Out',
                  color: AppColors.danger,
                  onTap: () => _showLogoutDialog(context),
                ),
              ]),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 130)),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out? You\'ll need to log in again to access your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                FadeSlidePageRoute(page: const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Log Out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Widget _menuGroup(BuildContext context, List<_MenuItemData> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: List.generate(items.length, (index) {
            final item = items[index];
            return Column(
              children: [
                ListTile(
                  leading: Icon(item.icon, color: item.color ?? AppColors.primary),
                  title: Text(item.label, style: TextStyle(fontWeight: FontWeight.w600, color: item.color)),
                  trailing: item.trailing ??
                      (item.trailingText != null
                          ? Text(item.trailingText!, style: const TextStyle(color: AppColors.textSecondaryLight))
                          : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight)),
                  onTap: item.onTap,
                ),
                if (index != items.length - 1) const Divider(height: 1, indent: 20, endIndent: 20),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? trailingText;
  final Color? color;

  _MenuItemData({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.trailingText,
    this.color,
  });
}