import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/success_dialog.dart';

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
  late TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _selectedDate = user?.dateOfBirth;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // Kaydet butonuna basıldığında klavyeyi kapat
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_selectedDate == null) {
        throw Exception('Lütfen doğum tarihi seçin.');
      }

      await context.read<AuthViewModel>().updateUserInfo(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            dateOfBirth: _selectedDate!,
            newPassword: _passwordController.text.isNotEmpty
                ? _passwordController.text
                : null,
          );
      if (mounted) {
        await showSuccessDialog(
          context,
          message: 'Bilgiler güncellendi!',
          onDismiss: () {
            if (mounted) Navigator.of(context).pop(); // Ekranı kapat
          },
        );
      }
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, message: 'Hata: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profili Düzenle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'İsim',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v!.isEmpty ? 'İsim boş olamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Soyisim',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v!.isEmpty ? 'Soyisim boş olamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [_PhoneInputFormatter()],
                validator: (v) =>
                    v!.isEmpty ? 'Telefon numarası boş olamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'E-posta boş olamaz' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.only(),
                title: Text(
                  _selectedDate == null
                      ? 'Doğum Tarihi Seçin'
                      : 'Doğum Tarihi: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                ),
                leading: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre (İsteğe Bağlı)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  helperText:
                      'Şifrenizi değiştirmek istemiyorsanız boş bırakın.',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Kaydet',
                          style: TextStyle(color: Colors.green),
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
