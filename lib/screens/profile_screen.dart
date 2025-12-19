import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user.dart';
import '../widgets/glass_card.dart';
import 'child_dashboard.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onLogout;
  final User? user;

  const ProfileScreen({
    super.key,
    required this.onLogout,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          GlassCard(
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppTheme.blue100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: AppTheme.blue600,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'User',
                        style: AppTheme.headingMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'user@example.com',
                        style: AppTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.emerald50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Protected',
                          style: TextStyle(
                            color: AppTheme.emerald600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.slate50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: AppTheme.slate500,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Children section
          if (user?.children != null && user!.children!.isNotEmpty) ...[
            const Text(
              'Children',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 12),
            Column(
              children: user!.children!.map((child) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.child_care_outlined, color: AppTheme.slate600),
                  title: Text(child['name'] ?? 'Child'),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.slate500),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChildDashboard(child: child),
                    ));
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
          ],

          // Settings Section
          const Text(
            'Settings',
            style: AppTheme.headingMedium,
          ),
          const SizedBox(height: 16),

          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingsItem(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  subtitle: 'Update your profile details',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Personal Information screen')),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.security,
                  title: 'Privacy & Security',
                  subtitle: 'Manage your security preferences',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy & Security screen')),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Configure alert preferences',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications screen')),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.devices,
                  title: 'Connected Devices',
                  subtitle: 'Manage your The Guard devices',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Connected Devices screen')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showLogoutDialog(context);
              },
              icon: const Icon(
                Icons.logout,
                color: AppTheme.red500,
              ),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  color: AppTheme.red500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.red500, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // App Version
          Center(
            child: Text(
              'The Guard v1.0.0',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.slate500,
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.slate50.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.slate600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.slate900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.slate600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.slate500,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Sign Out',
          style: AppTheme.headingMedium,
        ),
        content: const Text(
          'Are you sure you want to sign out? You will need to sign in again to access your The Guard protection.',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.slate600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}