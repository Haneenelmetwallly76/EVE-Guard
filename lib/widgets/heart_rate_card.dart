import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class HeartRateCard extends StatefulWidget {
  const HeartRateCard({super.key});

  @override
  State<HeartRateCard> createState() => _HeartRateCardState();
}

class _HeartRateCardState extends State<HeartRateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _currentHeartRate = 0;
  bool _isMonitoring = true;
  Timer? _heartbeatTimer;
  List<int> _heartRateHistory = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _startHeartRateSimulation();
  }

  void _startHeartRateSimulation() {
    // Simulate heart rate readings (typically 60-100 BPM for resting)
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _isMonitoring) {
        setState(() {
          // Simulate realistic heart rate variation
          _currentHeartRate = 65 + (DateTime.now().millisecond % 40).toInt();
          _heartRateHistory.add(_currentHeartRate);
          
          // Keep only last 10 readings for history
          if (_heartRateHistory.length > 10) {
            _heartRateHistory.removeAt(0);
          }
        });
        
        // Pulse animation
        _pulseController.forward().then((_) {
          if (mounted) _pulseController.reverse();
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  Color _getHeartRateColor() {
    if (_currentHeartRate < 60) return Colors.blue;
    if (_currentHeartRate < 80) return AppTheme.emerald500;
    if (_currentHeartRate < 100) return AppTheme.yellow600;
    return AppTheme.red600;
  }

  String _getHeartRateStatus() {
    if (_currentHeartRate < 60) return 'Low';
    if (_currentHeartRate < 80) return 'Normal';
    if (_currentHeartRate < 100) return 'Elevated';
    return 'High';
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getHeartRateColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.favorite,
                  color: _getHeartRateColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Heart Rate Pulse',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slate900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getHeartRateStatus(),
                      style: TextStyle(
                        color: _getHeartRateColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isMonitoring
                      ? AppTheme.emerald50.withOpacity(0.7)
                      : AppTheme.slate50.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isMonitoring
                        ? AppTheme.emerald100.withOpacity(0.5)
                        : AppTheme.slate200.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isMonitoring ? AppTheme.emerald500 : AppTheme.slate500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isMonitoring ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: _isMonitoring ? AppTheme.emerald600 : AppTheme.slate600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Heart Rate Display
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulse animation circles
                    ScaleTransition(
                      scale: Tween(begin: 1.0, end: 1.3).animate(
                        CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
                      ),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getHeartRateColor().withOpacity(0.1),
                          border: Border.all(
                            color: _getHeartRateColor().withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // Inner circle
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getHeartRateColor().withOpacity(0.2),
                        border: Border.all(
                          color: _getHeartRateColor().withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$_currentHeartRate',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _getHeartRateColor(),
                              ),
                            ),
                            Text(
                              'BPM',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getHeartRateColor().withOpacity(0.8),
                                fontWeight: FontWeight.w500,
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
          const SizedBox(height: 16),
          
          // Heart Rate History Graph (simplified bar chart)
          if (_heartRateHistory.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Readings',
                  style: TextStyle(
                    color: AppTheme.slate600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    _heartRateHistory.length,
                    (index) {
                      final maxRate = 120.0;
                      final height = (_heartRateHistory[index] / maxRate) * 40;
                      return Flexible(
                        child: Tooltip(
                          message: '${_heartRateHistory[index]} BPM',
                          child: Column(
                            children: [
                              Container(
                                width: 20,
                                height: height,
                                decoration: BoxDecoration(
                                  color: _getHeartRateColor().withOpacity(0.7),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          
          // Stats Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.slate50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.slate200.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Average',
                        style: TextStyle(
                          color: AppTheme.slate600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _heartRateHistory.isEmpty
                            ? '--'
                            : '${(_heartRateHistory.reduce((a, b) => a + b) ~/ _heartRateHistory.length)}',
                        style: const TextStyle(
                          color: AppTheme.slate900,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.slate50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.slate200.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Max',
                        style: TextStyle(
                          color: AppTheme.slate600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _heartRateHistory.isEmpty
                            ? '--'
                            : '${_heartRateHistory.reduce((a, b) => a > b ? a : b)}',
                        style: const TextStyle(
                          color: AppTheme.slate900,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.slate50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.slate200.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Min',
                        style: TextStyle(
                          color: AppTheme.slate600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _heartRateHistory.isEmpty
                            ? '--'
                            : '${_heartRateHistory.reduce((a, b) => a < b ? a : b)}',
                        style: const TextStyle(
                          color: AppTheme.slate900,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Toggle Monitoring Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isMonitoring = !_isMonitoring;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMonitoring ? AppTheme.red600 : AppTheme.emerald500,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isMonitoring ? 'Stop Monitoring' : 'Start Monitoring',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
