import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/product_card.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';
import '../../widgets/custom_bottom_sheets.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_snackbars.dart';

class CustomerSellerDetailScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String sellerDescription;
  final String stallLocation;
  final String stallHours;
  final String? instagramLink;
  final String? facebookLink;
  final String? instagramName;
  final String? facebookName;
  final String? profilePicture;
  final String? marketName;
  final String? highlightReviewId;

  const CustomerSellerDetailScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.sellerDescription,
    required this.stallLocation,
    required this.stallHours,
    this.instagramLink,
    this.facebookLink,
    this.instagramName,
    this.facebookName,
    this.profilePicture,
    this.marketName,
    this.highlightReviewId,
  });

  @override
  State<CustomerSellerDetailScreen> createState() =>
      _CustomerSellerDetailScreenState();
}

class _CustomerSellerDetailScreenState
    extends State<CustomerSellerDetailScreen> {
  bool _isFavorite = false;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  double _rating = 0.0;
  int _reviewCount = 0;
  List<Map<String, dynamic>> _reviews = [];
  bool _reviewsLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredProducts = [];
  final Map<String, GlobalKey> _reviewKeys = {};
  List<String> _favoriteProductIds = [];
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // Filtreleme Değişkenleri
  String _sortOption = 'newest'; // 'newest', 'price_asc', 'price_desc'
  List<String> _selectedCategories = [];
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

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _searchController.addListener(_applyFilters);
    _checkFavoriteStatus();
    _loadProducts();
    _loadReviews();
    _loadSellerStats();
    _loadFavoriteProducts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
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
            _searchController.text = val.recognizedWords;
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      var temp = _products.where((p) {
        // Arama Filtresi
        final name = (p['name'] ?? '').toString().toLowerCase();
        if (query.isNotEmpty && !name.contains(query)) return false;

        // Kategori Filtresi
        if (_selectedCategories.isNotEmpty) {
          final category = p['category'] ?? '';
          if (!_selectedCategories.contains(category)) return false;
        }

        // Fiyat Filtresi
        final price = (p['price'] as num?)?.toDouble() ?? 0.0;
        if (price < _priceRange.start || price > _priceRange.end) return false;

        return true;
      }).toList();

      // Sıralama
      if (_sortOption == 'price_asc') {
        temp.sort((a, b) => ((a['price'] as num?)?.toDouble() ?? 0)
            .compareTo((b['price'] as num?)?.toDouble() ?? 0));
      } else if (_sortOption == 'price_desc') {
        temp.sort((a, b) => ((b['price'] as num?)?.toDouble() ?? 0)
            .compareTo((a['price'] as num?)?.toDouble() ?? 0));
      } else if (_sortOption == 'newest') {
        temp.sort((a, b) {
          final tA = a['createdAt'];
          final tB = b['createdAt'];
          if (tA is Timestamp && tB is Timestamp) return tB.compareTo(tA);
          return 0;
        });
      }
      _filteredProducts = temp;
    });
  }

  Future<void> _loadFavoriteProducts() async {
    final favs = await AuthService.instance.getFavoriteProducts();
    if (mounted) {
      setState(() {
        _favoriteProductIds = favs;
      });
    }
  }

  Future<void> _loadSellerStats() async {
    try {
      final stats = await AuthService.instance.getSellerStats(widget.sellerId);
      if (mounted) {
        setState(() {
          _rating = (stats['averageRating'] as num).toDouble();
          _reviewCount = (stats['reviewCount'] as num).toInt();
        });
      }
    } catch (e) {
      debugPrint('Satıcı puanı yüklenemedi: $e');
    }
  }

  Future<void> _loadReviews() async {
    final reviews =
        await AuthService.instance.getSellerReviews(widget.sellerId);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _reviewsLoading = false;
      });

      if (widget.highlightReviewId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _scrollToHighlightedItem(widget.highlightReviewId!);
          });
        });
      }
    }
  }

  Future<void> _loadProducts() async {
    final products =
        await AuthService.instance.getSellerProducts(widget.sellerId);

    if (mounted) {
      setState(() {
        _products = products;
        _applyFilters(); // Filtreleri uygula (varsayılan sıralama vb.)
        _isLoading = false;
      });
    }
  }

  void _scrollToHighlightedItem(String id) {
    final key = _reviewKeys[id];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
        alignment: 0.5,
      );
    }
  }

  Future<void> _launchSocialLink(String url, {String? platform}) async {
    if (url.isEmpty) return;
    String finalUrl = url.trim();

    if (platform == 'instagram' && !finalUrl.contains('instagram.com')) {
      finalUrl = finalUrl.replaceAll('@', '');
      finalUrl = 'instagram.com/$finalUrl';
    } else if (platform == 'facebook' && !finalUrl.contains('facebook.com')) {
      finalUrl = 'facebook.com/$finalUrl';
    }

    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }
    final Uri uri = Uri.parse(finalUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Link açma hatası: $e');
    }
  }

  String _extractUsername(String url) {
    String username = url.trim();
    if (username.contains('instagram.com/')) {
      username = username.split('instagram.com/').last;
    } else if (username.contains('facebook.com/')) {
      username = username.split('facebook.com/').last;
    }
    username = username.replaceAll('/', '').replaceAll('@', '');
    return '@$username';
  }

  Future<void> _checkFavoriteStatus() async {
    final favorites = await AuthService.instance.getFavoriteSellers();
    if (mounted) {
      setState(() {
        _isFavorite = favorites.contains(widget.sellerId);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    await AuthService.instance.toggleFavoriteSeller(widget.sellerId);
    await _checkFavoriteStatus();
    if (mounted) {
      final langVM = Provider.of<LanguageViewModel>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(langVM.translate(_isFavorite
              ? 'seller_added_to_favorites'
              : 'seller_removed_from_favorites')),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showFilterBottomSheet() {
    // Geçici durum değişkenleri
    String tempSortOption = _sortOption;
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    List<String> tempSelectedCategories = List.from(_selectedCategories);
    RangeValues tempPriceRange = _priceRange;

    CustomBottomSheets.showDraggable(
      context: context,
      initialChildSize: 0.7,
      builder: (context, scrollController) => StatefulBuilder(
        builder: (context, setState) {
          return Column(
            children: [
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
                          _sortOption = 'newest';
                          _selectedCategories.clear();
                          _priceRange = const RangeValues(0, 2000);
                          _applyFilters();
                        });
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
                  controller: scrollController,
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
                        final isSelected = tempSelectedCategories.contains(cat);
                        return FilterChip(
                          label: Text(langVM.translate(cat)),
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
                          selectedColor: Theme.of(context).colorScheme.primary,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
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
                  ],
                ),
              ),
              // Uygula Butonu
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      this.setState(() {
                        _sortOption = tempSortOption;
                        _selectedCategories = tempSelectedCategories;
                        _priceRange = tempPriceRange;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(langVM.translate('show_results_button'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
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

  void _showAddReviewDialog() {
    final authVM = context.read<AuthViewModel>();
    if (!authVM.isAuthenticated) {
      authVM.checkGuestStatus(context);
      return;
    }

    final commentController = TextEditingController();
    int selectedRating = 0;

    CustomBottomSheets.showContent(
      context: context,
      title: 'Satıcıyı Değerlendir',
      icon: Icons.star_rate_rounded,
      child: StatefulBuilder(
        builder: (sheetContext, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext)
                      .colorScheme
                      .primary
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(sheetContext)
                        .colorScheme
                        .primary
                        .withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedRating = index + 1;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: AnimatedScale(
                          scale: selectedRating >= index + 1 ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            selectedRating >= index + 1
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 36,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: commentController,
              maxLines: 4,
              minLines: 3,
              style: TextStyle(
                color: Theme.of(sheetContext).textTheme.bodyLarge?.color,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                alignLabelWithHint: true,
                labelText: 'Yorumunuzu yazın...',
                labelStyle: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.primary),
                filled: true,
                fillColor: Theme.of(sheetContext).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.05),
                prefixIcon: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin:
                          const EdgeInsets.only(left: 12, right: 8, top: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(sheetContext)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.rate_review_rounded,
                          color: Theme.of(sheetContext).colorScheme.primary,
                          size: 20),
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                      color: Theme.of(sheetContext)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                      color: Theme.of(sheetContext)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                      color: Theme.of(sheetContext).colorScheme.primary,
                      width: 2),
                ),
              ),
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: 'Gönder',
              icon: Icons.send_rounded,
              onPressed: () async {
                if (selectedRating == 0) {
                  CustomSnackbars.showWarning(
                      sheetContext, 'Lütfen puan verin.');
                  return;
                }
                if (commentController.text.trim().isEmpty) {
                  CustomSnackbars.showWarning(
                      sheetContext, 'Lütfen yorum yazın.');
                  return;
                }

                final review = {
                  'sellerId': widget.sellerId,
                  'userId': authVM.currentUser!.id,
                  'rating': selectedRating,
                  'comment': commentController.text.trim(),
                  'date': DateTime.now().toIso8601String(),
                };

                Navigator.pop(sheetContext); // Dialog'u kapat

                try {
                  await AuthService.instance.addSellerReview(review);
                  _loadReviews(); // Yorumları yenile
                  _loadSellerStats(); // Puanı yenile
                  if (mounted) {
                    CustomSnackbars.showSuccess(
                        context, 'Değerlendirmeniz gönderildi.');
                  }
                } catch (e) {
                  debugPrint('Yorum eklenemedi: $e');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerInfo(BuildContext context, LanguageViewModel langVM) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 110, 16, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seller profile section
            Row(
              children: [
                // Profile picture
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  child: (widget.profilePicture != null &&
                          widget.profilePicture!.isNotEmpty)
                      ? (widget.profilePicture!.startsWith('http')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.network(
                                widget.profilePicture!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.people,
                                        color: Colors.grey),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.file(
                                File(widget.profilePicture!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.people,
                                        color: Colors.grey),
                              ),
                            ))
                      : const Icon(Icons.people, color: Colors.grey, size: 30),
                ),
                const SizedBox(width: 16),
                // Seller info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.sellerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$_rating ($_reviewCount ${langVM.translate('reviews')})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Description
            if (widget.sellerDescription.isNotEmpty) ...[
              Text(
                widget.sellerDescription,
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8)),
              ),
              const SizedBox(height: 12),
            ],
            // Location
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on,
                      size: 20, color: Theme.of(context).colorScheme.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.marketName != null ? '${widget.marketName} - ' : ''}${widget.stallLocation}',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                        fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Hours
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.access_time,
                      size: 20, color: Theme.of(context).colorScheme.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.stallHours,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                        fontSize: 13),
                  ),
                ),
              ],
            ),
            // Social links
            if ((widget.instagramLink != null &&
                    widget.instagramLink!.isNotEmpty) ||
                (widget.facebookLink != null &&
                    widget.facebookLink!.isNotEmpty)) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (widget.instagramLink != null &&
                      widget.instagramLink!.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF833AB4), Color(0xFFF56040)],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF833AB4).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () => _launchSocialLink(widget.instagramLink!,
                              platform: 'instagram'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SvgIcon(
                                    iconPath: AppIcons.instagram,
                                    size: 20,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  (widget.instagramName != null &&
                                          widget.instagramName!.isNotEmpty)
                                      ? widget.instagramName!
                                      : _extractUsername(widget.instagramLink!),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (widget.facebookLink != null &&
                      widget.facebookLink!.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1877F2),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1877F2).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () => _launchSocialLink(widget.facebookLink!,
                              platform: 'facebook'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SvgIcon(
                                    iconPath: AppIcons.facebook,
                                    size: 20,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  (widget.facebookName != null &&
                                          widget.facebookName!.isNotEmpty)
                                      ? widget.facebookName!
                                      : _extractUsername(widget.facebookLink!),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddReviewDialog,
                label: const Text('Satıcıyı Değerlendir',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF5F5F5),
      appBar: CustomAppBar(
        title: Text(langVM.translate('seller_details')),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CustomLoadingIndicator())
          : _products.isEmpty
              ? SingleChildScrollView(
                  padding: EdgeInsets.only(
                      bottom: 100 + MediaQuery.of(context).padding.bottom),
                  child: Column(
                    children: [
                      _buildSellerInfo(context, langVM),
                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          langVM.translate('no_products_added'),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                )
              : DefaultTabController(
                  length: 2,
                  initialIndex: widget.highlightReviewId != null ? 1 : 0,
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        SliverToBoxAdapter(
                          child: _buildSellerInfo(context, langVM),
                        ),
                        SliverPersistentHeader(
                          delegate: _SliverAppBarDelegate(
                            TabBar(
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              indicator: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: Theme.of(context).colorScheme.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                              labelStyle:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              splashBorderRadius: BorderRadius.circular(30),
                              padding: const EdgeInsets.all(4),
                              tabs: [
                                Tab(text: langVM.translate('products_tab')),
                                Tab(text: langVM.translate('reviews')),
                              ],
                            ),
                            Theme.of(context).cardColor,
                          ),
                          pinned: true,
                        ),
                      ];
                    },
                    body: TabBarView(
                      children: [
                        _buildProductsTab(context, langVM),
                        _buildReviewsTab(context, langVM),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProductsTab(BuildContext context, LanguageViewModel langVM) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: langVM.translate('search_hint'),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SvgIcon(
                          iconPath: AppIcons.search,
                          color: Theme.of(context).hintColor),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening
                              ? Colors.redAccent
                              : Theme.of(context).iconTheme.color),
                      onPressed: _listen,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.25)
                          : Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.filter_list),
                      if (_selectedCategories.isNotEmpty ||
                          _priceRange.start > 0 ||
                          _priceRange.end < 2000)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: _showFilterBottomSheet,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredProducts.isEmpty
              ? Center(
                  child: Text(
                    langVM.translate('no_products_found'),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                      16, 0, 16, 100 + MediaQuery.of(context).padding.bottom),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return ProductCard(
                      product: product,
                      isPriority: false,
                      isFavorite: _favoriteProductIds.contains(product['id']),
                      onFavoriteToggle: () async {
                        await AuthService.instance
                            .toggleFavoriteProduct(product['id']);
                        _loadFavoriteProducts();
                      },
                      onDetailReturn: _loadFavoriteProducts,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab(BuildContext context, LanguageViewModel langVM) {
    if (_reviewsLoading) {
      return const Center(child: CustomLoadingIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 100 + MediaQuery.of(context).padding.bottom),
      children: [
        if (_reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                langVM.translate('no_reviews_yet'),
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          ..._reviews.map((review) {
            final date = review['date'] != null
                ? DateTime.parse(review['date']).toString().split(' ')[0]
                : '';
            final isHighlighted = widget.highlightReviewId == review['id'];
            if (!_reviewKeys.containsKey(review['id'])) {
              _reviewKeys[review['id']] = GlobalKey();
            }

            return Container(
              key: _reviewKeys[review['id']],
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                    : (isDark ? Theme.of(context).cardColor : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isHighlighted
                      ? Theme.of(context).colorScheme.primary
                      : (isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            backgroundImage: (review['userImage'] != null &&
                                    review['userImage'].toString().isNotEmpty)
                                ? NetworkImage(review['userImage'])
                                : null,
                            child: (review['userImage'] == null ||
                                    review['userImage'].toString().isEmpty)
                                ? Text(
                                    (review['userName'] ?? 'K')[0]
                                        .toUpperCase(),
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review['userName'] ?? 'Kullanıcı',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index <
                                            ((review['rating'] as num?)
                                                    ?.toInt() ??
                                                0)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 14,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    review['comment'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _backgroundColor;

  _SliverAppBarDelegate(this._tabBar, this._backgroundColor);

  @override
  double get minExtent => _tabBar.preferredSize.height + 16;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 16;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: _backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(30),
            ),
            child: _tabBar,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
