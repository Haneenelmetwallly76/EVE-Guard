import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Navigation extends StatelessWidget {
  final String activeScreen;
  final Function(String) onScreenChange;

  const Navigation({
    super.key,
    required this.activeScreen,
    required this.onScreenChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.slate50.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_rounded, 'Home', 'home'),
            _buildNavItem(Icons.analytics_rounded, 'Analysis', 'ai'),
            _buildNavItem(Icons.videocam_rounded, 'Camera', 'camera'),
            _buildNavItem(Icons.person_rounded, 'Profile', 'profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, String screenName) {
    final bool isActive = activeScreen == screenName;
    
    return GestureDetector(
      onTap: () => onScreenChange(screenName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.blue600 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : AppTheme.slate500,
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}