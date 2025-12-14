import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'register_screen.dart';
import 'auth_viewmodel.dart';
import '../viewmodels/language_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    try {
      final success = await authVM.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success) {
        widget.onLoginSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-posta veya şifre hatalı.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bir hata oluştu: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Şifremi unuttum akışını başlatan metod
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // İşlem bitmeden kapanmasın
      builder: (BuildContext context) {
        return _ForgotPasswordDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);

    return Scaffold(
      body: Center(
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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('assets/images/copilot_ikon.png'),
                    ),
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
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: langVM.translate('email_label'),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value?.isEmpty ?? true)
                      ? langVM.translate('email_error')
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: langVM.translate('password_label'),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) => (value?.isEmpty ?? true)
                      ? langVM.translate('password_error')
                      : null,
                ),
                // Şifremi Unuttum Butonu
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text(
                      langVM.translate('forgot_password'),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(48),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          langVM.translate('login'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const RegisterScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.ease;
                              final tween = Tween(
                                begin: begin,
                                end: end,
                              ).chain(CurveTween(curve: curve));
                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                      ),
                    );
                  },
                  child: Text(
                    langVM.translate('no_account'),
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(height: 40),
                OutlinedButton(
                  onPressed: () {
                    Provider.of<AuthViewModel>(
                      context,
                      listen: false,
                    ).enterAsGuest();
                    widget.onLoginSuccess();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(48),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        langVM.translate('continue_guest'),
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Şifre Sıfırlama Diyaloğu (StatefulWidget olarak ayrıldı çünkü kendi içinde durum yönetiyor)
class _ForgotPasswordDialog extends StatefulWidget {
  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _pageController = PageController();

  int _step = 0; // 0: Email, 1: Code, 2: New Password
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    return AlertDialog(
      title: Text(langVM.translate('forgot_password_title')),
      content: SizedBox(
        width: double.maxFinite,
        height: 200,
        child: PageView(
          controller: _pageController,
          physics:
              const NeverScrollableScrollPhysics(), // Elle kaydırmayı engelle
          children: [
            // ADIM 1: E-posta Girişi
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(langVM.translate('enter_email_message')),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: langVM.translate('email_label'),
                    errorText: _errorText,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            // ADIM 2: Kod Doğrulama
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(langVM.translate('enter_code_message')),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Kod (123456)',
                    errorText: _errorText,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            // ADIM 3: Yeni Şifre
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(langVM.translate('new_password_label')),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(
                    labelText: '******',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (_step < 2)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(langVM.translate('no')), // İptal / Hayır
          ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() {
                    _isLoading = true;
                    _errorText = null;
                  });

                  try {
                    if (_step == 0) {
                      // E-posta gönder
                      final success = await authVM.sendVerificationCode(
                        _emailController.text.trim(),
                      );
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(langVM.translate('code_sent')),
                          ),
                        );
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                        setState(() => _step = 1);
                      } else {
                        setState(
                          () => _errorText = langVM.translate('user_not_found'),
                        );
                      }
                    } else if (_step == 1) {
                      // Kodu doğrula
                      final isValid = authVM.verifyCode(
                        _codeController.text.trim(),
                      );
                      if (isValid) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                        setState(() => _step = 2);
                      } else {
                        setState(
                          () => _errorText = langVM.translate('invalid_code'),
                        );
                      }
                    } else if (_step == 2) {
                      // Şifreyi sıfırla
                      await authVM.resetPassword(
                        _emailController.text.trim(),
                        _newPasswordController.text,
                      );
                      if (mounted) {
                        Navigator.of(context).pop(); // Diyaloğu kapat
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              langVM.translate('password_reset_success'),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    setState(() => _errorText = e.toString());
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _step == 0
                      ? langVM.translate('send_code')
                      : _step == 1
                      ? langVM.translate('verify_code')
                      : langVM.translate('reset_password_button'),
                ),
        ),
      ],
    );
  }
}
