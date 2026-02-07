import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../../data/models/market.dart';
import '../../widgets/success_dialog.dart';
import '../../widgets/custom_app_bar.dart';

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
  final _marketController = TextEditingController();

  String? _selectedMarketId;
  XFile? _profileImage;
  bool _isLoading = false;
  bool _isLoadingMarkets = true;
  bool _obscurePassword = true;
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

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final sellerVM = Provider.of<SellerViewModel>(context);

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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.1),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      image: _profileImage != null
                          ? DecorationImage(
                              image: FileImage(File(_profileImage!.path)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _profileImage == null
                        ? Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: Theme.of(context).colorScheme.secondary,
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
                            _inputDecoration(context, 'İsim', Icons.person),
                        validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: _inputDecoration(
                            context, 'Soyisim', Icons.person_outline),
                        validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                      context, 'E-posta', Icons.email_outlined),
                  validator: (v) => v!.isEmpty ? 'E-posta gerekli' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(context, 'Telefon', Icons.phone),
                  validator: (v) => v!.isEmpty ? 'Telefon gerekli' : null,
                ),
                const SizedBox(height: 16),
                // Pazar Yeri Seçimi (Dropdown)
                TextFormField(
                  controller: _marketController,
                  readOnly: true,
                  decoration:
                      _inputDecoration(context, 'Pazar Yeri Seçin', Icons.store)
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
                  decoration:
                      _inputDecoration(context, 'Şifre', Icons.lock_outline)
                          .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      v!.length < 6 ? 'Şifre en az 6 karakter olmalı' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
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
                          color: Theme.of(context).colorScheme.secondary,
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
      BuildContext context, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.secondary),
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

  @override
  Widget build(BuildContext context) {
    final filtered = widget.markets.where((m) {
      final q = _searchQuery.toLowerCase();
      return m.name.toLowerCase().contains(q) ||
          m.address.district.toLowerCase().contains(q) ||
          m.address.neighborhood.toLowerCase().contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Pazar Ara...',
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final market = filtered[index];
                    return ListTile(
                      title: Text(market.name),
                      subtitle: Text(
                          '${market.address.neighborhood}, ${market.address.district}'),
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
