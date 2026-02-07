import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/success_dialog.dart';
import '../../widgets/custom_app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // Kaydet butonuna basıldığında klavyeyi kapat
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authVM = context.read<AuthViewModel>();
      await authVM.updateUserInfo(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: authVM.currentUser?.email ?? '',
        dateOfBirth: authVM.currentUser?.dateOfBirth ?? DateTime.now(),
      );
      if (mounted) {
        await DialogService.showSuccess(
          context,
          message: 'Bilgiler güncellendi!',
          onDismiss: () {
            if (mounted) Navigator.of(context).pop(); // Ekranı kapat
          },
        );
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, message: 'Hata: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon,
      {String? helperText}) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      helperStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      prefixIcon: Icon(icon, color: Theme.of(context).iconTheme.color),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.5), width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: Text('Profili Düzenle')),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.only(top: 110, left: 16, right: 16, bottom: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: _buildInputDecoration('İsim', Icons.person),
                validator: (v) => v!.isEmpty ? 'İsim boş olamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration:
                    _buildInputDecoration('Soyisim', Icons.person_outline),
                validator: (v) => v!.isEmpty ? 'Soyisim boş olamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration:
                    _buildInputDecoration('Telefon Numarası', Icons.phone),
                keyboardType: TextInputType.phone,
                inputFormatters: [_PhoneInputFormatter()],
                validator: (v) =>
                    v!.isEmpty ? 'Telefon numarası boş olamaz' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Kaydet',
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

/// Telefon numarası formatlayıcı: (5XX) XXX XX XX
class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Sadece rakamları al
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Başta 0 varsa temizle
    final cleanText = text.startsWith('0') ? text.substring(1) : text;

    // Maksimum 10 hane
    if (cleanText.length > 10) return oldValue;

    final buffer = StringBuffer();

    // (5XX)
    if (cleanText.isNotEmpty) {
      buffer.write('(');
      if (cleanText.length >= 3) {
        buffer.write(cleanText.substring(0, 3));
        buffer.write(') ');
      } else {
        buffer.write(cleanText);
      }
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
