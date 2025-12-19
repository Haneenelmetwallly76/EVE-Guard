import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChildDashboard extends StatelessWidget {
  final Map<String, String> child;

  const ChildDashboard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final name = child['name'] ?? 'Child';
    return Scaffold(
      appBar: AppBar(
        title: Text('$name Dashboard'),
        backgroundColor: AppTheme.indigo600,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: AppTheme.headingLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'This is a placeholder dashboard for $name. You can add per-child monitoring, alerts, and device links here.',
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
