import 'dart:ui';
import 'package:flutter/material.dart';

class LoadingOverlay {
  /// İşlemi gerçekleştirirken yükleme animasyonunu gösterir.
  /// [asyncFunction]: Yapılacak asenkron işlem (Giriş, Çıkış, Kayıt vb.)
  /// [minDuration]: Animasyonun ekranda kalacağı minimum süre (Varsayılan 2 saniye)
  static Future<void> show(
    BuildContext context, {
    required Future<void> Function() asyncFunction,
    Duration minDuration = const Duration(seconds: 2),
  }) async {
    // NavigatorState'i işlemden önce alıyoruz çünkü işlem sırasında context unmounted olabilir
    final navigator = Navigator.of(context, rootNavigator: true);

    // Yükleme diyaloğunu göster
    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcı dışarı tıklayıp kapatamasın
      barrierColor: Colors.black.withOpacity(0.3), // Hafif karartma
      builder: (_) => const _LoadingDialog(),
    );

    try {
      // Hem işlemi yap hem de minimum süreyi bekle
      await Future.wait([
        asyncFunction(),
        Future.delayed(minDuration),
      ]);
    } finally {
      // İşlem bitince (veya hata olsa bile) diyaloğu kapat
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: const Center(
        child: CustomLoadingIndicator(),
      ),
    );
  }
}

class CustomLoadingIndicator extends StatefulWidget {
  final double size;
  const CustomLoadingIndicator({super.key, this.size = 100});

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); // Büyüyüp küçülme döngüsü

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        // İkonunuzu buraya ekliyoruz
        child: Image.asset('assets/images/copilot_ikon.png'),
      ),
    );
  }
}
