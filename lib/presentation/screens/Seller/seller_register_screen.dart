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
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/custom_snackbars.dart';

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
  bool _isLoadingMarkets = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isTermsAccepted = false;
  List<Market> _markets = [];
  double _passwordStrength = 0;

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
    _passwordController.addListener(_updatePasswordStrength);
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

  void _updatePasswordStrength() {
    final pass = _passwordController.text;
    if (pass.isEmpty) {
      setState(() => _passwordStrength = 0);
    } else if (pass.length < 6) {
      setState(() => _passwordStrength = 1 / 3);
    } else if (pass.length < 8 || !pass.contains(RegExp(r'[0-9A-Z!@#\$&*~]'))) {
      setState(() => _passwordStrength = 2 / 3);
    } else {
      setState(() => _passwordStrength = 1.0);
    }
  }

  Color _getStrengthColor() {
    if (_passwordStrength <= 0.34) return Colors.red;
    if (_passwordStrength <= 0.67) return Colors.orange;
    return Colors.green;
  }

  String _getStrengthText() {
    if (_passwordStrength <= 0.34) return 'Zayıf';
    if (_passwordStrength <= 0.67) return 'Orta';
    return 'Güçlü';
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      // Spark Paketi İçin Kritik Ayarlar:
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() => _profileImage = image);
    }
  }

  void _showImagePickerOptions() {
    CustomBottomSheets.showImagePicker(
      context: context,
      onCameraTap: () => _pickImage(ImageSource.camera),
      onGalleryTap: () => _pickImage(ImageSource.gallery),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMarketId == null) {
      CustomSnackbars.showError(context, 'Lütfen bir pazar yeri seçiniz.');
      return;
    }

    if (!_isTermsAccepted) {
      CustomSnackbars.showError(
          context, 'Lütfen kullanım koşullarını kabul ediniz.');
      return;
    }

    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    try {
      await LoadingOverlay.show(
        context,
        asyncFunction: () async {
          await authVM.registerSeller(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            marketId: _selectedMarketId!,
            profileImagePath: _profileImage?.path,
          );
        },
      );

      if (mounted) {
        CustomSnackbars.showSuccess(
          context,
          langVM.translate('register_success_verify'),
        );
        Navigator.of(context).pop(); // Giriş ekranına dön
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showError(context, 'Kayıt hatası: $e');
      }
    }
  }

  void _showMarketPicker() {
    CustomBottomSheets.showDraggable(
      context: context,
      initialChildSize: 0.7,
      builder: (context, scrollController) => _MarketSelectionSheet(
        markets: _markets,
        scrollController: scrollController,
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
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
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
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Okudum, Kabul Ediyorum',
            onPressed: () {
              setState(() => _isTermsAccepted = true);
              Navigator.pop(context);
            },
            isFullWidth: true,
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
      appBar: const CustomAppBar(title: Text('Satıcı Kaydı')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Center(
                    child: Stack(
                      children: [
                        if (_profileImage == null)
                          CustomPaint(
                            painter: _DashedBorderPainter(
                              color: theme.colorScheme.primary.withOpacity(0.5),
                              borderRadius:
                                  60.0, // 120x120 kutuyu tam daire yapar
                            ),
                            child: Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    color: theme.colorScheme.primary,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    langVM.translate('add_photo_button'),
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ClipOval(
                            child: Image.file(
                              File(_profileImage!.path),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        if (_profileImage != null)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: theme.colorScheme.primary,
                              child: SvgIcon(
                                  iconPath: AppIcons.camera,
                                  size: 22,
                                  color: theme.colorScheme.onPrimary),
                            ),
                          ),
                      ],
                    ),
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
                        validator: (v) =>
                            v!.isEmpty ? 'Lütfen isminizi giriniz' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration:
                            _inputDecoration(context, 'Soyisim', AppIcons.user),
                        validator: (v) =>
                            v!.isEmpty ? 'Lütfen soyisminizi giriniz' : null,
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
                    if (v == null || v.isEmpty)
                      return 'Lütfen e-posta adresinizi giriniz';
                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(v)) {
                      return 'Lütfen geçerli bir e-posta adresi giriniz';
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
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Lütfen telefon numaranızı giriniz';
                    if (v.length < 15)
                      return 'Lütfen geçerli bir numara giriniz';
                    return null;
                  },
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
                            child: CustomLoadingIndicator(size: 20),
                          )
                        : const Icon(Icons.arrow_drop_down),
                  ),
                  onTap: _isLoadingMarkets ? null : _showMarketPicker,
                  validator: (v) => _selectedMarketId == null
                      ? 'Lütfen satış yapacağınız pazar yerini seçiniz'
                      : null,
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
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Lütfen bir şifre belirleyiniz';
                    if (v.length < 6)
                      return 'Şifreniz en az 6 karakterden oluşmalıdır';
                    return null;
                  },
                ),
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 4,
                          decoration: BoxDecoration(
                            color: _passwordStrength >= 0.33
                                ? _getStrengthColor()
                                : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 4,
                          decoration: BoxDecoration(
                            color: _passwordStrength >= 0.66
                                ? _getStrengthColor()
                                : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 4,
                          decoration: BoxDecoration(
                            color: _passwordStrength >= 1.0
                                ? _getStrengthColor()
                                : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _getStrengthText(),
                      style: TextStyle(
                        color: _getStrengthColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
                      return 'Lütfen şifrenizi tekrar giriniz';
                    }
                    if (v != _passwordController.text)
                      return 'Girdiğiniz şifreler birbiriyle uyuşmuyor';
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
                CustomButton(
                  text: 'Kayıt Ol',
                  onPressed: !_isTermsAccepted ? null : _register,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  foregroundColor: theme.colorScheme.primary,
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

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.dashWidth = 8.0,
    this.dashSpace = 6.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();
    final dashedPath = Path();

    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.borderRadius != borderRadius;
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
  final ScrollController scrollController;

  const _MarketSelectionSheet(
      {required this.markets,
      required this.onSelect,
      required this.scrollController});

  @override
  State<_MarketSelectionSheet> createState() => _MarketSelectionSheetState();
}

class _MarketSelectionSheetState extends State<_MarketSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    return Column(
      children: [
        if (_cities.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? theme.cardColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCity,
                  hint: Text(
                    'İl Seçiniz (Tümü)',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  isExpanded: true,
                  icon: SvgIcon(
                    iconPath: AppIcons.market,
                    color: theme.colorScheme.primary,
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: CustomSearchBar(
            controller: _searchController,
            hintText: 'Pazar Ara...',
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: widget.scrollController,
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: theme.dividerColor.withOpacity(0.2)),
            itemBuilder: (context, index) {
              final market = filtered[index];
              return ListTile(
                title: Text(market.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${market.address.neighborhood}, ${market.address.district}',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7))),
                trailing: Icon(Icons.chevron_right,
                    color: theme.colorScheme.primary.withOpacity(0.5)),
                onTap: () => widget.onSelect(market),
              );
            },
          ),
        ),
      ],
    );
  }
}
