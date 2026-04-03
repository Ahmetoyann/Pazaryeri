import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'svg_icon.dart';
import '../../core/constants/app_icons.dart';

class CustomBottomSheets {
  static const Color _darkSheetBackground = Color(0xFF121212);

  /// Temel BottomSheet yapılandırması (Tüm sheetler bunu kullanacak)
  static Future<T?> _showBase<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(isDark ? 0.85 : 0.6),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container( 
            decoration: BoxDecoration(
              color: (Theme.of(context).brightness == Brightness.dark
                  ? _darkSheetBackground
                  : Colors.white),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom +
                  24,
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
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
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
              _AnimatedIcon(
                type: IconAnimationType.shake,
                child: Container(
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
            _AnimatedIcon(
              type: IconAnimationType.scale,
              child: Container(
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
                        color:
                            iconColor ?? Theme.of(context).colorScheme.primary,
                      )
                    : Icon(
                        icon,
                        size: 32,
                        color:
                            iconColor ?? Theme.of(context).colorScheme.primary,
                      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(isDark ? 0.85 : 0.6),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: (Theme.of(context).brightness == Brightness.dark
                    ? _darkSheetBackground
                    : Colors.white),
              ),
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom),
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
          _AnimatedIcon(
            type: IconAnimationType.elastic,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
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

enum IconAnimationType { scale, shake, elastic, rotate }

class _AnimatedIcon extends StatefulWidget {
  final Widget child;
  final IconAnimationType type;

  const _AnimatedIcon({
    required this.child,
    this.type = IconAnimationType.scale,
  });

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    switch (widget.type) {
      case IconAnimationType.scale:
      case IconAnimationType.elastic:
        _scaleAnimation = CurvedAnimation(
          parent: _controller,
          curve: Curves.elasticOut,
        );
        _controller.forward();
        break;
      case IconAnimationType.rotate:
        _rotateAnimation = CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOutBack,
        );
        _controller.forward();
        break;
      case IconAnimationType.shake:
        _controller.forward();
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == IconAnimationType.shake) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final sineValue = sin(4 * pi * _controller.value);
          return Transform.translate(
            offset: Offset(sineValue * 8, 0),
            child: child,
          );
        },
        child: widget.child,
      );
    } else if (widget.type == IconAnimationType.rotate) {
      return RotationTransition(
        turns: _rotateAnimation,
        child: widget.child,
      );
    }

    // Scale & Elastic
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}
