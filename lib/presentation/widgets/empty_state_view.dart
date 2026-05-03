import 'package:flutter/material.dart';
import 'svg_icon.dart';

class EmptyStateView extends StatelessWidget {
  final String? iconPath;
  final IconData? iconData;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final IconData? actionIcon;

  const EmptyStateView({
    super.key,
    this.iconPath,
    this.iconData,
    required this.title,
    this.message,
    this.actionLabel,
    this.onActionPressed,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconPath != null || iconData != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: iconPath != null
                  ? SvgIcon(
                      iconPath: iconPath!,
                      size: 64,
                      color: theme.colorScheme.primary,
                    )
                  : Icon(
                      iconData,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
            ),
          if (iconPath != null || iconData != null) const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: onActionPressed,
              icon: Icon(actionIcon ?? Icons.refresh_rounded),
              label: Text(actionLabel!),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
