import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user.dart';
import '../widgets/glass_card.dart';
import '../widgets/device_status_card.dart';
import '../widgets/heart_rate_card.dart';
import '../screens/gps_map_screen.dart';

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

          // GPS Location Map Section
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live GPS Location',
                  style: AppTheme.headingMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'View your real-time location on map',
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GPSMapScreen(),
                      ),
                    );
                  },
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF34C759),
                          Color(0xFF00A86B),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // Map background pattern
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 64,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Open Full Map',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap to view your location',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tap indicator
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  'Device Status',
                  style: AppTheme.headingMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Device Status Section - The Guard Wearable
          const DeviceStatusCard(
            deviceName: 'The Guard Wearable',
            deviceType: 'Smart Watch',
            isConnected: true,
            batteryLevel: 85,
            lastSync: '2 min ago',
          ),

          const SizedBox(height: 12),

          // Heart Rate Pulse Sensor
          const HeartRateCard(),

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
                  onTap: () {
                    Navigator.pushNamed(context, 'camera');
                  },
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Safe Zones - Locations coming soon')),
                    );
                  },
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
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title feature')),
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
}