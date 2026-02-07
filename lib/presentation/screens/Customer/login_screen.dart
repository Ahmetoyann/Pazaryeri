import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/success_dialog.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _isGuestLoading = false;

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    try {
      final success = await authVM.loginWithGoogle();
      if (success && mounted) {
        widget.onLoginSuccess();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context,
            message: '${langVM.translate('google_login_error')}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginAsGuest() async {
    setState(() {
      _isGuestLoading = true;
    });

    // Animasyonun görünmesi için kısa bir gecikme
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Provider.of<AuthViewModel>(context, listen: false).enterAsGuest();
      widget.onLoginSuccess();
      Navigator.of(context).pop();
      // Genellikle sayfa değişeceği için false yapmaya gerek kalmayabilir ama güvenli taraf:
      if (mounted) setState(() => _isGuestLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  height: MediaQuery.of(context).size.width * 0.35,
                  width: MediaQuery.of(context).size.width * 0.35,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Image.asset('assets/images/copilot_ikon.png'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                langVM.translate('welcome_title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed:
                    (_isLoading || _isGuestLoading) ? () {} : _loginWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 27, 94, 32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: Colors.white.withOpacity(0.4)),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Image.asset(
                        'assets/images/google_logo.svg.png',
                        height: 24,
                      ),
                label: Text(
                  langVM.translate('google_login'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                child: ElevatedButton(
                  onPressed:
                      (_isLoading || _isGuestLoading) ? () {} : _loginAsGuest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                  ),
                  child: _isGuestLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              langVM.translate('continue_guest'),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
