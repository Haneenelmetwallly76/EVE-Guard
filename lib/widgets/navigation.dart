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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: AppTheme.slate200.withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                screen: 'home',
                icon: Icons.home,
                label: 'Home',
              ),
              _buildNavItem(
                screen: 'ai',
                icon: Icons.psychology,
                label: 'Test',
              ),
              _buildNavItem(
                screen: 'report',
                icon: Icons.report,
                label: 'Report',
              ),
              _buildNavItem(
                screen: 'profile',
                icon: Icons.person,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String screen,
    required IconData icon,
    required String label,
  }) {
    final bool isActive = activeScreen == screen;

    return GestureDetector(
      onTap: () => onScreenChange(screen),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? AppTheme.blue50.withOpacity(0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isActive ? AppTheme.blue600 : AppTheme.slate500,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isActive ? AppTheme.blue600 : AppTheme.slate500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}