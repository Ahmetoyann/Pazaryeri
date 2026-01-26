import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'auth_viewmodel.dart';
import '../viewmodels/language_viewmodel.dart';
import '../viewmodels/status_message_widget.dart';
import 'package:confetti/confetti.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  double _passwordStrength = 0.0;
  bool _isSeller = false;
  String? _errorMessage;
  String? _successMessage;
  late ConfettiController _confettiController;
  bool _isTermsAccepted = false;
  XFile? _profileImage;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    try {
      final success = await authVM.loginWithGoogle();
      if (success && mounted) {
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen doğum tarihinizi seçin.')),
      );
      return;
    }
    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen kullanım koşullarını kabul edin.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    try {
      final success = await authVM.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: _selectedDate!,
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        profilePicturePath: _profileImage?.path,
        isSeller: _isSeller,
      );

      if (success && mounted) {
        _confettiController.play(); // Konfeti animasyonunu başlat
        setState(() {
          _isLoading = false; // Başarılı olunca spinner'ı durdur
          _successMessage =
              Provider.of<LanguageViewModel>(context, listen: false)
                  .translate('register_success');
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Kayıt hatası: $e');
    } finally {
      // Sadece hata durumunda veya işlem bitmediyse loading'i kapat
      if (mounted && _isLoading) {
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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Fotoğrafı Kırp',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
            ],
          ),
          IOSUiSettings(
            title: 'Fotoğrafı Kırp',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() => _profileImage = XFile(croppedFile.path));
      }
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanım Koşulları'),
        content: const SingleChildScrollView(
          child: Text(
            '1. Taraflar\n'
            'İşbu sözleşme kullanıcı ile Pazaryeri uygulaması arasında akdedilmiştir.\n\n'
            '2. Konu\n'
            'İşbu sözleşmenin konusu, kullanıcının uygulamadan faydalanma şartlarının belirlenmesidir.\n\n'
            '3. Gizlilik ve Güvenlik\n'
            'Kullanıcı bilgileri gizli tutulacak ve üçüncü şahıslarla paylaşılmayacaktır.\n\n'
            '(Bu bir örnek metindir. Gerçek kullanım koşulları buraya eklenecektir.)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _isTermsAccepted = true);
              Navigator.pop(context);
            },
            child: const Text('Okudum, Kabul Ediyorum'),
          ),
        ],
      ),
    );
  }

  void _updatePasswordStrength(String password) {
    double strength = 0;
    if (password.isNotEmpty) {
      // Kriterler: Uzunluk, Büyük Harf, Küçük Harf, Rakam, Özel Karakter
      if (password.length >= 8) strength += 0.2;
      if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
      if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
      if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
      if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;
    }
    setState(() {
      _passwordStrength = strength;
    });
  }

  Color _getStrengthColor() {
    if (_passwordStrength <= 0.2) return Colors.red;
    if (_passwordStrength <= 0.4) return Colors.orange;
    if (_passwordStrength <= 0.6) return Colors.yellow.shade700;
    if (_passwordStrength <= 0.8) return Colors.blue;
    return Colors.green;
  }

  String _getStrengthText(LanguageViewModel langVM) {
    if (_passwordStrength <= 0.2)
      return langVM.translate('password_strength_very_weak');
    if (_passwordStrength <= 0.4)
      return langVM.translate('password_strength_weak');
    if (_passwordStrength <= 0.6)
      return langVM.translate('password_strength_medium');
    if (_passwordStrength <= 0.8)
      return langVM.translate('password_strength_good');
    return langVM.translate('password_strength_strong');
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    return Scaffold(
      appBar: AppBar(title: Text(langVM.translate('register'))),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null)
                    StatusMessageWidget(
                      message: _errorMessage!,
                      type: StatusType.error,
                      onClose: () => setState(() => _errorMessage = null),
                    ),
                  if (_successMessage != null)
                    StatusMessageWidget(
                      message: _successMessage!,
                      type: StatusType.success,
                      onClose: () => setState(() => _successMessage = null),
                    ),
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _profileImage != null
                                ? FileImage(File(_profileImage!.path))
                                : null,
                            child: _profileImage == null
                                ? Icon(Icons.person,
                                    size: 50, color: Colors.grey.shade400)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: const Icon(Icons.camera_alt,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'İsim',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'İsim boş olamaz' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Soyisim',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Soyisim boş olamaz' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefon Numarası',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_PhoneInputFormatter()],
                    validator: (v) =>
                        v!.isEmpty ? 'Telefon numarası boş olamaz' : null,
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return RawAutocomplete<String>(
                        textEditingController: _emailController,
                        focusNode: _emailFocusNode,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final text = textEditingValue.text.trim();
                          if (text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          // Sadece Gmail zorunluluğu olduğu için sadece onu öneriyoruz
                          const domain = '@gmail.com';

                          if (!text.contains('@')) {
                            return ['$text$domain'];
                          }

                          final index = text.indexOf('@');
                          final prefix = text.substring(0, index);
                          final domainPart = text.substring(index);

                          if (domain.startsWith(domainPart)) {
                            return ['$prefix$domain'];
                          }

                          return const Iterable<String>.empty();
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              child: SizedBox(
                                width: constraints.maxWidth,
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final String option =
                                        options.elementAt(index);
                                    return InkWell(
                                      onTap: () => onSelected(option),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(option),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        fieldViewBuilder: (context, textEditingController,
                            focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'E-posta (Gmail)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'E-posta boş olamaz';
                              // Genel e-posta formatı kontrolü
                              final emailRegex =
                                  RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(v)) {
                                return 'Geçerli bir e-posta adresi girin';
                              }
                              // Gmail alan adı kontrolü
                              if (!v.endsWith('@gmail.com')) {
                                return 'Lütfen @gmail.com uzantılı bir adres girin.';
                              }
                              return null;
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<bool>(
                    value: _isSeller,
                    decoration: InputDecoration(
                      labelText: langVM.translate('account_type_label'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.badge),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: false,
                        child: Text(langVM.translate('customer_label')),
                      ),
                      DropdownMenuItem(
                        value: true,
                        child: Text(langVM.translate('seller_label')),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _isSeller = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      _selectedDate == null
                          ? 'Doğum Tarihi Seçin'
                          : 'Doğum Tarihi: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    onChanged: _updatePasswordStrength,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
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
                    validator: (v) {
                      if (v!.isEmpty) return 'Şifre boş olamaz';
                      if (v.length < 8) return 'Şifre en az 8 karakter olmalı';
                      if (!v.contains(RegExp(r'[A-Z]')))
                        return 'Şifre en az bir büyük harf içermeli';
                      if (!v.contains(RegExp(r'[0-9]')))
                        return 'Şifre en az bir rakam içermeli';
                      return null;
                    },
                  ),
                  if (_passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _passwordStrength,
                      backgroundColor: Colors.grey.shade300,
                      color: _getStrengthColor(),
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStrengthText(langVM),
                      style: TextStyle(
                        color: _getStrengthColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Şifre Tekrar',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !_isConfirmPasswordVisible,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Lütfen şifrenizi tekrar girin';
                      }
                      if (v != _passwordController.text)
                        return 'Şifreler eşleşmiyor';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _isTermsAccepted,
                        onChanged: (val) =>
                            setState(() => _isTermsAccepted = val ?? false),
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showTermsDialog,
                          child: Text(
                            'Kullanım Koşullarını okudum ve kabul ediyorum',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    // Başarılı mesajı gösterilirken de butonu devre dışı bırak
                    onPressed: (_isLoading || _successMessage != null)
                        ? null
                        : _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(langVM.translate('register')),
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
                    onPressed: (_isLoading || _successMessage != null)
                        ? null
                        : _registerWithGoogle,
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
                      langVM.translate('google_register'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
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
