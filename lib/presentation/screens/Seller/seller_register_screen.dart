import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../../data/models/market.dart';
import '../../widgets/success_dialog.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_sheets.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';

class SellerRegisterScreen extends StatefulWidget {
  const SellerRegisterScreen({super.key});

  @override
  State<SellerRegisterScreen> createState() => _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends State<SellerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _marketController = TextEditingController();

  String? _selectedMarketId;
  XFile? _profileImage;
  bool _isLoading = false;
  bool _isLoadingMarkets = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isTermsAccepted = false;
  List<Market> _markets = [];

  @override
  void initState() {
    super.initState();
    // Pazarları yükle
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final markets =
            await Provider.of<SellerViewModel>(context, listen: false)
                .getMarkets();
        if (mounted) {
          setState(() {
            _markets = markets;
            _isLoadingMarkets = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingMarkets = false);
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _marketController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      // Spark Paketi İçin Kritik Ayarlar:
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() => _profileImage = image);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMarketId == null) {
      await DialogService.showError(context,
          message: 'Lütfen bir pazar yeri seçiniz.');
      return;
    }

    if (!_isTermsAccepted) {
      await DialogService.showError(context,
          message: 'Lütfen kullanım koşullarını kabul ediniz.');
      return;
    }

    setState(() => _isLoading = true);

    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    try {
      await authVM.registerSeller(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        marketId: _selectedMarketId!,
        profileImagePath: _profileImage?.path,
      );

      if (mounted) {
        // Modern başarı mesajı
        await DialogService.showSuccess(
          context,
          message:
              'Satıcı kaydınız başarıyla oluşturuldu!\nGiriş yapabilirsiniz.',
          onDismiss: () {
            if (mounted) {
              Navigator.of(context).pop(); // Giriş ekranına dön
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, message: 'Kayıt hatası: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMarketPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MarketSelectionSheet(
        markets: _markets,
        onSelect: (market) {
          setState(() {
            _selectedMarketId = market.id;
            _marketController.text = market.name;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showTermsDialog() {
    CustomBottomSheets.showContent(
      context: context,
      title: 'Kullanım Koşulları',
      child: Column(
        children: [
          const SizedBox(
            height: 300,
            child: SingleChildScrollView(
              child: Text(
                'Pazaryeri Satıcı Sözleşmesi\n\n'
                '1. Taraflar\n'
                'İşbu sözleşme, Pazaryeri uygulaması ile satıcı arasında akdedilmiştir.\n\n'
                '2. Konu\n'
                'Satıcının uygulama üzerinden ürünlerini listelemesi ve satışa sunması ile ilgili şartları kapsar.\n\n'
                '3. Yükümlülükler\n'
                'Satıcı, listelediği ürünlerin doğruluğundan ve kalitesinden sorumludur. '
                'Yanıltıcı bilgi verilmesi durumunda hesap askıya alınabilir.\n\n'
                '4. Gizlilik\n'
                'Kullanıcı verileri gizlilik politikası çerçevesinde korunmaktadır.\n\n'
                '(Bu metin örnektir, lütfen kendi sözleşmenizi ekleyiniz.)',
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _isTermsAccepted = true);
                Navigator.pop(context);
              },
              child: const Text('Okudum, Kabul Ediyorum'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final sellerVM = Provider.of<SellerViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: Text('Satıcı Kaydı')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 110, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 100,
                    width: 100,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.cardColor,
                      border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.5)),
                      image: _profileImage != null
                          ? DecorationImage(
                              image: FileImage(File(_profileImage!.path)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _profileImage == null
                        ? SvgIcon(
                            iconPath: AppIcons.camera,
                            size: 32,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration:
                            _inputDecoration(context, 'İsim', AppIcons.user),
                        validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration:
                            _inputDecoration(context, 'Soyisim', AppIcons.user),
                        validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      _inputDecoration(context, 'E-posta', AppIcons.email),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'E-posta gerekli';
                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(v)) {
                      return 'Geçerli bir e-posta adresi giriniz';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_PhoneInputFormatter()],
                  decoration:
                      _inputDecoration(context, 'Telefon', AppIcons.phone)
                          .copyWith(helperText: '5** *** ** **'),
                  validator: (v) => v!.isEmpty ? 'Telefon gerekli' : null,
                ),
                const SizedBox(height: 16),
                // Pazar Yeri Seçimi (Dropdown)
                TextFormField(
                  controller: _marketController,
                  readOnly: true,
                  decoration: _inputDecoration(
                          context, 'Pazar Yeri Seçin', AppIcons.market)
                      .copyWith(
                    suffixIcon: _isLoadingMarkets
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_drop_down),
                  ),
                  onTap: _isLoadingMarkets ? null : _showMarketPicker,
                  validator: (v) =>
                      _selectedMarketId == null ? 'Lütfen pazar seçin' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration(context, 'Şifre', AppIcons.lock)
                      .copyWith(
                    suffixIcon: IconButton(
                      icon: SvgIcon(
                          iconPath: _obscurePassword
                              ? AppIcons.visibility
                              : AppIcons.visibilityOff,
                          color: theme.colorScheme.primary,
                          size: 24),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      v!.length < 6 ? 'Şifre en az 6 karakter olmalı' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration:
                      _inputDecoration(context, 'Şifre Tekrar', AppIcons.lock)
                          .copyWith(
                    suffixIcon: IconButton(
                      icon: SvgIcon(
                          iconPath: _obscureConfirmPassword
                              ? AppIcons.visibility
                              : AppIcons.visibilityOff,
                          color: theme.colorScheme.primary,
                          size: 24),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
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
                      onChanged: (value) {
                        setState(() => _isTermsAccepted = value ?? false);
                      },
                      activeColor: theme.colorScheme.primary,
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
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed:
                      (_isLoading || !_isTermsAccepted) ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    foregroundColor: theme.colorScheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.1)),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Kayıt Ol',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Zaten hesabınız var mı? "),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "Giriş Yap",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
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
    );
  }

  InputDecoration _inputDecoration(
      BuildContext context, String label, String iconPath) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: SvgIcon(
            iconPath: iconPath,
            color: theme.colorScheme.primary,
            size: 24,
          )),
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

class _MarketSelectionSheet extends StatefulWidget {
  final List<Market> markets;
  final Function(Market) onSelect;

  const _MarketSelectionSheet({required this.markets, required this.onSelect});

  @override
  State<_MarketSelectionSheet> createState() => _MarketSelectionSheetState();
}

class _MarketSelectionSheetState extends State<_MarketSelectionSheet> {
  String _searchQuery = '';
  String? _selectedCity;
  List<String> _cities = [];

  @override
  void initState() {
    super.initState();
    _cities = widget.markets
        .map((m) => m.address.city)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    _cities.sort();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = widget.markets.where((m) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = m.name.toLowerCase().contains(q) ||
          m.address.district.toLowerCase().contains(q) ||
          m.address.neighborhood.toLowerCase().contains(q);
      final matchesCity =
          _selectedCity == null || m.address.city == _selectedCity;
      return matchesSearch && matchesCity;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (_cities.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCity,
                        hint: Text(
                          'İl Seçiniz (Tümü)',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                        isExpanded: true,
                        icon: SvgIcon(
                          iconPath: AppIcons.market,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Tümü'),
                          ),
                          ..._cities.map((String city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(city),
                            );
                          }).toList(),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCity = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Pazar Ara...',
                    prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SvgIcon(
                            iconPath: AppIcons.search,
                            color: theme.colorScheme.primary,
                            size: 24)),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: theme.colorScheme.primary, width: 2)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: theme.dividerColor),
                  itemBuilder: (context, index) {
                    final market = filtered[index];
                    return ListTile(
                      title: Text(market.name,
                          style: TextStyle(color: theme.colorScheme.onSurface)),
                      subtitle: Text(
                          '${market.address.neighborhood}, ${market.address.district}',
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.7))),
                      onTap: () => widget.onSelect(market),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
