import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user.dart';
import '../widgets/glass_card.dart';
import '../widgets/device_status_card.dart';
import '../widgets/sos_button.dart';

class HomeScreen extends StatefulWidget {
  final User? user;

  const HomeScreen({super.key, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.indigo100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.waving_hand,
                        color: AppTheme.indigo600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${widget.user?.name.split(' ').first ?? 'User'}!',
                            style: AppTheme.headingMedium,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Your safety network is active and monitoring',
                            style: AppTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.emerald50.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.emerald100.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: AppTheme.statusIndicatorDecoration(
                                AppTheme.emerald500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Protection Status: Active',
                              style: TextStyle(
                                color: AppTheme.emerald700,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // SOS Section
          GlassCard(
            child: Column(
              children: [
                const Text(
                  'Emergency SOS',
                  style: AppTheme.headingMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Press and hold for 3 seconds to activate emergency protocol',
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Center(
                  child: SOSButton(
                    onPressed: () {
                      _showSOSConfirmation();
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.blue50.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.blue600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Emergency contacts and authorities will be notified immediately',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.blue600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Device Status Section
          const Text(
            'Connected Devices',
            style: AppTheme.headingMedium,
          ),
          const SizedBox(height: 16),
          const DeviceStatusCard(
            deviceName: 'EVE Wearable',
            deviceType: 'Smart Watch',
            isConnected: true,
            batteryLevel: 85,
            lastSync: '2 min ago',
          ),
          const SizedBox(height: 12),
          const DeviceStatusCard(
            deviceName: 'Home Camera',
            deviceType: 'Security Camera',
            isConnected: true,
            lastSync: 'Live',
          ),
          const SizedBox(height: 12),
          const DeviceStatusCard(
            deviceName: 'Mobile Sensor',
            deviceType: 'Phone',
            isConnected: true,
            batteryLevel: 67,
            lastSync: 'Now',
          ),

          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: AppTheme.headingMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.visibility,
                  title: 'Live Monitor',
                  subtitle: 'View cameras',
                  color: AppTheme.indigo600,
                  backgroundColor: AppTheme.indigo50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.analytics,
                  title: 'AI Analysis',
                  subtitle: 'Behavior insights',
                  color: AppTheme.blue600,
                  backgroundColor: AppTheme.blue50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.report,
                  title: 'Report Incident',
                  subtitle: 'File a report',
                  color: AppTheme.yellow600,
                  backgroundColor: AppTheme.orange50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.map,
                  title: 'Safe Zones',
                  subtitle: 'Manage areas',
                  color: AppTheme.emerald600,
                  backgroundColor: AppTheme.emerald50,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Activity
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Activity',
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: 16),
                _buildActivityItem(
                  icon: Icons.check_circle,
                  title: 'System Check Completed',
                  subtitle: '2 minutes ago',
                  color: AppTheme.emerald500,
                ),
                const SizedBox(height: 12),
                _buildActivityItem(
                  icon: Icons.sync,
                  title: 'Device Sync Successful',
                  subtitle: '5 minutes ago',
                  color: AppTheme.blue600,
                ),
                const SizedBox(height: 12),
                _buildActivityItem(
                  icon: Icons.location_on,
                  title: 'Entered Safe Zone',
                  subtitle: '15 minutes ago',
                  color: AppTheme.emerald500,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: () {
        // Handle quick action tap
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title feature coming soon')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassMorphismDecoration(
          opacity: 0.9,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.slate900,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.slate900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSOSConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.warning,
              color: AppTheme.red500,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Emergency SOS',
              style: AppTheme.headingMedium,
            ),
          ],
        ),
        content: const Text(
          'This will immediately alert your emergency contacts and local authorities. Are you in immediate danger?',
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
              _activateEmergency();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Activate SOS'),
          ),
        ],
      ),
    );
  }

  void _activateEmergency() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Emergency SOS Activated! Authorities have been notified.',
        ),
        backgroundColor: AppTheme.red500,
        duration: Duration(seconds: 3),
      ),
    );
  }
}