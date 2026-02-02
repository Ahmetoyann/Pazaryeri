import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/language_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback onVerified;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.onVerified,
  });

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isCodeSent = false;

  @override
  void initState() {
    super.initState();
    _startVerification();
  }

  void _startVerification() {
    setState(() => _isLoading = true);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    // Telefon numarası formatı +90... şeklinde olmalı
    String formattedPhone = widget.phoneNumber;
    if (!formattedPhone.startsWith('+')) {
      // Basit bir varsayım, ülke kodunu dinamik almanız daha iyi olur
      formattedPhone = '+90$formattedPhone';
    }

    authVM.startPhoneVerification(
      formattedPhone,
      onCodeSent: () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isCodeSent = true;
          });
        }
      },
      onAutoVerify: () {
        if (mounted) {
          widget.onVerified();
        }
      },
      onError: (message) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
    );
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length < 6) return;

    setState(() => _isLoading = true);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    final success = await authVM.verifySMSCode(_codeController.text.trim());

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        widget.onVerified();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(langVM.translate('verification_failed'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(langVM.translate('phone_verification_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.phoneNumber}\n${langVM.translate('enter_sms_code')}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(langVM.translate('verify_button')),
            ),
            if (_isCodeSent && !_isLoading)
              TextButton(
                onPressed: _startVerification,
                child: Text(langVM.translate('resend_code')),
              ),
          ],
        ),
      ),
    );
  }
}
