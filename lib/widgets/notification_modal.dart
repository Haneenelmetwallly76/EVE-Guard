import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationModal extends StatelessWidget {
  final VoidCallback onClose;

  const NotificationModal({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 100),
              GestureDetector(
                onTap: () {}, // Prevent closing when tapping the modal content
                child: Container(
                  width: double.infinity,
                  decoration: AppTheme.glassMorphismDecoration(
                    opacity: 0.95,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.blue100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.notifications,
                                    color: AppTheme.blue600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Notifications',
                                  style: AppTheme.headingMedium,
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: onClose,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.slate50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: AppTheme.slate500,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Notifications List
                      Container(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildNotificationItem(
                              icon: Icons.check_circle,
                              iconColor: AppTheme.emerald500,
                              iconBgColor: AppTheme.emerald50,
                              title: 'System Health Check',
                              subtitle: 'All devices are functioning normally',
                              time: '2 min ago',
                              isUnread: true,
                            ),
                            const SizedBox(height: 12),
                            _buildNotificationItem(
                              icon: Icons.location_on,
                              iconColor: AppTheme.blue600,
                              iconBgColor: AppTheme.blue50,
                              title: 'Safe Zone Alert',
                              subtitle: 'You have entered your designated safe zone',
                              time: '15 min ago',
                              isUnread: true,
                            ),
                            const SizedBox(height: 12),
                            _buildNotificationItem(
                              icon: Icons.sync,
                              iconColor: AppTheme.indigo600,
                              iconBgColor: AppTheme.indigo50,
                              title: 'Device Sync',
                              subtitle: 'EVE Wearable synchronized successfully',
                              time: '1 hour ago',
                              isUnread: false,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  // Mark all as read
                                  onClose();
                                },
                                style: AppTheme.outlineButtonStyle,
                                child: const Text('Mark All Read'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // View all notifications
                                  onClose();
                                },
                                style: AppTheme.primaryButtonStyle,
                                child: const Text('View All'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread 
            ? AppTheme.blue50.withOpacity(0.3)
            : AppTheme.slate50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? AppTheme.blue100.withOpacity(0.5)
              : AppTheme.slate200.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                          color: AppTheme.slate900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.blue600,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.slate600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.slate500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}