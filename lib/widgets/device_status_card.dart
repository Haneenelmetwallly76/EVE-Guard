import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'status_badge.dart';

class DeviceStatusCard extends StatelessWidget {
  final String deviceName;
  final String deviceType;
  final bool isConnected;
  final int? batteryLevel;
  final String lastSync;

  const DeviceStatusCard({
    super.key,
    required this.deviceName,
    required this.deviceType,
    required this.isConnected,
    this.batteryLevel,
    required this.lastSync,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Device Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isConnected
                  ? AppTheme.emerald50.withOpacity(0.7)
                  : AppTheme.slate50.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getDeviceIcon(),
              color: isConnected ? AppTheme.emerald600 : AppTheme.slate500,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Device Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      deviceName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.slate900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      text: isConnected ? 'Connected' : 'Offline',
                      type: isConnected ? StatusType.success : StatusType.error,
                      showPulse: isConnected,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  deviceType,
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (batteryLevel != null) ...[
                      Icon(
                        Icons.battery_std,
                        size: 14,
                        color: _getBatteryColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$batteryLevel%',
                        style: TextStyle(
                          color: _getBatteryColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Icon(
                      Icons.sync,
                      size: 14,
                      color: AppTheme.slate500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      lastSync,
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Button
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.slate50.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.more_vert,
              color: AppTheme.slate500,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon() {
    switch (deviceType.toLowerCase()) {
      case 'smart watch':
        return Icons.watch;
      case 'security camera':
        return Icons.videocam;
      case 'phone':
        return Icons.phone_android;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getBatteryColor() {
    if (batteryLevel == null) return AppTheme.slate500;
    
    if (batteryLevel! > 50) {
      return AppTheme.emerald600;
    } else if (batteryLevel! > 20) {
      return AppTheme.yellow600;
    } else {
      return AppTheme.red500;
    }
  }
}