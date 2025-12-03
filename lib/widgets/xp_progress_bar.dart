import 'package:flutter/material.dart';
import 'package:mentora_app/theme.dart';

class XPProgressBar extends StatelessWidget {
  final int currentXP;
  final int requiredXP;
  final int level;

  const XPProgressBar({
    super.key,
    required this.currentXP,
    required this.requiredXP,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentXP / requiredXP;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level $level',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.gradientPurple,
              ),
            ),
            Text(
              '$currentXP / $requiredXP XP',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 12,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.xpGold),
          ),
        ),
      ],
    );
  }
}
