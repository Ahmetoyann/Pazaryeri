import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../../data/models/market.dart';
import 'product_detail_screen.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/product_card.dart';
import '../../widgets/custom_search_bar.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedCategories = [];
  String _searchQuery = '';
  List<String> _favoriteProductIds = [];
  bool _filterOpenToday = false;
  String _sortOption = 'newest'; // 'smart', 'newest'
  RangeValues _priceRange = const RangeValues(0, 2000);

  final List<String> _categories = [
    'category_fruit',
    'category_vegetable',
    'category_delicatessen',
    'category_dairy',
    'category_bakery',
    'category_spices',
    'category_fish',
    'category_clothing',
    'category_electronics',
    'category_second_hand',
    'category_animals',
    'category_home',
    'category_toys',
    'category_books',
    'category_tools',
    'category_plants',
    'category_handmade',
    'category_cosmetics',
    'category_sports',
    'category_automotive',
    'category_antiques',
    'category_jewelry',
    'category_art',
    'category_baby',
    'category_music',
    'category_office',
    'category_other',
  ];

  final Map<String, String> _categoryPaths = {
    'category_fruit': AppIcons.fruit,
    'category_vegetable': AppIcons.vegetable,
    'category_delicatessen': AppIcons.delicatessen,
    'category_dairy': AppIcons.dairy,
    'category_bakery': AppIcons.bakery,
    'category_spices': AppIcons.spices,
    'category_fish': AppIcons.fish,
    'category_clothing': AppIcons.clothing,
    'category_electronics': AppIcons.electronics,
    'category_second_hand': AppIcons.secondHand,
    'category_animals': AppIcons.animals,
    'category_home': AppIcons.homeLiving,
    'category_toys': AppIcons.toys,
    'category_books': AppIcons.books,
    'category_tools': AppIcons.tools,
    'category_plants': AppIcons.plants,
    'category_handmade': AppIcons.handmade,
    'category_cosmetics': AppIcons.cosmetics,
    'category_sports': AppIcons.sports,
    'category_automotive': AppIcons.automotive,
    'category_antiques': AppIcons.antiques,
    'category_jewelry': AppIcons.jewelry,
    'category_art': AppIcons.art,
    'category_baby': AppIcons.baby,
    'category_music': AppIcons.music,
    'category_office': AppIcons.office,
    'category_other': AppIcons.other,
  };

  List<DocumentSnapshot> _allProducts = [];
  bool _isStreamLoading = true;
  StreamSubscription<QuerySnapshot>? _streamSubscription;
  final ScrollController _scrollController = ScrollController();
  int _productsLimit = 50;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  Map<String, Market> _marketsMap = {};

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _setupStream();
    _loadFavorites();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMarkets());
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadMarkets() async {
    try {
      final sellerVM = Provider.of<SellerViewModel>(context, listen: false);
      final markets = await sellerVM.getMarkets();
      if (mounted) {
        setState(() {
          _marketsMap = {for (var m in markets) m.id: m};
        });
      }
    } catch (e) {
      debugPrint('Marketler yüklenemedi: $e');
    }
  }

  void _setupStream() {
    _streamSubscription?.cancel();

    Query query = FirebaseFirestore.instance.collection('products');

    // Sıralama
    if (_sortOption == 'newest') {
      query = query.orderBy('createdAt', descending: true);
    } else if (_sortOption == 'price_asc') {
      query = query.orderBy('price', descending: false);
    } else if (_sortOption == 'price_desc') {
      query = query.orderBy('price', descending: true);
    }

    // Sayfalama Kontrolü:
    // Arama, filtreleme veya akıllı sıralama aktifse tüm veriyi çekmemiz gerekir.
    // Çünkü bu işlemler client-side (istemci taraflı) yapılıyor.
    bool shouldLoadAll = _searchQuery.isNotEmpty ||
        _filterOpenToday ||
        _selectedCategories.isNotEmpty ||
        _sortOption == 'smart' ||
        _priceRange.start > 0 ||
        _priceRange.end < 2000;

    if (!shouldLoadAll) {
      query = query.limit(_productsLimit);
    }

    _streamSubscription = query.snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          _allProducts = snapshot.docs;
          _isStreamLoading = false;
        });
      }
    });
  }

  void _onScroll() {
    if (!mounted) return;
    // Listenin sonuna yaklaşıldığında (%90)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMore();
    }
  }

  void _loadMore() {
    // Eğer zaten tüm veriyi yüklüyorsak (filtreler aktifse) daha fazla yüklemeye gerek yok
    bool shouldLoadAll = _searchQuery.isNotEmpty ||
        _filterOpenToday ||
        _selectedCategories.isNotEmpty ||
        _sortOption == 'smart' ||
        _priceRange.start > 0 ||
        _priceRange.end < 2000;

    if (shouldLoadAll) return;

    setState(() {
      _productsLimit += 20; // 20'şer artır
      _setupStream();
    });
  }

  Future<void> _loadFavorites() async {
    final favs = await AuthService.instance.getFavoriteProducts();
    if (mounted) {
      setState(() {
        _favoriteProductIds = favs;
      });
    }
  }

  Future<void> _refreshProducts() async {
    await _loadFavorites();
    setState(() {
      _productsLimit = 20; // Yenilendiğinde limiti sıfırla
      _setupStream();
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _searchController.text = val.recognizedWords;
              _searchQuery = val.recognizedWords.toLowerCase();
              _setupStream();
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategories.clear();
      _filterOpenToday = false;
      _priceRange = const RangeValues(0, 2000);
      _sortOption = 'smart';
    });
    _setupStream();
  }

  void _showFilterBottomSheet() {
    // Geçici durum değişkenleri (Kullanıcı 'Uygula' diyene kadar asıl state değişmez)
    String tempSortOption = _sortOption;
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    List<String> tempSelectedCategories = List.from(_selectedCategories);
    bool tempFilterOpenToday = _filterOpenToday;
    RangeValues tempPriceRange = _priceRange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        langVM.translate('filter_sort_title'),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      TextButton(
                        onPressed: () {
                          this.setState(() {
                            _sortOption = 'smart';
                            _selectedCategories.clear();
                            _filterOpenToday = false;
                            _priceRange = const RangeValues(0, 2000);
                          });
                          _setupStream();
                          Navigator.pop(context);
                        },
                        child: Text(
                          langVM.translate('clear_button'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Sıralama
                      Text(langVM.translate('sort_title'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSortChip(
                                setState,
                                'smart',
                                langVM.translate('sort_smart'),
                                tempSortOption,
                                (val) => tempSortOption = val),
                            const SizedBox(width: 8),
                            _buildSortChip(
                                setState,
                                'newest',
                                langVM.translate('sort_newest'),
                                tempSortOption,
                                (val) => tempSortOption = val),
                            const SizedBox(width: 8),
                            _buildSortChip(
                                setState,
                                'price_asc',
                                langVM.translate('sort_price_asc'),
                                tempSortOption,
                                (val) => tempSortOption = val),
                            const SizedBox(width: 8),
                            _buildSortChip(
                                setState,
                                'price_desc',
                                langVM.translate('sort_price_desc'),
                                tempSortOption,
                                (val) => tempSortOption = val),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Kategoriler
                      Text(langVM.translate('categories_title'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((cat) {
                          final isSelected =
                              tempSelectedCategories.contains(cat);
                          return FilterChip(
                            label: Text(Provider.of<LanguageViewModel>(context,
                                    listen: false)
                                .translate(cat)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  tempSelectedCategories.add(cat);
                                } else {
                                  tempSelectedCategories.remove(cat);
                                }
                              });
                            },
                            backgroundColor:
                                Theme.of(context).cardColor.withOpacity(0.7),
                            selectedColor:
                                Theme.of(context).colorScheme.primary,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 8),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Fiyat Aralığı
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(langVM.translate('price_range_title'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            '${tempPriceRange.start.round()}₺ - ${tempPriceRange.end.round()}₺',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RangeSlider(
                        values: tempPriceRange,
                        min: 0,
                        max: 2000,
                        divisions: 40,
                        labels: RangeLabels(
                          '${tempPriceRange.start.round()}₺',
                          '${tempPriceRange.end.round()}₺',
                        ),
                        onChanged: (values) {
                          setState(() => tempPriceRange = values);
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        inactiveColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                      ),
                      const SizedBox(height: 24),

                      // Diğer Filtreler
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: CheckboxListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          title: Text(
                              langVM.translate('filter_open_today_only'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          value: tempFilterOpenToday,
                          onChanged: (val) => setState(
                              () => tempFilterOpenToday = val ?? false),
                          activeColor: Theme.of(context).colorScheme.primary,
                          controlAffinity: ListTileControlAffinity.trailing,
                        ),
                      ),
                    ],
                  ),
                ),
                // Uygula Butonu
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: CustomButton(
                    text: langVM.translate('show_results_button'),
                    onPressed: () {
                      // Filtreleri uygula
                      this.setState(() {
                        _sortOption = tempSortOption;
                        _selectedCategories.clear();
                        _selectedCategories.addAll(tempSelectedCategories);
                        _filterOpenToday = tempFilterOpenToday;
                        _priceRange = tempPriceRange;
                      });
                      _setupStream();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortChip(StateSetter setState, String value, String label,
      String currentSort, Function(String) onSelect) {
    final isSelected = currentSort == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => onSelect(value));
        }
      },
      backgroundColor: Theme.of(context).cardColor.withOpacity(0.7),
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2),
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCategories.isNotEmpty) count++;
    if (_filterOpenToday) count++;
    if (_priceRange.start > 0 || _priceRange.end < 2000) count++;
    return count;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final homeVM = Provider.of<HomeViewModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Üst Alan (Arama ve Filtreler)
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 16,
            16,
            16,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Arama Çubuğu
                  Expanded(
                    child: CustomSearchBar(
                      controller: _searchController,
                      hintText: langVM.translate('search_hint'),
                      onMicPressed: _listen,
                      isListening: _isListening,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                          _setupStream();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filtre Butonu
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.filter_list,
                              color: Theme.of(context).colorScheme.primary),
                          tooltip: 'Filtrele',
                          onPressed: _showFilterBottomSheet,
                        ),
                      ),
                      if (_activeFilterCount > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        // Ürün Listesi
        Expanded(
          child: _isStreamLoading && _allProducts.isEmpty
              ? const Center(child: CustomLoadingIndicator())
              : Builder(
                  builder: (context) {
                    if (_allProducts.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _refreshProducts,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
                                  child: Text(
                                      langVM.translate('no_products_added'))),
                            ),
                          ],
                        ),
                      );
                    }

                    // 1. Verileri al ve filtrele
                    var products = _allProducts.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      data['id'] = doc.id;
                      return data;
                    }).where((product) {
                      // Arama filtresi
                      final name =
                          (product['name'] ?? '').toString().toLowerCase();
                      if (_searchQuery.isNotEmpty &&
                          !name.contains(_searchQuery)) {
                        return false;
                      }

                      // Kategori filtresi
                      if (_selectedCategories.isNotEmpty) {
                        final category = product['category'] ?? '';
                        if (!_selectedCategories.contains(category))
                          return false;
                      }

                      // Fiyat Filtresi
                      final price =
                          (product['price'] as num?)?.toDouble() ?? 0.0;
                      if (price < _priceRange.start ||
                          price > _priceRange.end) {
                        return false;
                      }

                      // Bugün Açık Filtresi
                      if (_filterOpenToday) {
                        final marketId = product['marketId'];
                        if (marketId == null) return false;

                        Market? market = _marketsMap[marketId];

                        if (market == null) {
                          try {
                            market = homeVM.nearbyMarkets
                                .firstWhere((m) => m.id == marketId);
                          } catch (_) {
                            try {
                              market = homeVM.provinceMarkets
                                  .firstWhere((m) => m.id == marketId);
                            } catch (_) {}
                          }
                        }

                        if (market == null) return false;

                        final todayMap = {
                          1: 'Pazartesi',
                          2: 'Salı',
                          3: 'Çarşamba',
                          4: 'Perşembe',
                          5: 'Cuma',
                          6: 'Cumartesi',
                          7: 'Pazar',
                        };
                        final today = todayMap[DateTime.now().weekday]!;

                        if (!market.openDays.contains(today)) return false;
                      }

                      return true;
                    }).toList();

                    if (products.isEmpty) {
                      final bool hasFilters = _searchQuery.isNotEmpty ||
                          _selectedCategories.isNotEmpty ||
                          _filterOpenToday ||
                          _priceRange.start > 0 ||
                          _priceRange.end < 2000;

                      return RefreshIndicator(
                        onRefresh: _refreshProducts,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      langVM.translate('no_results'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (hasFilters) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        langVM.translate(
                                            'no_products_found_filter'),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      OutlinedButton.icon(
                                        onPressed: _clearAllFilters,
                                        icon: const Icon(Icons.filter_list_off),
                                        label: Text(langVM
                                            .translate('clear_filters_button')),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // 2. Sıralama Mantığı
                    String? priorityMarketId;
                    double minDistance = double.infinity;

                    final todayMap = {
                      1: 'Pazartesi',
                      2: 'Salı',
                      3: 'Çarşamba',
                      4: 'Perşembe',
                      5: 'Cuma',
                      6: 'Cumartesi',
                      7: 'Pazar',
                    };
                    final today = todayMap[DateTime.now().weekday]!;

                    // HomeViewModel'deki pazarları tara
                    for (var market in homeVM.nearbyMarkets) {
                      if (market.openDays.contains(today)) {
                        if (market.distanceInMeters < minDistance) {
                          minDistance = market.distanceInMeters;
                          priorityMarketId = market.id;
                        }
                      }
                    }

                    if (_sortOption == 'newest') {
                      // Tarihe göre sırala (En yeni en üstte)
                      products.sort((a, b) {
                        final tA = a['createdAt'];
                        final tB = b['createdAt'];
                        if (tA is Timestamp && tB is Timestamp) {
                          return tB.compareTo(tA);
                        }
                        return 0;
                      });
                    } else {
                      // Akıllı Sıralama (Varsayılan)
                      products.sort((a, b) {
                        final marketIdA = a['marketId'];
                        final marketIdB = b['marketId'];

                        // Öncelikli pazar kontrolü
                        final isPriorityA = marketIdA == priorityMarketId;
                        final isPriorityB = marketIdB == priorityMarketId;

                        if (isPriorityA && !isPriorityB)
                          return -1; // A önce gelir
                        if (!isPriorityA && isPriorityB)
                          return 1; // B önce gelir

                        // İkisi de öncelikli değilse veya ikisi de öncelikliyse
                        // Pazara olan mesafeye göre sırala (HomeViewModel'den mesafe bul)
                        double distA = double.infinity;
                        double distB = double.infinity;

                        try {
                          final marketA = homeVM.nearbyMarkets
                              .firstWhere((m) => m.id == marketIdA);
                          distA = marketA.distanceInMeters;
                        } catch (_) {}

                        try {
                          final marketB = homeVM.nearbyMarkets
                              .firstWhere((m) => m.id == marketIdB);
                          distB = marketB.distanceInMeters;
                        } catch (_) {}

                        return distA.compareTo(distB);
                      });
                    }

                    return RefreshIndicator(
                      onRefresh: _refreshProducts,
                      child: GridView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.62,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final isPriority = priorityMarketId != null &&
                              product['marketId'] == priorityMarketId;

                          return ProductCard(
                            product: product,
                            isPriority: isPriority,
                            isFavorite:
                                _favoriteProductIds.contains(product['id']),
                            onFavoriteToggle: () async {
                              await AuthService.instance
                                  .toggleFavoriteProduct(product['id']);
                              _loadFavorites();
                            },
                            onDetailReturn: _loadFavorites,
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
