import 'package:flutter/material.dart';

class DialogService {
  /// Genel amaçlı durum diyaloğu gösterir.
  /// İkon, renk ve mesaj parametreleri ile özelleştirilebilir.
  /// 2 saniye sonra otomatik kapanır ve [onDismiss] fonksiyonunu çalıştırır.
  static Future<void> showStatusDialog(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
    VoidCallback? onDismiss,
    Duration duration = const Duration(seconds: 2),
  }) async {
    // Dialogu göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 72),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // Belirtilen süre kadar bekle
    await Future.delayed(duration);

    // Context hala geçerliyse dialogu kapat ve callback'i çalıştır
    if (context.mounted) {
      Navigator.of(context).pop(); // Dialogu kapat
      onDismiss?.call();
    }
  }

  /// Başarılı işlem sonrası yeşil tikli onay diyaloğu gösterir.
  static Future<void> showSuccess(
    BuildContext context, {
    required String message,
    VoidCallback? onDismiss,
    Duration duration = const Duration(seconds: 2),
  }) async {
    await showStatusDialog(
      context,
      message: message,
      icon: Icons.check_circle,
      color: Colors.green,
      onDismiss: onDismiss,
      duration: duration,
    );
  }

  /// Hata durumunda kırmızı çarpı ikonu ile hata diyaloğu gösterir.
  static Future<void> showError(
    BuildContext context, {
    required String message,
    VoidCallback? onDismiss,
  }) async {
    await showStatusDialog(
      context,
      message: message,
      icon: Icons.cancel,
      color: Colors.red,
      onDismiss: onDismiss,
    );
  }

  /// Hesap silme sonrası veda diyaloğu gösterir.
  static Future<void> showFarewell(
    BuildContext context, {
    String message = 'Hesabınız silindi. Sizi özleyeceğiz...',
    VoidCallback? onDismiss,
  }) async {
    await showStatusDialog(
      context,
      message: message,
      icon: Icons.sentiment_dissatisfied,
      color: Colors.blueGrey,
      onDismiss: onDismiss,
      duration: const Duration(seconds: 3),
    );
  }

  /// Kullanıcıdan onay almak için kullanılan modern diyalog.
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Evet',
    String cancelText = 'Hayır',
    Color confirmColor = Colors.red,
    IconData icon = Icons.warning_amber_rounded,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: confirmColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: confirmColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
