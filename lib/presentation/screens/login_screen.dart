import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';
import 'auth_viewmodel.dart';
import '../viewmodels/language_viewmodel.dart';
import '../viewmodels/status_message_widget.dart';

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
  bool _rememberMe = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    try {
      await authVM.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        rememberMe: _rememberMe,
      );

      if (mounted) {
        widget.onLoginSuccess();
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      String message = langVM.translate('login_error');
      if (e.code == 'user-not-found') {
        message = langVM.translate('user_not_found');
      } else if (e.code == 'wrong-password') {
        message = langVM.translate('login_error');
      } else if (e.code == 'too-many-requests') {
        message =
            'Çok fazla deneme yaptınız. Lütfen daha sonra tekrar deneyin.';
      } else if (e.code == 'network-request-failed') {
        message = 'İnternet bağlantınızı kontrol edin.';
      } else {
        message = e.message ?? langVM.translate('login_error');
      }
      if (mounted) setState(() => _errorMessage = message);
    } on FirebaseException catch (e) {
      // Firestore veya diğer Firebase hataları (Örn: permission-denied)
      debugPrint('Firebase Hatası: Kod: ${e.code} - Mesaj: ${e.message}');
      String message = 'Sunucu hatası: ${e.message}';
      if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        message = 'İnternet bağlantısı yok veya sunucuya erişilemiyor.';
      } else if (e.code == 'permission-denied') {
        message = 'Erişim reddedildi. Lütfen yetkilerinizi kontrol edin.';
      }
      if (mounted) setState(() => _errorMessage = message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Bir hata oluştu: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    try {
      final success = await authVM.loginWithGoogle();
      if (success && mounted) {
        // Eğer yeni kullanıcı ise hoş geldin mesajı göster
        if (authVM.isNewUser) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(langVM.translate('welcome_dialog_title')),
              content: Text(langVM.translate('welcome_dialog_message')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(langVM.translate('start')),
                ),
              ],
            ),
          );
        }
        widget.onLoginSuccess();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted)
        setState(() =>
            _errorMessage = '${langVM.translate('google_login_error')}: $e');
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
                if (_errorMessage != null)
                  StatusMessageWidget(
                    message: _errorMessage!,
                    type: StatusType.error,
                    onClose: () => setState(() => _errorMessage = null),
                  ),
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
                // Beni Hatırla ve Şifremi Unuttum Satırı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
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
                      onPressed: _showForgotPasswordDialog,
                      child: Text(
                        langVM.translate('forgot_password'),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ],
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        langVM.translate('or'),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(48),
                    ),
                  ),
                  icon: const Icon(Icons.g_mobiledata,
                      size: 32, color: Colors.red),
                  label: Text(
                    langVM.translate('google_login'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
  bool _isLoading = false;
  String? _errorText;
  bool _isLinkSent = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _emailController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isLinkSent = true;
      _countdown = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    return AlertDialog(
      title: Text(langVM.translate('forgot_password_title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
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
          if (_isLinkSent) ...[
            const SizedBox(height: 16),
            Text(
              _countdown > 0
                  ? '${langVM.translate('check_email_timer')} ($_countdown)'
                  : langVM.translate('resend_available'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _countdown > 0 ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(langVM.translate('no')),
        ),
        ElevatedButton(
          onPressed: (_isLoading || (_isLinkSent && _countdown > 0))
              ? null
              : () async {
                  setState(() {
                    _isLoading = true;
                    _errorText = null;
                  });

                  try {
                    // E-posta gönder
                    final success = await authVM.sendVerificationCode(
                      _emailController.text.trim(),
                    );
                    if (success) {
                      if (mounted) {
                        _startTimer();
                      }
                    } else {
                      setState(
                        () => _errorText = langVM.translate('user_not_found'),
                      );
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
              : Text(_isLinkSent && _countdown == 0
                  ? langVM.translate('retry')
                  : langVM.translate('send_code')),
        ),
      ],
    );
  }
}
