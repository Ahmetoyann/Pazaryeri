import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../../data/models/market.dart';
import '../../widgets/status_message_widget.dart';
import '../../widgets/success_dialog.dart';

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
  bool _isLoading = false;
  bool _isLoadingMarkets = true;
  bool _obscurePassword = true;
  String? _errorMessage;
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMarketId == null) {
      setState(() => _errorMessage = 'Lütfen bir pazar yeri seçiniz.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    try {
      await authVM.registerSeller(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        marketId: _selectedMarketId!,
      );

      if (mounted) {
        // Modern başarı mesajı
        await showSuccessDialog(
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
        setState(() => _errorMessage = 'Kayıt hatası: $e');
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
      appBar: AppBar(
        title: const Text('Satıcı Kaydı'),
        backgroundColor: Colors.orange.shade50,
        foregroundColor: Colors.orange.shade900,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.shade50,
                  ),
                  child: Icon(
                    Icons.person_add_alt_1,
                    size: 40,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: StatusMessageWidget(
                      message: _errorMessage!,
                      type: StatusType.error,
                      onClose: () => setState(() => _errorMessage = null),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: _inputDecoration('İsim', Icons.person),
                        validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration:
                            _inputDecoration('Soyisim', Icons.person_outline),
                        validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('E-posta', Icons.email_outlined),
                  validator: (v) => v!.isEmpty ? 'E-posta gerekli' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('Telefon', Icons.phone),
                  validator: (v) => v!.isEmpty ? 'Telefon gerekli' : null,
                ),
                const SizedBox(height: 16),
                // Pazar Yeri Seçimi (Dropdown)
                TextFormField(
                  controller: _marketController,
                  readOnly: true,
                  decoration: _inputDecoration('Pazar Yeri Seçin', Icons.store)
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
                      _inputDecoration('Şifre', Icons.lock_outline).copyWith(
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
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.orange.shade700),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.zero,
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
