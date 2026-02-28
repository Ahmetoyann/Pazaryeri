import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/success_dialog.dart';
import '../../widgets/custom_bottom_sheets.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';

class SellerEditProfileScreen extends StatefulWidget {
  const SellerEditProfileScreen({super.key});

  @override
  State<SellerEditProfileScreen> createState() =>
      _SellerEditProfileScreenState();
}

class _SellerEditProfileScreenState extends State<SellerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthViewModel>(context, listen: false).currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    try {
      // 1. Temel Bilgileri Güncelle
      await authVM.updateUserInfo(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        dateOfBirth: authVM.currentUser?.dateOfBirth ?? DateTime.now(),
      );

      if (mounted) {
        await DialogService.showSuccess(
          context,
          message: langVM.translate('success_profile_updated'),
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(
          context,
          message: '${langVM.translate('error_prefix')}: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    try {
      await authVM.resetPassword(_emailController.text);
      if (mounted) {
        DialogService.showSuccess(
          context,
          message: langVM.translate('code_sent'),
        );
      }
    } catch (e) {
      if (mounted) {
        DialogService.showError(context, message: e.toString());
      }
    }
  }

  void _showResetPasswordBottomSheet() {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final theme = Theme.of(context);

    CustomBottomSheets.showContent(
      context: context,
      title: langVM.translate('forgot_password_title'),
      icon: Icons.lock_reset,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            langVM.translate('enter_email_message'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(langVM.translate('cancel')),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _sendPasswordResetEmail();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    foregroundColor: theme.colorScheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.5)),
                    ),
                  ),
                  child: Text(langVM.translate('send_code')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, String iconPath) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: SvgIcon(
              iconPath: iconPath,
              color: theme.colorScheme.secondary,
              size: 28)),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(langVM.translate('edit_profile')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Kişisel Bilgiler ---
              Text(
                langVM.translate('personal_information'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: _buildInputDecoration(
                          langVM.translate('first_name'), AppIcons.user),
                      validator: (v) => v!.isEmpty
                          ? langVM.translate('error_required')
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: _buildInputDecoration(
                          langVM.translate('last_name'), AppIcons.user),
                      validator: (v) => v!.isEmpty
                          ? langVM.translate('error_required')
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [_PhoneInputFormatter()],
                decoration: _buildInputDecoration(
                        langVM.translate('phone_number'), AppIcons.phone)
                    .copyWith(helperText: '5** *** ** **'),
                validator: (v) =>
                    v!.isEmpty ? langVM.translate('error_required') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                readOnly: true, // E-posta değişimi genellikle daha karmaşıktır
                decoration: _buildInputDecoration(
                        langVM.translate('email'), AppIcons.email)
                    .copyWith(
                  filled: true,
                  fillColor: theme.disabledColor.withOpacity(0.1),
                ),
              ),

              const SizedBox(height: 32),

              // --- Şifre Değiştirme Butonu ---
              OutlinedButton.icon(
                onPressed: _showResetPasswordBottomSheet,
                icon: SvgIcon(
                    iconPath: AppIcons.lock,
                    color: theme.colorScheme.primary,
                    size: 28),
                label: Text(langVM.translate('forgot_password_title')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  foregroundColor: theme.colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.5)),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(langVM.translate('save_changes')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Telefon numarası formatlayıcı: (5XX) XXX XX XX
class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Sadece rakamları al
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Tamamen silindiyse boş döndür
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Başta 0 varsa temizle
    final cleanText = text.startsWith('0') ? text.substring(1) : text;

    // Temizlendikten sonra boşsa (sadece 0 girildiyse) boş döndür
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Katı Kural: İlk rakam 5 olmak zorunda
    if (!cleanText.startsWith('5')) {
      return oldValue;
    }

    // Maksimum 10 hane
    if (cleanText.length > 10) return oldValue;

    final buffer = StringBuffer();

    // (5XX)
    buffer.write('(');
    if (cleanText.length >= 3) {
      buffer.write(cleanText.substring(0, 3));
      buffer.write(') ');
    } else {
      buffer.write(cleanText);
    }

    // XXX
    if (cleanText.length > 3) {
      if (cleanText.length >= 6) {
        buffer.write(cleanText.substring(3, 6));
        buffer.write(' ');
      } else {
        buffer.write(cleanText.substring(3));
      }
    }

    // XX
    if (cleanText.length > 6) {
      if (cleanText.length >= 8) {
        buffer.write(cleanText.substring(6, 8));
        buffer.write(' ');
      } else {
        buffer.write(cleanText.substring(6));
      }
    }

    // XX
    if (cleanText.length > 8) {
      buffer.write(cleanText.substring(8));
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
