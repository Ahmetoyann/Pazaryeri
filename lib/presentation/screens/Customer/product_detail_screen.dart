import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../../data/models/market.dart';
import 'seller_products_view_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/success_dialog.dart';
import 'customer_seller_detail_screen.dart';
import '../../widgets/custom_bottom_sheets.dart';
import '../../widgets/custom_snackbars.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String sellerName;
  final String? highlightReviewId;
  final String? highlightQuestionId;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.sellerName,
    this.highlightReviewId,
    this.highlightQuestionId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _allReviews = [];
  int _selectedRatingFilter = 0;
  bool _isFavorite = false;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  List<Map<String, dynamic>> _otherSellers = [];
  List<Map<String, dynamic>> _questions = [];
  final Map<String, GlobalKey> _reviewKeys = {};
  final Map<String, GlobalKey> _questionKeys = {};
  String? _sellerDescription;
  String? _marketName;
  Market? _market;
  Map<String, dynamic>? _sellerData;
  int _favoriteCount = 0;
  late TabController _tabController;
  List<String> _favoriteProductIds = [];
  late ScrollController _scrollController;
  bool _showTitle = false;

  final Map<String, Color> _categoryColors = {
    'category_fruit': Colors.orange,
    'category_vegetable': Colors.green,
    'category_delicatessen': Colors.redAccent,
    'category_dairy': Colors.blue,
    'category_bakery': Colors.amber,
    'category_spices': Colors.deepOrange,
    'category_fish': Colors.teal,
    'category_clothing': Colors.purple,
    'category_other': Colors.blueGrey,
    'category_electronics': Colors.blueGrey,
    'category_second_hand': Colors.brown,
    'category_animals': Colors.orangeAccent,
    'category_home': Colors.teal,
    'category_toys': Colors.pinkAccent,
    'category_books': Colors.indigo,
    'category_tools': Colors.grey,
    'category_plants': Colors.lightGreen,
    'category_handmade': Colors.purpleAccent,
    'category_cosmetics': Colors.pink,
    'category_sports': Colors.lightBlue,
    'category_automotive': Colors.red,
    'category_antiques': Colors.amberAccent,
    'category_jewelry': Colors.cyan,
    'category_art': Colors.deepPurple,
    'category_baby': Colors.lightBlueAccent,
    'category_music': Colors.deepOrangeAccent,
    'category_office': Colors.blueGrey,
  };

  final Map<String, String> _categoryPaths = {
    'category_fruit': AppIcons.fruit,
    'category_vegetable': AppIcons.vegetable,
    'category_delicatessen': AppIcons.delicatessen,
    'category_dairy': AppIcons.dairy,
    'category_bakery': AppIcons.bakery,
    'category_spices': AppIcons.spices,
    'category_fish': AppIcons.fish,
    'category_clothing': AppIcons.clothing,
    'category_other': AppIcons.other,
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
  };

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.highlightQuestionId != null ? 1 : 0,
    );
    _loadReviews();
    _loadOtherSellers();
    _loadQuestions();
    _loadSellerInfo();
    _loadMarketInfo();
    _checkFavoriteStatus();
    _loadFavoriteProducts();
    _loadFavoriteCount();

    // Görüntülenme sayısını artır (Sayfa açıldığında)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.product['id'] != null) {
        AuthService.instance.incrementProductViewCount(widget.product['id']);
      }
      if (widget.product['category'] != null) {
        AuthService.instance.addRecentCategory(widget.product['category']);
      }
    });
  }

  void _onScroll() {
    if (!mounted) return;
    final expandedHeight = MediaQuery.of(context).size.height * 0.5;
    final threshold = expandedHeight - kToolbarHeight - 20;

    if (_scrollController.hasClients) {
      if (_scrollController.offset > threshold && !_showTitle) {
        setState(() => _showTitle = true);
      } else if (_scrollController.offset <= threshold && _showTitle) {
        setState(() => _showTitle = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  double get _averageRating {
    if (_allReviews.isEmpty) return 0.0;
    final total = _allReviews.fold(
      0.0,
      (sum, item) => sum + ((item['rating'] as num?)?.toDouble() ?? 0.0),
    );
    return total / _allReviews.length;
  }

  Future<void> _loadReviews() async {
    final reviews =
        await AuthService.instance.getProductReviews(widget.product['id']);
    if (mounted) {
      setState(() {
        _allReviews = reviews;
        _applyFilter();
        _isLoading = false;
      });

      if (widget.highlightReviewId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _scrollToHighlightedItem(widget.highlightReviewId!, _reviewKeys);
          });
        });
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final favs = await AuthService.instance.getFavoriteProducts();
    if (mounted) {
      setState(() {
        _isFavorite = favs.contains(widget.product['id']);
      });
    }
  }

  Future<void> _loadFavoriteCount() async {
    final count = await AuthService.instance
        .getProductFavoriteCount(widget.product['id']);
    if (mounted) {
      setState(() {
        _favoriteCount = count;
      });
    }
  }

  Future<void> _loadFavoriteProducts() async {
    final favs = await AuthService.instance.getFavoriteProducts();
    if (mounted) {
      setState(() {
        _favoriteProductIds = favs;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final authVM = context.read<AuthViewModel>();
    if (await authVM.checkGuestStatus(context)) {
      await AuthService.instance.toggleFavoriteProduct(widget.product['id']);
      setState(() {
        _isFavorite = !_isFavorite;
        if (_isFavorite) {
          _favoriteCount++;
        } else {
          _favoriteCount = (_favoriteCount - 1).clamp(0, 999999);
        }
      });

      if (mounted) {
        CustomSnackbars.showSuccess(
          context,
          _isFavorite
              ? 'Ürün favorilere eklendi'
              : 'Ürün favorilerden çıkarıldı',
        );
      }
    }
  }

  Future<void> _shareProduct() async {
    final product = widget.product;
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final unit = langVM.translate(product['unit'] ?? 'unit_kg');

    final String storeLink = Platform.isIOS
        ? 'https://apps.apple.com/app/idYOUR_APP_ID' // Kendi App Store ID'niz ile değiştirin
        : 'https://play.google.com/store/apps/details?id=com.ahmed.pazaryeri';

    final String text =
        '${product['name']}\nFiyat: ${product['price']} ₺ / $unit\nSatıcı: ${widget.sellerName}\n\nPazaryeri uygulamasında incele!\nİndir: $storeLink';

    String? imagePath;
    if (product['images'] != null && (product['images'] as List).isNotEmpty) {
      imagePath = (product['images'] as List).first.toString();
    } else if (product['imagePath'] != null &&
        product['imagePath'].toString().isNotEmpty) {
      imagePath = product['imagePath'].toString();
    }

    if (imagePath != null) {
      try {
        XFile? fileToShare;
        await LoadingOverlay.show(
          context,
          asyncFunction: () async {
            if (imagePath!.startsWith('http')) {
              final uri = Uri.parse(imagePath);
              final response = await http.get(uri);
              final bytes = response.bodyBytes;
              final temp = await getTemporaryDirectory();
              final path = '${temp.path}/${uri.pathSegments.last}';
              final f = File(path);
              await f.writeAsBytes(bytes);
              fileToShare = XFile(path);
            } else {
              fileToShare = XFile(imagePath);
            }
          },
        );

        if (fileToShare != null) {
          await Share.shareXFiles([fileToShare!], text: text);
        } else {
          await Share.share(text);
        }
      } catch (e) {
        debugPrint('Paylaşım hatası: $e');
        await Share.share(text);
      }
    } else {
      await Share.share(text);
    }
  }

  void _applyFilter() {
    if (_selectedRatingFilter == 0) {
      _reviews = List.from(_allReviews);
    } else {
      _reviews = _allReviews.where((r) {
        final rating = r['rating'];
        return (rating is num) && rating.toInt() == _selectedRatingFilter;
      }).toList();
    }
  }

  Future<void> _loadOtherSellers() async {
    final sellers = await AuthService.instance.getSellersSellingProduct(
      widget.product['name'],
      widget.product['sellerId'],
    );
    if (mounted) {
      setState(() {
        _otherSellers = sellers;
      });
    }
  }

  Future<void> _loadQuestions() async {
    final questions =
        await AuthService.instance.getProductQuestions(widget.product['id']);
    if (mounted) {
      setState(() {
        _questions = questions;
      });

      if (widget.highlightQuestionId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _scrollToHighlightedItem(
                widget.highlightQuestionId!, _questionKeys);
          });
        });
      }
    }
  }

  Future<void> _loadSellerInfo() async {
    if (widget.product['sellerId'] != null) {
      final data = await AuthService.instance
          .refreshUserData(widget.product['sellerId']);
      if (mounted && data != null) {
        setState(() {
          _sellerData = data;
          _sellerDescription = data['stallDescription'];
        });
        // Satıcının güncel pazar bilgisini kullanarak market bilgisini yenile
        if (data['sellerMarketId'] != null &&
            data['sellerMarketId'].toString().isNotEmpty) {
          _loadMarketInfo(overrideMarketId: data['sellerMarketId']);
        }
      }
    }
  }

  Future<void> _loadMarketInfo({String? overrideMarketId}) async {
    final marketId = overrideMarketId ?? widget.product['marketId'];
    if (marketId != null) {
      try {
        final homeVM = Provider.of<HomeViewModel>(context, listen: false);
        final sellerVM = Provider.of<SellerViewModel>(context, listen: false);
        Market? foundMarket;

        // 1. Mesafe bilgisi için HomeViewModel'e bak
        try {
          foundMarket =
              homeVM.nearbyMarkets.firstWhere((m) => m.id == marketId);
        } catch (_) {
          try {
            foundMarket =
                homeVM.provinceMarkets.firstWhere((m) => m.id == marketId);
          } catch (_) {}
        }

        // 2. Bulunamazsa SellerViewModel'den tüm pazarlara bak
        if (foundMarket == null) {
          final markets = await sellerVM.getMarkets();
          try {
            foundMarket = markets.firstWhere((m) => m.id == marketId);
          } catch (_) {}
        }

        if (foundMarket != null && mounted) {
          setState(() {
            _market = foundMarket;
            _marketName = foundMarket!.name;
          });
        }
      } catch (e) {
        debugPrint('Pazar bilgisi yüklenemedi: $e');
      }
    }
  }

  Future<void> _openMap() async {
    if (_market == null) return;
    final lat = _market!.address.latitude;
    final lng = _market!.address.longitude;
    final uri =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Harita açılamadı');
      }
    } catch (e) {
      debugPrint('Harita açılırken hata oluştu: $e');
    }
  }

  void _scrollToHighlightedItem(String id, Map<String, GlobalKey> keys) {
    final key = keys[id];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
        alignment: 0.5,
      );
    } else {
      // Eğer ilk denemede bulunamazsa (render gecikmesi), kısa süre sonra tekrar dene
      Future.delayed(const Duration(milliseconds: 500), () {
        final retryKey = keys[id];
        if (retryKey != null && retryKey.currentContext != null) {
          Scrollable.ensureVisible(
            retryKey.currentContext!,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
            alignment: 0.5,
          );
        }
      });
    }
  }

  Future<void> _showAddReviewDialog() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    final commentController = TextEditingController();
    int rating = 0;
    XFile? reviewImage;
    final ImagePicker picker = ImagePicker();

    await CustomBottomSheets.showContent(
      context: context,
      title: langVM.translate('add_review'),
      child: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      iconSize: 40,
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () => setState(() => rating = index + 1),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: langVM.translate('write_review_hint'),
                  hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 70,
                        maxWidth: 1024,
                      );
                      if (image != null) {
                        setState(() => reviewImage = image);
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Fotoğraf Ekle'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (reviewImage != null) ...[
                    const SizedBox(width: 8),
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(reviewImage!.path),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => reviewImage = null),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const SvgIcon(
                                iconPath: AppIcons.close,
                                color: Colors.red,
                                size: 20),
                          ),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: langVM.translate('send_button'),
                onPressed: () async {
                  if (rating == 0) {
                    CustomSnackbars.showWarning(
                      context,
                      langVM.translate('please_rate'),
                    );
                    return;
                  }
                  if (commentController.text.trim().isEmpty) return;

                  String? imageUrl;
                  if (reviewImage != null) {
                    // Yükleme işlemi
                    imageUrl = await AuthService.instance
                        .uploadReviewImage(File(reviewImage!.path));
                  }

                  final newReview = {
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'productId': widget.product['id'],
                    'sellerId': widget.product['sellerId'],
                    'userId': authVM.currentUser?.id ?? 'guest',
                    'userName':
                        '${authVM.currentUser?.firstName} ${authVM.currentUser?.lastName}',
                    'userProfilePicture':
                        authVM.currentUser?.profilePicturePath,
                    'rating': rating,
                    'comment': commentController.text.trim(),
                    'date': DateTime.now().toIso8601String(),
                    'imageUrl': imageUrl,
                  };

                  await AuthService.instance.addProductReview(newReview);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadReviews();
                    await DialogService.showSuccess(
                      context,
                      message: langVM.translate('review_success'),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAskQuestionDialog() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final questionController = TextEditingController();

    await CustomBottomSheets.showContent(
      context: context,
      title: 'Soru Sor',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: questionController,
            decoration: InputDecoration(
              hintText: 'Sorunuzu buraya yazın...',
              hintStyle: TextStyle(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3)),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: langVM.translate('send_button'),
            onPressed: () async {
              if (questionController.text.trim().isEmpty) return;

              final newQuestion = {
                'productId': widget.product['id'],
                'productName': widget.product['name'],
                'productImage': widget.product['imagePath'],
                'userId': authVM.currentUser?.id ?? 'guest',
                'userName':
                    '${authVM.currentUser?.firstName} ${authVM.currentUser?.lastName}',
                'userProfilePicture': authVM.currentUser?.profilePicturePath,
                'question': questionController.text.trim(),
                'date': DateTime.now().toIso8601String(),
              };

              await AuthService.instance.askProductQuestion(newQuestion);
              if (mounted) {
                Navigator.pop(context);
                _loadQuestions();
                await DialogService.showSuccess(
                  context,
                  message: 'Sorunuz başarıyla gönderildi.',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showMarketSellers() {
    // Ürünün ait olduğu market ID'si (Veride yoksa varsayılan '1' atanır)
    final String marketId =
        _market?.id ?? widget.product['marketId']?.toString() ?? '1';

    CustomBottomSheets.showDraggable(
      context: context,
      initialChildSize: 0.5,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Pazardaki Satıcılar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: AuthService.instance.getMarketSellers(marketId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CustomLoadingIndicator(size: 50));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Hata: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Satıcı bulunamadı.'));
                  }

                  final sellers = snapshot.data!;
                  return ListView.separated(
                    controller: scrollController,
                    itemCount: sellers.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final seller = sellers[index];
                      final displayName = seller['stallName'] ??
                          '${seller['firstName'] ?? ''} ${seller['lastName'] ?? ''}'
                              .trim();
                      final rating = seller['rating'] ?? 0.0;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1),
                          child: Text(
                              displayName.isNotEmpty ? displayName[0] : '?',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor)),
                        ),
                        title: Text(displayName),
                        subtitle: Row(
                          children: [
                            const Icon(Icons.star,
                                size: 16, color: Colors.amber),
                            Text(' $rating'),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SellerProductsViewScreen(seller: seller),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showOtherSellers() {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    CustomBottomSheets.showContent(
        context: context,
        title: 'Bu Ürünü Satan Diğer Satıcılar',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _otherSellers.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final seller = _otherSellers[index];
                  final displayName = seller['stallName'] ??
                      '${seller['firstName']} ${seller['lastName']}';
                  final price = seller['productPrice'];
                  final unit = seller['productUnit'];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (seller['profilePicture'] != null &&
                              seller['profilePicture'].isNotEmpty)
                          ? NetworkImage(seller['profilePicture'])
                          : null,
                      child: (seller['profilePicture'] == null ||
                              seller['profilePicture'].isEmpty)
                          ? Text(displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?')
                          : null,
                    ),
                    title: Text(displayName),
                    subtitle: Text(
                      'Fiyat: $price ₺ / ${langVM.translate(unit ?? 'unit_kg')}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context); // Sheet'i kapat
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerSellerDetailScreen(
                            sellerId: seller['id'],
                            sellerName: displayName,
                            sellerDescription: seller['stallDescription'] ?? '',
                            stallLocation: seller['stallLocation'] ?? '',
                            stallHours: seller['stallHours'] ?? '',
                            instagramLink: seller['instagramLink'],
                            facebookLink: seller['facebookLink'],
                            instagramName: seller['instagramName'],
                            facebookName: seller['facebookName'],
                            profilePicture: seller['profilePicture'],
                            marketName: _marketName,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ));
  }

  Widget _buildSimilarProductsSection() {
    final currentCategory = widget.product['category'];
    final currentProductId = widget.product['id'];
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            'Bunlara da Bakabilirsin',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 260,
          child: FutureBuilder<List<String>>(
            future: AuthService.instance.getRecentCategories(),
            builder: (context, categorySnapshot) {
              List<String> categoriesToQuery = [currentCategory];

              if (categorySnapshot.hasData &&
                  categorySnapshot.data!.isNotEmpty) {
                categoriesToQuery = List.from(categorySnapshot.data!);
                if (!categoriesToQuery.contains(currentCategory)) {
                  categoriesToQuery.insert(0, currentCategory);
                }
              }

              if (categoriesToQuery.length > 10) {
                categoriesToQuery = categoriesToQuery.sublist(0, 10);
              }

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('products')
                    .where('category', whereIn: categoriesToQuery)
                    .limit(10)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CustomLoadingIndicator(size: 50));
                  }

                  Widget buildEmptyState() {
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.manage_search,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            langVM.translate('no_similar_products'),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return buildEmptyState();
                  }

                  final products = snapshot.data!.docs
                      .map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        data['id'] = doc.id;
                        return data;
                      })
                      .where((p) => p['id'] != currentProductId)
                      .toList();

                  // Karıştırarak çeşitlilik sağla
                  products.shuffle();

                  if (products.isEmpty) {
                    return buildEmptyState();
                  }

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) => SizedBox(
                      width: 140,
                      child: ProductCard(
                        product: products[index],
                        isFavorite:
                            _favoriteProductIds.contains(products[index]['id']),
                        onFavoriteToggle: () async {
                          await AuthService.instance
                              .toggleFavoriteProduct(products[index]['id']);
                          _loadFavoriteProducts();
                        },
                        onDetailReturn: _loadFavoriteProducts,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteReview(
    BuildContext context,
    String reviewId,
  ) async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final confirm = await CustomBottomSheets.showConfirmation(
      context: context,
      title: 'Yorumu Sil',
      message: 'Bu yorumu silmek istediğinize emin misiniz?',
      confirmText: langVM.translate('yes'),
      cancelText: langVM.translate('no'),
      iconPath: AppIcons.delete,
    );

    if (confirm == true) {
      await AuthService.instance.deleteProductReview(reviewId);
      _loadReviews();
    }
  }

  Future<void> _confirmDeleteQuestion(
    String questionId,
  ) async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final confirm = await CustomBottomSheets.showConfirmation(
      context: context,
      title: 'Soruyu Sil',
      message: 'Bu soruyu silmek istediğinize emin misiniz?',
      confirmText: langVM.translate('yes'),
      cancelText: langVM.translate('no'),
      iconPath: AppIcons.delete,
    );

    if (confirm == true) {
      await AuthService.instance.deleteProductQuestion(questionId);
      _loadQuestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final product = widget.product;
    final bool inStock = product['inStock'];
    final double stockQuantity =
        (product['stockQuantity'] as num?)?.toDouble() ?? 0;
    final bool isLowStock = inStock && stockQuantity > 0 && stockQuantity < 5;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? Colors.white : Theme.of(context).colorScheme.primary;
    final contentColor = isDark ? Colors.black : Colors.white;

    bool isMarketOpen = false;
    if (_market != null) {
      final todayIndex = DateTime.now().weekday;
      final daysMap = {
        1: 'Pazartesi',
        2: 'Salı',
        3: 'Çarşamba',
        4: 'Perşembe',
        5: 'Cuma',
        6: 'Cumartesi',
        7: 'Pazar',
      };
      final todayName = daysMap[todayIndex];
      isMarketOpen = _market!.openDays.contains(todayName);
    }

    // Kategoriye göre stil belirle
    final category = product['category'] as String? ?? 'category_other';
    final categoryColor =
        _categoryColors[category] ?? Theme.of(context).primaryColor;
    final categoryPath = _categoryPaths[category] ?? AppIcons.other;

    final List<String> images = [];
    if (product['images'] != null && (product['images'] as List).isNotEmpty) {
      images.addAll((product['images'] as List).map((e) => e.toString()));
    } else if (product['imagePath'] != null &&
        product['imagePath'].toString().isNotEmpty) {
      images.add(product['imagePath'].toString());
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: CustomAppBar(
        title: _showTitle ? Text(product['name']) : const SizedBox.shrink(),
        backgroundColor: _showTitle ? null : Colors.transparent,
        elevation: _showTitle ? 2 : 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            onPressed: _shareProduct,
          ),
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
          : NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: images.isNotEmpty
                                ? PageView.builder(
                                    itemCount: images.length,
                                    onPageChanged: (index) {
                                      setState(
                                          () => _currentImageIndex = index);
                                    },
                                    itemBuilder: (context, index) {
                                      final img = images[index];
                                      return GestureDetector(
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  _FullScreenImageGallery(
                                                images: images,
                                                initialIndex:
                                                    _currentImageIndex,
                                                product: product,
                                                sellerName: widget.sellerName,
                                              ),
                                            ),
                                          );
                                          _checkFavoriteStatus();
                                          _loadFavoriteCount();
                                        },
                                        child: Hero(
                                          tag: 'product_image_${product['id']}',
                                          child: img.startsWith('http')
                                              ? Image.network(
                                                  img,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Container(
                                                      color: categoryColor
                                                          .withOpacity(0.1),
                                                      child: Center(
                                                        child: SvgIcon(
                                                            iconPath:
                                                                categoryPath,
                                                            size: 64,
                                                            color: categoryColor
                                                                .withOpacity(
                                                                    0.5)),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Image.file(
                                                  File(img),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Container(
                                                    color: categoryColor
                                                        .withOpacity(0.1),
                                                    child: Center(
                                                      child: SvgIcon(
                                                          iconPath:
                                                              categoryPath,
                                                          size: 64,
                                                          color: categoryColor
                                                              .withOpacity(
                                                                  0.5)),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: categoryColor.withOpacity(0.1),
                                    child: Center(
                                      child: SvgIcon(
                                          iconPath: categoryPath,
                                          size: 100,
                                          color:
                                              categoryColor.withOpacity(0.5)),
                                    ),
                                  ),
                          ),
                          if (images.length > 1)
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(images.length, (index) {
                                  return Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentImageIndex == index
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.white.withOpacity(0.8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
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
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product['name'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _tabController.animateTo(0),
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                            left: 8, top: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SvgIcon(
                                                iconPath: AppIcons.star,
                                                color: Colors.amber,
                                                size: 18),
                                            const SizedBox(width: 4),
                                            Text(
                                              _averageRating.toStringAsFixed(1),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${product['price']} ₺ / ${langVM.translate(product['unit'] ?? 'unit_kg')}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isLowStock
                                            ? Colors.orange.withOpacity(0.1)
                                            : (inStock
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.red.withOpacity(0.1)),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isLowStock
                                              ? Colors.orange
                                              : (inStock
                                                  ? Colors.green
                                                      .withOpacity(0.5)
                                                  : Colors.red
                                                      .withOpacity(0.5)),
                                        ),
                                      ),
                                      child: Text(
                                        isLowStock
                                            ? '${langVM.translate('critical_stock')} (${stockQuantity % 1 == 0 ? stockQuantity.toInt() : stockQuantity} ${langVM.translate(product['unit'] ?? 'unit_kg')})'
                                            : langVM.translate(inStock
                                                ? 'in_stock'
                                                : 'out_of_stock'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isLowStock
                                              ? FontWeight.bold
                                              : null,
                                          color: isLowStock
                                              ? Colors.orange
                                              : (inStock
                                                  ? Colors.green
                                                  : Colors.red),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (product['description'] != null &&
                                    product['description']
                                        .toString()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    product['description'],
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.8),
                                          height: 1.5,
                                        ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.people,
                                          size: 20,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          if (_sellerData != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CustomerSellerDetailScreen(
                                                  sellerId: _sellerData!['id'],
                                                  sellerName: _sellerData![
                                                          'stallName'] ??
                                                      widget.sellerName,
                                                  sellerDescription: _sellerData![
                                                          'stallDescription'] ??
                                                      '',
                                                  stallLocation: '',
                                                  stallHours: _sellerData![
                                                          'stallHours'] ??
                                                      '',
                                                  instagramLink: _sellerData![
                                                      'instagramLink'],
                                                  facebookLink: _sellerData![
                                                      'facebookLink'],
                                                  instagramName: _sellerData![
                                                      'instagramName'],
                                                  facebookName: _sellerData![
                                                      'facebookName'],
                                                  profilePicture: _sellerData![
                                                      'profilePicture'],
                                                  marketName: _marketName ?? '',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            Text(
                                              widget.sellerName,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Icon(Icons.launch,
                                                size: 15,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_marketName != null) ...[
                                  const SizedBox(height: 12),
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
                                        child: Icon(Icons.storefront,
                                            size: 20,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _marketName!,
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.8)),
                                        ),
                                      ),
                                      if (_market != null &&
                                          _market!.distanceInMeters > 0) ...[
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.near_me,
                                              size: 14,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${(_market!.distanceInMeters / 1000).toStringAsFixed(1)} km',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                                if (_sellerDescription != null &&
                                    _sellerDescription!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.location_on,
                                            size: 20,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _sellerDescription!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.8),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                      if (_market != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isMarketOpen
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.red.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                              color: isMarketOpen
                                                  ? Colors.green
                                                      .withOpacity(0.5)
                                                  : Colors.red.withOpacity(0.5),
                                            ),
                                          ),
                                          child: Text(
                                            langVM.translate(isMarketOpen
                                                ? 'market_open_status'
                                                : 'market_closed_status'),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isMarketOpen
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_market != null) ...[
                            Container(
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
                              child: SizedBox(
                                width: double.infinity,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _openMap,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 16),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.directions,
                                                    color: Colors.white),
                                                const SizedBox(width: 8),
                                                Text(
                                                  langVM.translate(
                                                      'get_directions'),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Container(
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
                              children: [
                                if (_otherSellers.isNotEmpty) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _showOtherSellers,
                                      icon: const Icon(Icons.compare_arrows),
                                      label: Text(
                                          '${_otherSellers.length} Satıcıda Daha Var - Fiyatları Gör'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                _buildSimilarProductsSection(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
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
                          Tab(text: langVM.translate('reviews_tab')),
                          Tab(text: langVM.translate('questions_title')),
                        ],
                      ),
                      Theme.of(context).scaffoldBackgroundColor,
                    ),
                    pinned: true,
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildReviewsTab(
                      context, langVM, authVM, backgroundColor, contentColor),
                  _buildQuestionsTab(context, langVM, authVM),
                ],
              ),
            ),
    );
  }

  Widget _buildReviewsTab(BuildContext context, LanguageViewModel langVM,
      AuthViewModel authVM, Color backgroundColor, Color contentColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CustomButton(
          text: langVM.translate('add_review'),
          onPressed: () async {
            if (await authVM.checkGuestStatus(context)) {
              _showAddReviewDialog();
            }
          },
        ),
        const SizedBox(height: 16),
        if (_reviews.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    langVM.translate('no_reviews_for_product'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reviews.length,
                itemBuilder: (context, index) {
                  final review = _reviews[index];
                  final isHighlighted =
                      widget.highlightReviewId == review['id'];

                  if (!_reviewKeys.containsKey(review['id'])) {
                    _reviewKeys[review['id']] = GlobalKey();
                  }

                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;

                  return Container(
                    key: _reviewKeys[review['id']],
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.05)
                          : (isDark
                              ? Theme.of(context).cardColor
                              : Colors.white),
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
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
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
                                  radius: 24,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  backgroundImage:
                                      (review['userProfilePicture'] != null &&
                                              review['userProfilePicture']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? NetworkImage(
                                              review['userProfilePicture'])
                                          : null,
                                  child:
                                      (review['userProfilePicture'] == null ||
                                              review['userProfilePicture']
                                                  .toString()
                                                  .isEmpty)
                                          ? Text(
                                              (review['userName'] ?? 'M')[0]
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
                                Text(
                                  review['userName'] ??
                                      langVM.translate('guest_user_title'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                ...List.generate(5, (starIndex) {
                                  return Icon(
                                    starIndex < (review['rating'] as int)
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: Colors.amber,
                                  );
                                }),
                                if (review['userId'] == authVM.currentUser?.id)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: GestureDetector(
                                      onTap: () => _confirmDeleteReview(
                                          context, review['id']),
                                      child: const SvgIcon(
                                        iconPath: AppIcons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(review['comment'] ?? ''),
                        const SizedBox(height: 4),
                        if (review['imageUrl'] != null &&
                            review['imageUrl'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Scaffold(
                                    backgroundColor: Colors.black,
                                    appBar: AppBar(
                                        backgroundColor: Colors.black,
                                        iconTheme: const IconThemeData(
                                            color: Colors.white)),
                                    body: Center(
                                      child: InteractiveViewer(
                                        child:
                                            Image.network(review['imageUrl']),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(review['imageUrl'],
                                  height: 100, fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review['date'] != null
                                  ? DateTime.parse(review['date'])
                                      .toString()
                                      .split(' ')[0]
                                  : '',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5)),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    if (authVM.currentUser == null) return;
                                    if (review['id'] == null) return;

                                    await AuthService.instance
                                        .toggleProductReviewLike(
                                      review['id'],
                                      authVM.currentUser!.id,
                                    );
                                    _loadReviews();
                                  },
                                  child: Icon(
                                    (review['likes'] as List?)?.contains(
                                                authVM.currentUser?.id) ==
                                            true
                                        ? Icons.thumb_up
                                        : Icons.thumb_up_outlined,
                                    size: 16,
                                    color: (review['likes'] as List?)?.contains(
                                                authVM.currentUser?.id) ==
                                            true
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(review['likes'] as List?)?.length ?? 0}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (review['sellerReply'] != null &&
                            review['sellerReply'].toString().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: 16,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      langVM.translate('seller_reply_label'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  review['sellerReply'],
                                  style: const TextStyle(fontSize: 13),
                                ),
                                if (review['replyDate'] != null)
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        review['replyDate'] is Timestamp
                                            ? () {
                                                final dt = (review['replyDate']
                                                        as Timestamp)
                                                    .toDate();
                                                return '${dt.day}.${dt.month}.${dt.year}';
                                              }()
                                            : '',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildQuestionsTab(
      BuildContext context, LanguageViewModel langVM, AuthViewModel authVM) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CustomButton(
          text: langVM.translate('ask_question_title'),
          onPressed: () async {
            final authVM = context.read<AuthViewModel>();
            if (await authVM.checkGuestStatus(context)) {
              _showAskQuestionDialog();
            }
          },
        ),
        const SizedBox(height: 16),
        if (_questions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                langVM.translate('no_questions_yet_simple'),
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  final isCurrentUser = question['userId'] != null &&
                      question['userId'] == authVM.currentUser?.id;
                  final isHighlighted =
                      widget.highlightQuestionId == question['id'];

                  if (!_questionKeys.containsKey(question['id'])) {
                    _questionKeys[question['id']] = GlobalKey();
                  }

                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;

                  return Container(
                    key: _questionKeys[question['id']],
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.05)
                          : (isDark
                              ? Theme.of(context).cardColor
                              : Colors.white),
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
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
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
                                  radius: 24,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  backgroundImage:
                                      (question['userProfilePicture'] != null &&
                                              question['userProfilePicture']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? NetworkImage(
                                              question['userProfilePicture'])
                                          : null,
                                  child:
                                      (question['userProfilePicture'] == null ||
                                              question['userProfilePicture']
                                                  .toString()
                                                  .isEmpty)
                                          ? Text(
                                              (question['userName'] ?? 'M')[0]
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
                                Text(
                                  question['userName'] ??
                                      langVM.translate('guest_user_title'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  question['date'] != null
                                      ? DateTime.parse(question['date'])
                                          .toString()
                                          .split(' ')[0]
                                      : '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5),
                                  ),
                                ),
                                if (isCurrentUser)
                                  IconButton(
                                    icon: const SvgIcon(
                                      iconPath: AppIcons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () =>
                                        _confirmDeleteQuestion(question['id']),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(question['question'] ?? ''),
                        if (question['sellerReply'] != null &&
                            question['sellerReply'].toString().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: 16,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      langVM.translate('seller_reply_label'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  question['sellerReply'],
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        const SizedBox(height: 80),
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
    return Container(
      color: _backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: _tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _FullScreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final Map<String, dynamic> product;
  final String sellerName;

  const _FullScreenImageGallery({
    required this.images,
    required this.initialIndex,
    required this.product,
    required this.sellerName,
  });

  @override
  State<_FullScreenImageGallery> createState() =>
      _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<_FullScreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, TransformationController> _transformationControllers = {};
  bool _isFavorite = false;
  bool _showControls = true;
  final ScrollController _thumbnailScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final favs = await AuthService.instance.getFavoriteProducts();
    if (mounted) {
      setState(() {
        _isFavorite = favs.contains(widget.product['id']);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final authVM = context.read<AuthViewModel>();
    if (await authVM.checkGuestStatus(context)) {
      await AuthService.instance.toggleFavoriteProduct(widget.product['id']);
      setState(() {
        _isFavorite = !_isFavorite;
      });

      if (mounted) {
        if (_isFavorite) {
          CustomSnackbars.showSuccess(context, 'Ürün favorilere eklendi');
        } else {
          CustomSnackbars.showUndo(
            context,
            'Ürün favorilerden çıkarıldı',
            () async {
              await AuthService.instance
                  .toggleFavoriteProduct(widget.product['id']);
              if (mounted) {
                setState(() => _isFavorite = true);
              }
            },
          );
        }
      }
    }
  }

  Future<void> _shareProduct() async {
    final product = widget.product;
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final unit = langVM.translate(product['unit'] ?? 'unit_kg');

    final String storeLink = Platform.isIOS
        ? 'https://apps.apple.com/app/idYOUR_APP_ID' // Kendi App Store ID'niz ile değiştirin
        : 'https://play.google.com/store/apps/details?id=com.ahmed.pazaryeri';

    final String text =
        '${product['name']}\nFiyat: ${product['price']} ₺ / $unit\nSatıcı: ${widget.sellerName}\n\nPazaryeri uygulamasında incele!\nİndir: $storeLink';

    String imagePath = widget.images[_currentIndex];

    try {
      XFile? fileToShare;
      await LoadingOverlay.show(
        context,
        asyncFunction: () async {
          if (imagePath.startsWith('http')) {
            final uri = Uri.parse(imagePath);
            final response = await http.get(uri);
            final bytes = response.bodyBytes;
            final temp = await getTemporaryDirectory();
            final path = '${temp.path}/${uri.pathSegments.last}';
            final f = File(path);
            await f.writeAsBytes(bytes);
            fileToShare = XFile(path);
          } else {
            fileToShare = XFile(imagePath);
          }
        },
      );

      if (fileToShare != null) {
        await Share.shareXFiles([fileToShare!], text: text);
      } else {
        await Share.share(text);
      }
    } catch (e) {
      debugPrint('Paylaşım hatası: $e');
      await Share.share(text);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbnailScrollController.dispose();
    for (var controller in _transformationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleDoubleTap(int index) {
    final controller = _transformationControllers[index];
    if (controller == null) return;

    if (controller.value != Matrix4.identity()) {
      controller.value = Matrix4.identity();
    } else {
      // Merkeze 2x zoom yap
      controller.value = Matrix4.identity()..scale(2.0);
    }
  }

  void _scrollToThumbnail(int index) {
    if (!_thumbnailScrollController.hasClients) return;
    const double itemSize = 70.0; // 60 width + 10 margin
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scrollOffset =
        (index * itemSize) - (screenWidth / 2) + (itemSize / 2);

    _thumbnailScrollController.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Dismissible(
        key: const Key('fullscreen_gallery_dismiss'),
        direction: DismissDirection.vertical,
        onDismissed: (_) => Navigator.of(context).pop(),
        background: const ColoredBox(color: Colors.transparent),
        child: Stack(
          children: [
            // Görsel Slider
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  // Sayfa değiştiğinde diğer sayfaların zoomunu sıfırla
                  _transformationControllers.forEach((key, controller) {
                    if (key != index) {
                      controller.value = Matrix4.identity();
                    }
                  });
                });
                _scrollToThumbnail(index);
              },
              itemBuilder: (context, index) {
                final img = widget.images[index];

                if (!_transformationControllers.containsKey(index)) {
                  _transformationControllers[index] =
                      TransformationController();
                }

                return GestureDetector(
                  onTap: () => setState(() => _showControls = !_showControls),
                  onDoubleTap: () => _handleDoubleTap(index),
                  child: InteractiveViewer(
                    transformationController: _transformationControllers[index],
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Center(
                      child: img.startsWith('http')
                          ? Image.network(img, fit: BoxFit.contain)
                          : Image.file(File(img), fit: BoxFit.contain),
                    ),
                  ),
                );
              },
            ),

            // Üst Kontrol Barı (Kapatma ve Sayaç)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showControls ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                      bottom: 10,
                      left: 16,
                      right: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Kapatma Butonu
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const SvgIcon(
                                iconPath: AppIcons.close,
                                color: Colors.white,
                                size: 24),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.ios_share_rounded,
                                  color: Colors.white),
                              onPressed: _shareProduct,
                            ),
                            IconButton(
                              icon: Icon(
                                  _isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      _isFavorite ? Colors.red : Colors.white),
                              onPressed: _toggleFavorite,
                            ),
                            const SizedBox(width: 8),
                            // Sayaç
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_currentIndex + 1} / ${widget.images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
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
            ),

            // Alt İndikatör (Thumbnails)
            if (widget.images.length > 1)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _showControls ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: SizedBox(
                      height: 60,
                      child: ListView.separated(
                        controller: _thumbnailScrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.images.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final img = widget.images[index];
                          final isSelected = _currentIndex == index;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                border: isSelected
                                    ? Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        width: 2)
                                    : Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: img.startsWith('http')
                                    ? Image.network(img, fit: BoxFit.cover)
                                    : Image.file(File(img), fit: BoxFit.cover),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
