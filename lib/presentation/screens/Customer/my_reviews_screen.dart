import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/market.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/custom_app_bar.dart';
import 'customer_seller_detail_screen.dart';
import 'market_detail_screen.dart';
import 'product_detail_screen.dart';
import '../../widgets/custom_bottom_sheets.dart';
import '../../../core/constants/app_icons.dart';
import '../../widgets/svg_icon.dart';
import '../../widgets/loading_overlay.dart';

class MyReviewsScreen extends StatefulWidget {
  final String? highlightReviewId;
  const MyReviewsScreen({super.key, this.highlightReviewId});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

enum ReviewView { menu, markets, sellers, products }

enum ReviewType { market, seller, product }

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<Map<String, dynamic>> _marketReviews = [];
  List<Map<String, dynamic>> _sellerReviews = [];
  List<Map<String, dynamic>> _productReviews = [];
  ReviewView _currentView = ReviewView.menu;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAllReviews();
  }

  Future<void> _loadAllReviews() async {
    final userId = context.read<AuthViewModel>().currentUser?.id;
    if (userId != null) {
      // Pazar yorumlarını Firestore'dan çek
      final marketReviews =
          await AuthService.instance.getUserMarketReviews(userId);
      // Satıcı yorumlarını çek
      final sellerReviews =
          await AuthService.instance.getUserSellerReviews(userId);
      // Ürün yorumlarını Firestore'dan çek
      final productReviews =
          await AuthService.instance.getUserProductReviews(userId);

      ReviewView targetView = _currentView;

      // Bildirimden gelindiyse ilgili yorumu bul, en başa taşı ve o sekmeyi aç
      if (widget.highlightReviewId != null) {
        // Pazar yorumlarında ara
        int mIndex = marketReviews
            .indexWhere((r) => r['id'] == widget.highlightReviewId);
        if (mIndex != -1) {
          final item = marketReviews.removeAt(mIndex);
          marketReviews.insert(0, item);
          targetView = ReviewView.markets;
        }

        // Satıcı yorumlarında ara
        int sIndex = sellerReviews
            .indexWhere((r) => r['id'] == widget.highlightReviewId);
        if (sIndex != -1) {
          final item = sellerReviews.removeAt(sIndex);
          sellerReviews.insert(0, item);
          targetView = ReviewView.sellers;
        }

        // Ürün yorumlarında ara
        int pIndex = productReviews
            .indexWhere((r) => r['id'] == widget.highlightReviewId);
        if (pIndex != -1) {
          final item = productReviews.removeAt(pIndex);
          productReviews.insert(0, item);
          targetView = ReviewView.products;
        }
      }

      if (mounted) {
        setState(() {
          _marketReviews = marketReviews;
          _sellerReviews = sellerReviews;
          _productReviews = productReviews;
          _currentView = targetView;
          _isLoading = false;
        });

        // Listeyi en başa kaydır
        if (widget.highlightReviewId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
          });
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReview(String reviewId, ReviewType type) async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final confirm = await CustomBottomSheets.showConfirmation(
      context: context,
      title: langVM.translate('delete_review_title'),
      message: langVM.translate('delete_review_confirm'),
      confirmText: langVM.translate('yes'),
      cancelText: langVM.translate('no'),
      iconPath: AppIcons.delete,
    );

    if (confirm == true) {
      if (type == ReviewType.market) {
        await AuthService.instance.deleteMarketReview(reviewId);
      } else if (type == ReviewType.seller) {
        await AuthService.instance.deleteSellerReview(reviewId);
      } else {
        await AuthService.instance.deleteProductReview(reviewId);
      }
      _loadAllReviews();
    }
  }

  void _navigateTo(ReviewView view) {
    setState(() {
      _currentView = view;
    });
  }

  void _goBack() {
    setState(() {
      _currentView = ReviewView.menu;
    });
  }

  String _getTitle(LanguageViewModel langVM) {
    switch (_currentView) {
      case ReviewView.markets:
        return 'Pazar Değerlendirmeleri';
      case ReviewView.sellers:
        return 'Satıcı Değerlendirmeleri';
      case ReviewView.products:
        return 'Ürün Değerlendirmeleri';
      case ReviewView.menu:
      default:
        return langVM.translate('my_reviews');
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();

    return PopScope(
      canPop: _currentView == ReviewView.menu,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: Text(_getTitle(langVM)),
          leading: _currentView != ReviewView.menu
              ? IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: Theme.of(context).colorScheme.primary),
                  onPressed: _goBack,
                )
              : null,
        ),
        body: _isLoading
            ? const Center(child: CustomLoadingIndicator())
            : _buildBody(context, langVM),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LanguageViewModel langVM) {
    switch (_currentView) {
      case ReviewView.markets:
        return _buildReviewList(
          context,
          _marketReviews,
          type: ReviewType.market,
          langVM: langVM,
        );
      case ReviewView.sellers:
        return _buildReviewList(
          context,
          _sellerReviews,
          type: ReviewType.seller,
          langVM: langVM,
        );
      case ReviewView.products:
        return _buildReviewList(
          context,
          _productReviews,
          type: ReviewType.product,
          langVM: langVM,
        );
      case ReviewView.menu:
      default:
        return _buildMenu(context);
    }
  }

  Widget _buildMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMenuButton(
            context,
            title: 'Pazar Değerlendirmeleri',
            icon: Icons.storefront,
            color: Colors.orange,
            onTap: () => _navigateTo(ReviewView.markets),
          ),
          const SizedBox(height: 16),
          _buildMenuButton(
            context,
            title: 'Satıcı Değerlendirmeleri',
            icon: Icons.people,
            color: Colors.blue,
            onTap: () => _navigateTo(ReviewView.sellers),
          ),
          const SizedBox(height: 16),
          _buildMenuButton(
            context,
            title: 'Ürün Değerlendirmeleri',
            iconPath: AppIcons.products,
            color: Colors.green,
            onTap: () => _navigateTo(ReviewView.products),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String title,
    IconData? icon,
    String? iconPath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Arka plan ikonu (Dekoratif)
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: iconPath != null
                      ? SvgIcon(
                          iconPath: iconPath,
                          size: 140,
                          color: Colors.white.withOpacity(0.15),
                        )
                      : Icon(
                          icon,
                          size: 140,
                          color: Colors.white.withOpacity(0.15),
                        ),
                ),
                // İçerik
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: iconPath != null
                            ? SvgIcon(
                                iconPath: iconPath,
                                size: 32,
                                color: Colors.white,
                              )
                            : Icon(icon, size: 32, color: Colors.white),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(ReviewType type, BuildContext context) {
    IconData icon;
    switch (type) {
      case ReviewType.market:
        icon = Icons.storefront;
        break;
      case ReviewType.seller:
        icon = Icons.people;
        break;
      case ReviewType.product:
        icon = Icons.shopping_basket;
        break;
    }
    return Icon(icon,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.5));
  }

  Widget _buildReviewList(
    BuildContext context,
    List<Map<String, dynamic>> reviews, {
    required ReviewType type,
    required LanguageViewModel langVM,
  }) {
    if (reviews.isEmpty) {
      IconData icon;
      switch (type) {
        case ReviewType.market:
          icon = Icons.storefront_outlined;
          break;
        case ReviewType.seller:
          icon = Icons.people_outline;
          break;
        case ReviewType.product:
          icon = Icons.shopping_basket_outlined;
          break;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              langVM.translate('no_reviews_yet'),
              style: TextStyle(
                  fontSize: 18,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      // AppBar yüksekliği kadar boşluk bırakıyoruz
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        String title = '';
        String? imageUrl;

        if (type == ReviewType.product) {
          title = review['productName'] ?? 'Ürün';
          imageUrl = review['productImage'];
        } else if (type == ReviewType.seller) {
          title = review['sellerName'] ?? 'Satıcı';
          imageUrl = review['sellerImage'];
        } else {
          title = review['marketName'] ?? 'Pazar';
        }

        final date = review['date'] != null
            ? DateTime.parse(review['date']).toString().split(' ')[0]
            : '';

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isHighlighted = review['id'] == widget.highlightReviewId;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isHighlighted
                ? (isDark
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                    : Colors.orange.shade50)
                : (isDark ? Theme.of(context).cardColor : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted
                  ? Theme.of(context).colorScheme.primary
                  : (isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1)),
              width: isHighlighted ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                if (type == ReviewType.market) {
                  final marketId = review['marketId'];
                  if (marketId != null) {
                    final homeVM = context.read<HomeViewModel>();
                    Market? market;
                    // Pazarı mevcut listelerden bulmaya çalış
                    try {
                      market = homeVM.nearbyMarkets
                          .firstWhere((m) => m.id == marketId);
                    } catch (_) {
                      try {
                        market = homeVM.provinceMarkets
                            .firstWhere((m) => m.id == marketId);
                      } catch (_) {
                        try {
                          market = homeVM.favoriteMarkets
                              .firstWhere((m) => m.id == marketId);
                        } catch (_) {}
                      }
                    }

                    if (market != null && mounted) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => MarketDetailScreen(
                                    market: market!,
                                    highlightReviewId: review['id'],
                                  )));
                    }
                  }
                } else if (type == ReviewType.seller) {
                  final sellerId = review['sellerId'];
                  if (sellerId != null) {
                    try {
                      // Satıcı detaylarını çek
                      final doc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(sellerId)
                          .get();
                      if (doc.exists && mounted) {
                        final data = doc.data()!;
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CustomerSellerDetailScreen(
                                      sellerId: sellerId,
                                      sellerName: data['stallName'] ??
                                          '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
                                      sellerDescription:
                                          data['stallDescription'] ?? '',
                                      stallLocation:
                                          data['stallLocation'] ?? '',
                                      stallHours: data['stallHours'] ?? '',
                                      instagramLink: data['instagramLink'],
                                      facebookLink: data['facebookLink'],
                                      profilePicture: data['profilePicture'],
                                      highlightReviewId: review['id'],
                                    )));
                      }
                    } catch (e) {
                      debugPrint('Satıcı bilgileri alınamadı: $e');
                    }
                  }
                } else if (type == ReviewType.product) {
                  if (review['product'] != null && mounted) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                                  product: review['product'],
                                  sellerName: review['sellerName'] ?? 'Satıcı',
                                  highlightReviewId: review['id'],
                                )));
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Resim veya İkon
                        Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.withOpacity(0.1),
                            border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withOpacity(0.1)),
                          ),
                          child: (imageUrl != null && imageUrl.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: imageUrl.startsWith('http')
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) =>
                                              _buildPlaceholderIcon(
                                                  type, context),
                                        )
                                      : Image.file(
                                          File(imageUrl),
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) =>
                                              _buildPlaceholderIcon(
                                                  type, context),
                                        ),
                                )
                              : _buildPlaceholderIcon(type, context),
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        date,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: SvgIcon(
                                          iconPath: AppIcons.delete,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                          size: 20,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () =>
                                            _deleteReview(review['id'], type),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (type == ReviewType.product &&
                                  review['sellerName'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    review['sellerName'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    starIndex < (review['rating'] as num)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      review['comment'] as String? ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                    // Satıcı yanıtı varsa göster
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
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.1),
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
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Satıcı Yanıtı',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              review['sellerReply'],
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
