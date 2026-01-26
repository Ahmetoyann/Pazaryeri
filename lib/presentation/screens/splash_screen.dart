import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/language_viewmodel.dart';

class SplashScreen extends StatefulWidget {
  /// İnternet kontrolü başarılı olduğunda yönlendirilecek ana widget (Örn: AuthWrapper)
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Ekran çizildikten sonra kontrolü başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInternetAndProceed();
    });
  }

  Future<void> _checkInternetAndProceed() async {
    // Logo'nun görünmesi için minimum bekleme süresi (2 saniye)
    final minSplashDuration = Future.delayed(const Duration(seconds: 2));

    bool hasConnection = false;
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        hasConnection = true;
      }
    } on SocketException catch (_) {
      hasConnection = false;
    } catch (_) {
      hasConnection = false;
    }

    await minSplashDuration;

    if (!mounted) return;

    if (hasConnection) {
      // Bağlantı varsa sonraki ekrana geç (Replacement ile geri dönüşü engelle)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => widget.nextScreen),
      );
    } else {
      _showNoConnectionDialog();
    }
  }

  void _showNoConnectionDialog() {
    final langVM = context.read<LanguageViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcı dışarı tıklayarak kapatamasın
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.red),
            const SizedBox(width: 8),
            Text(langVM.translate('error_prefix')),
          ],
        ),
        content: Text(langVM.translate('no_internet')),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Diyaloğu kapat
              _checkInternetAndProceed(); // Tekrar dene
            },
            child: Text(langVM.translate('retry')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Uygulama Logosu
            Container(
              height: 150,
              width: 150,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/copilot_ikon.png'),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
