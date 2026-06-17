import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'seller_register_screen.dart';
import '../../widgets/success_dialog.dart';
import '../../widgets/custom_bottom_sheets.dart';
import '../../widgets/custom_snackbars.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_button.dart';

class SellerLoginScreen extends StatefulWidget {
  const SellerLoginScreen({super.key});

  @override
  State<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends State<SellerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    await LoadingOverlay.show(
      context,
      asyncFunction: () async {
        try {
          final success = await authVM.loginAsSeller(
            _emailController.text.trim(),
            _passwordController.text,
            rememberMe: _rememberMe,
          );
          if (success && mounted) {
            CustomSnackbars.showSuccess(
                context, langVM.translate('login_success'));
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } catch (e) {
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 100), () {
              CustomSnackbars.showError(
                  context, '${langVM.translate('error_prefix')}: $e');
            });
          }
        }
      },
    );
  }

  Future<void> _showForgotPasswordSheet() async {
    final emailController = TextEditingController(text: _emailController.text);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    await CustomBottomSheets.showContent(
      context: context,
      title: langVM.translate('forgot_password_title'),
      icon: Icons.lock_reset,
      iconColor: Theme.of(context).colorScheme.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            langVM.translate('enter_email_message'),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.7)),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: emailController,
            autofocus: true,
            decoration: _inputDecoration(
                langVM.translate('email_label'), AppIcons.email),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: langVM.translate('send_button'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Colors.white,
            onPressed: () async {
              if (emailController.text.trim().isEmpty) return;
              Navigator.pop(context);

              try {
                await Provider.of<AuthViewModel>(context, listen: false)
                    .resetPassword(emailController.text.trim());
                if (mounted) {
                  CustomSnackbars.showSuccess(
                      context, langVM.translate('code_sent'));
                }
              } catch (e) {
                if (mounted) {
                  CustomSnackbars.showError(
                      context, '${langVM.translate('error_prefix')}: $e');
                }
              }
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              langVM.translate('cancel'),
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String iconPath) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SvgIcon(
          iconPath: iconPath,
          color: theme.colorScheme.primary,
          size: 28,
        ),
      ),
      filled: true,
      fillColor: theme.cardColor,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: theme.colorScheme.primary.withOpacity(0.5))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: theme.colorScheme.primary.withOpacity(0.5))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                        height: MediaQuery.of(context).size.width * 0.35,
                        width: MediaQuery.of(context).size.width * 0.35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .shadowColor
                                  .withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              width: 1.5),
                        ),
                        child: Icon(
                          Icons.people,
                          color: Theme.of(context).colorScheme.primary,
                          size: MediaQuery.of(context).size.width * 0.24,
                        )),
                    const SizedBox(height: 16),
                    Text(
                      langVM.translate('seller_login'),
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                          langVM.translate('email_label'), AppIcons.email),
                      validator: (v) =>
                          v!.isEmpty ? langVM.translate('email_error') : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                              langVM.translate('password_label'), AppIcons.lock)
                          .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Theme.of(context).iconTheme.color ??
                                  Theme.of(context).colorScheme.onSurface,
                              size: 28),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => v!.isEmpty
                          ? langVM.translate('password_error')
                          : null,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor:
                                  Theme.of(context).colorScheme.secondary,
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? true;
                                });
                              },
                            ),
                            Text(langVM.translate('remember_me')),
                          ],
                        ),
                        TextButton(
                          onPressed: _showForgotPasswordSheet,
                          child: Text(
                            langVM.translate('forgot_password'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: langVM.translate('login'),
                      onPressed: _login,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Hesabınız yok mu? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SellerRegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Satıcı Kaydı",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Theme.of(context).colorScheme.primary, size: 24),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
