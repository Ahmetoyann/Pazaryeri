import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../../data/models/market.dart';
import '../../widgets/custom_app_bar.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_search_bar.dart';

class SellerMarketSelectionScreen extends StatefulWidget {
  const SellerMarketSelectionScreen({super.key});

  @override
  State<SellerMarketSelectionScreen> createState() =>
      _SellerMarketSelectionScreenState();
}

class _SellerMarketSelectionScreenState
    extends State<SellerMarketSelectionScreen> {
  bool _isChecking = true;
  List<Market> _allMarkets = [];
  List<Market> _filteredMarkets = [];
  bool _isLoadingMarkets = true;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCity;
  List<String> _cities = [];

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında kayıtlı seçim var mı kontrol et
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkExistingSelection());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingSelection() async {
    final userData = await AuthService.instance.getUserData();
    // Eğer kullanıcı daha önce bir pazar seçmişse (sellerMarketId doluysa)
    if (userData != null &&
        userData['sellerMarketId'] != null &&
        userData['sellerMarketId']!.isNotEmpty) {
      if (mounted) {
        final authVM = Provider.of<AuthViewModel>(context, listen: false);
        authVM.setSellerMarketId(userData['sellerMarketId']!);
        return;
      }
    }
    // Seçim yoksa listeyi göster
    if (mounted) {
      setState(() {
        _isChecking = false;
      });
      _loadMarkets();
    }
  }

  Future<void> _loadMarkets() async {
    try {
      final sellerVM = Provider.of<SellerViewModel>(context, listen: false);
      final markets = await sellerVM.getMarkets();
      if (mounted) {
        // Şehirleri çıkar ve sırala
        final cities = markets
            .map((m) => m.address.city)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();
        cities.sort();

        setState(() {
          _allMarkets = markets;
          _filteredMarkets = markets;
          _cities = cities;
          _isLoadingMarkets = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMarkets = false);
      }
    }
  }

  void _filterMarkets() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMarkets = _allMarkets.where((market) {
        final matchesSearch = query.isEmpty ||
            market.name.toLowerCase().contains(query) ||
            market.address.district.toLowerCase().contains(query) ||
            market.address.neighborhood.toLowerCase().contains(query);
        final matchesCity =
            _selectedCity == null || market.address.city == _selectedCity;
        return matchesSearch && matchesCity;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sellerVM = Provider.of<SellerViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context);

    // Kontrol sürerken yükleniyor göster
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CustomLoadingIndicator()),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(langVM.translate('select_market_title')),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                langVM.translate('select_market_instruction'),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            // İl Filtresi
            if (!_isLoadingMarkets && _cities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).cardColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCity,
                      hint: Text(
                        langVM.translate('select_city_all'),
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
                        size: 28,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(langVM.translate('all_option')),
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
                        _filterMarkets();
                      },
                    ),
                  ),
                ),
              ),
            // Arama Çubuğu
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: CustomSearchBar(
                controller: _searchController,
                hintText: langVM.translate('search_market_hint'),
                onChanged: (val) => _filterMarkets(),
              ),
            ),
            Expanded(
              child: _isLoadingMarkets
                  ? const Center(child: CustomLoadingIndicator())
                  : _filteredMarkets.isEmpty
                      ? Center(
                          child: Text(
                          langVM.translate('no_results'),
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6)),
                        ))
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _filteredMarkets.length,
                          itemBuilder: (context, index) {
                            final market = _filteredMarkets[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              elevation: 4,
                              shadowColor: Colors.black.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide.none,
                              ),
                              color: Theme.of(context).cardColor,
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.people,
                                    size: 28,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                title: Text(market.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(market.address.district),
                                trailing: Icon(Icons.arrow_forward,
                                    size: 20,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6)),
                                onTap: () async {
                                  // İşlem başladığında yükleniyor dialogunu göster
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    useRootNavigator: false,
                                    builder: (ctx) => const Center(
                                        child: CustomLoadingIndicator()),
                                  );

                                  // 1. Seçimi ViewModel'e bildir
                                  sellerVM.selectMarket(market);
                                  final navigator = Navigator.of(context);
                                  final scaffoldMessenger =
                                      ScaffoldMessenger.of(context);
                                  final authVM = Provider.of<AuthViewModel>(
                                      context,
                                      listen: false);

                                  try {
                                    // 2. Seçimi Kalıcı Olarak Kaydet (DB ve Yerel)
                                    if (authVM.currentUser != null) {
                                      // Firestore'a kaydet (Firebase'de tutulması için await)
                                      await AuthService.instance
                                          .updateUserInDb({
                                        'sellerMarketId': market.id,
                                        'isSeller':
                                            true, // Satıcı olarak işaretle
                                      }, authVM.currentUser!.email);

                                      await AuthService.instance
                                          .updateSellerMarketId(market.id);

                                      // YENİ: Satıcının mevcut ürünlerinin de pazarını güncelle
                                      await AuthService.instance
                                          .updateSellerProductsMarket(
                                              authVM.currentUser!.id,
                                              market.id);

                                      // 3. State'i Güncelle (Anında Yansıması İçin)
                                      authVM.setSellerMarketId(market.id);
                                      await authVM
                                          .refreshCurrentUser(); // Tüm uygulamada güncellenmesi için
                                    }

                                    // İşlem başarılı, yükleniyor dialogunu kapat
                                    navigator.pop();
                                  } catch (e) {
                                    // Hata oluştu, yükleniyor dialogunu kapat
                                    navigator.pop();

                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${langVM.translate('error_prefix')}: $e'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
