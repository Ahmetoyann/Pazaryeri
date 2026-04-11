import 'package:flutter/material.dart';

class CustomSnackbars {
  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String actionLabel = 'Geri Al',
  }) {
    // Varsa mevcut snackbar'ı gizle
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: duration,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        elevation: 6,
        action: onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Başarılı işlem bildirimi (Yeşil)
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      color: Colors.green,
    );
  }

  /// Hata bildirimi (Kırmızı)
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline,
      color: Theme.of(context).colorScheme.error,
    );
  }

  /// Bilgilendirme bildirimi (Mavi)
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline,
      color: Colors.blue,
    );
  }

  /// Uyarı bildirimi (Turuncu)
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      color: Colors.orange,
    );
  }

  /// Geri alma işlemi içeren bildirim (Koyu Gri)
  static void showUndo(
    BuildContext context,
    String message,
    VoidCallback onUndo, {
    String undoLabel = 'Geri Al',
  }) {
    _show(
      context,
      message: message,
      icon: Icons.undo,
      color: const Color(0xFF323232),
      duration: const Duration(seconds: 4),
      onAction: onUndo,
      actionLabel: undoLabel,
    );
  }
}
