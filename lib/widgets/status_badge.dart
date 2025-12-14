import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final StatusType type;
  final IconData? icon;
  final bool showPulse;

  const StatusBadge({
    super.key,
    required this.text,
    required this.type,
    this.icon,
    this.showPulse = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    switch (type) {
      case StatusType.success:
        backgroundColor = AppTheme.emerald50;
        textColor = AppTheme.emerald700;
        borderColor = AppTheme.emerald100;
        break;
      case StatusType.warning:
        backgroundColor = AppTheme.orange50;
        textColor = AppTheme.yellow600;
        borderColor = const Color(0xFFfed7aa);
        break;
      case StatusType.error:
        backgroundColor = const Color(0xFFfef2f2);
        textColor = AppTheme.red600;
        borderColor = const Color(0xFFfecaca);
        break;
      case StatusType.info:
        backgroundColor = AppTheme.blue50;
        textColor = AppTheme.blue600;
        borderColor = AppTheme.blue100;
        break;
      case StatusType.neutral:
        backgroundColor = AppTheme.slate50;
        textColor = AppTheme.slate600;
        borderColor = AppTheme.slate200;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.7),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: textColor,
            ),
            const SizedBox(width: 4),
          ],
          if (showPulse) ...[
            Container(
              width: 6,
              height: 6,
              decoration: AppTheme.statusIndicatorDecoration(textColor),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusType {
  success,
  warning,
  error,
  info,
  neutral,
}