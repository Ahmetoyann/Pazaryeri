import 'package:flutter/material.dart';
import 'svg_icon.dart';
import '../../core/constants/app_icons.dart';

class CustomBottomSheets {
  /// Temel BottomSheet yapılandırması (Tüm sheetler bunu kullanacak)
  static Future<T?> _showBase<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.black,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 12,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tutma Çubuğu (Drag Handle)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }

  /// Onay Diyaloğu (Çıkış, Silme vb.)
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    IconData? icon,
    String? iconPath,
    Color? confirmColor,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final effectiveConfirmColor = confirmColor ?? theme.colorScheme.error;
    final effectiveIconColor = iconColor ?? effectiveConfirmColor;

    return _showBase<bool>(
      context: context,
      isScrollControlled: false,
      child: Builder(
        builder: (context) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: effectiveIconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: iconPath != null
                    ? SvgIcon(
                        iconPath: iconPath,
                        size: 32,
                        color: effectiveIconColor,
                      )
                    : Icon(
                        icon,
                        size: 32,
                        color: effectiveIconColor,
                      ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        cancelText,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: effectiveConfirmColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// Resim Seçici (Kamera/Galeri)
  static Future<void> showImagePicker({
    required BuildContext context,
    required VoidCallback onCameraTap,
    required VoidCallback onGalleryTap,
    VoidCallback? onRemoveTap,
    String cameraText = 'Kamera',
    String galleryText = 'Galeri',
    String removeText = 'Fotoğrafı Kaldır',
  }) {
    return _showBase(
      context: context,
      isScrollControlled: false,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(cameraText),
                onTap: () {
                  Navigator.pop(context);
                  onCameraTap();
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(galleryText),
                onTap: () {
                  Navigator.pop(context);
                  onGalleryTap();
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
              if (onRemoveTap != null)
                ListTile(
                  leading: SvgIcon(
                      iconPath: AppIcons.delete,
                      color: theme.colorScheme.error),
                  title: Text(
                    removeText,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onRemoveTap();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Genel İçerik Gösterimi (Formlar, Bilgilendirme vb. için)
  static Future<T?> showContent<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    IconData? icon,
    String? iconPath,
    Color? iconColor,
  }) {
    return _showBase<T>(
      context: context,
      child: Column(
        children: [
          if (icon != null || iconPath != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (iconColor ?? Theme.of(context).colorScheme.primary)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: iconPath != null
                  ? SvgIcon(
                      iconPath: iconPath,
                      size: 32,
                      color: iconColor ?? Theme.of(context).colorScheme.primary,
                    )
                  : Icon(
                      icon,
                      size: 32,
                      color: iconColor ?? Theme.of(context).colorScheme.primary,
                    ),
            ),
            const SizedBox(height: 16),
          ],
          if (title != null) ...[
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
          child,
        ],
      ),
    );
  }

  /// Kaydırılabilir Liste (DraggableScrollableSheet)
  static Future<T?> showDraggable<T>({
    required BuildContext context,
    required Widget Function(BuildContext, ScrollController) builder,
    double initialChildSize = 0.5,
    double minChildSize = 0.25,
    double maxChildSize = 0.9,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(child: builder(context, scrollController)),
            ],
          ),
        ),
      ),
    );
  }

  /// Durum Bildirimi (Başarılı/Hata vb. - Otomatik kapanan)
  static Future<void> showStatus({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color color,
    VoidCallback? onDismiss,
    Duration duration = const Duration(seconds: 2),
  }) async {
    // Belirtilen süre sonunda kapat
    Future.delayed(duration, () {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });

    await _showBase(
      context: context,
      isScrollControlled: false,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: color),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    onDismiss?.call();
  }
}
