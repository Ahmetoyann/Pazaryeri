import 'package:flutter/material.dart';
import 'custom_bottom_sheets.dart';

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
    await CustomBottomSheets.showStatus(
      context: context,
      message: message,
      icon: icon,
      color: color,
      onDismiss: onDismiss,
      duration: duration,
    );
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
    final result = await CustomBottomSheets.showConfirmation(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: icon,
      confirmColor: confirmColor,
    );
    return result ?? false;
  }
}
