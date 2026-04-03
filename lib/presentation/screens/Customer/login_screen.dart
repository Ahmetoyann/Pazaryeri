import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/presentation/widgets/svg_icon.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/success_dialog.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_snackbars.dart';
import '../../../core/constants/app_icons.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _loginWithGoogle() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    await LoadingOverlay.show(
      context,
      asyncFunction: () async {
        try {
          final success = await authVM.loginWithGoogle();
          if (success && mounted) {
            CustomSnackbars.showSuccess(
                context, langVM.translate('login_success'));
            widget.onLoginSuccess();
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (mounted) {
            // Hata mesajını overlay kapandıktan sonra göster
            Future.delayed(const Duration(milliseconds: 100), () {
              CustomSnackbars.showError(
                  context, '${langVM.translate('google_login_error')}: $e');
            });
          }
        }
      },
    );
  }

  Future<void> _loginAsGuest() async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    await LoadingOverlay.show(
      context,
      asyncFunction: () async {
        Provider.of<AuthViewModel>(context, listen: false).enterAsGuest();
        if (mounted) {
          CustomSnackbars.showSuccess(
              context, langVM.translate('guest_login_success'));
          widget.onLoginSuccess();
          Navigator.of(context).pop();
        }
      },
    );
  }

  Widget _buildLoginButton(BuildContext context,
      {required String title,
      required Widget icon,
      required Color color,
      required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.27)),
                    ),
                    child: SvgIcon(
                      iconPath: AppIcons.user,
                      size: MediaQuery.of(context).size.width * 0.24,
                      color: Theme.of(context).colorScheme.primary,
                    )),
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
              _buildLoginButton(
                context,
                title: langVM.translate('google_login'),
                icon: Image.asset(
                  'assets/images/google_logo.svg.png',
                  height: 24,
                ),
                color: const Color.fromARGB(255, 27, 94, 32),
                onTap: _loginWithGoogle,
              ),
              const SizedBox(height: 24),
              _buildLoginButton(
                context,
                title: langVM.translate('continue_guest'),
                icon: const Icon(Icons.arrow_forward,
                    color: Colors.white, size: 24),
                color: Theme.of(context).colorScheme.primary,
                onTap: _loginAsGuest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
