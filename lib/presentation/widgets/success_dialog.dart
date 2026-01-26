import 'package:flutter/material.dart';

/// Genel amaçlı durum diyaloğu gösterir.
/// İkon, renk ve mesaj parametreleri ile özelleştirilebilir.
/// 2 saniye sonra otomatik kapanır ve [onDismiss] fonksiyonunu çalıştırır.
Future<void> showStatusDialog(
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
Future<void> showSuccessDialog(
  BuildContext context, {
  required String message,
  VoidCallback? onDismiss,
}) async {
  await showStatusDialog(
    context,
    message: message,
    icon: Icons.check_circle,
    color: Colors.green,
    onDismiss: onDismiss,
  );
}

/// Hata durumunda kırmızı çarpı ikonu ile hata diyaloğu gösterir.
Future<void> showErrorDialog(
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
Future<void> showFarewellDialog(
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
