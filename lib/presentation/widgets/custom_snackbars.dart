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
    // Varsa mevcut veya birikmiş snackbar'ları gizle
    ScaffoldMessenger.of(context).clearSnackBars();

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
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
            ),
            if (onAction != null)
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    onAction();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: duration,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        elevation: 8,
        action:
            null, // Butonu content içine alarak otomatik kapanmama sorununu bypass ettik!
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
      icon: Icons.restore_rounded,
      color:
          const Color(0xFF2C2C2E), // Apple tarzı daha modern ve soft koyu gri
      duration: const Duration(seconds: 5), // Kesin olarak 5 saniye
      onAction: onUndo,
      actionLabel: undoLabel,
    );
  }
}
