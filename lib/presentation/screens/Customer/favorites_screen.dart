import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../widgets/market_card.dart';
import 'market_detail_screen.dart';
import 'product_detail_screen.dart';
import '../../widgets/product_card.dart';
import 'customer_seller_detail_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_snackbars.dart';

enum FavoriteView { menu, markets, sellers, products }

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  FavoriteView _currentView = FavoriteView.menu;

  @override
  void initState() {
    super.initState();
    // Ekran açıldığında favori pazarları güncelleyelim
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadFavorites();
    });
  }

  void _navigateTo(FavoriteView view) {
    setState(() {
      _currentView = view;
    });
  }

  void _goBack() {
    setState(() {
      _currentView = FavoriteView.menu;
    });
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();

    // Geri tuşu kontrolü (Android fiziksel geri tuşu için)
    return PopScope(
      canPop: _currentView == FavoriteView.menu,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: Text(_getTitle(langVM)),
          leading: _currentView != FavoriteView.menu
              ? IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: Theme.of(context).colorScheme.primary),
                  onPressed: _goBack,
                )
              : null,
        ),
        body: _buildBody(context, langVM),
      ),
    );
  }

  String _getTitle(LanguageViewModel langVM) {
    switch (_currentView) {
      case FavoriteView.markets:
        return 'Favori Pazarlar';
      case FavoriteView.sellers:
        return 'Favori Satıcılar';
      case FavoriteView.products:
        return 'Favori Ürünler';
      case FavoriteView.menu:
      default:
        return langVM.translate('favorites_title');
    }
  }

  Widget _buildBody(BuildContext context, LanguageViewModel langVM) {
    switch (_currentView) {
      case FavoriteView.markets:
        return _buildFavoriteMarkets(context, langVM);
      case FavoriteView.sellers:
        return _buildFavoriteSellers(context, langVM);
      case FavoriteView.products:
        return _buildFavoriteProducts(context, langVM);
      case FavoriteView.menu:
      default:
        return _buildMenu(context);
    }
  }

  Widget _buildMenu(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        children: [
          _buildMenuButton(
            context,
            title: 'Favori Pazarlar',
            icon: Icons.storefront,
            color: Colors.orange,
            onTap: () => _navigateTo(FavoriteView.markets),
          ),
          const SizedBox(height: 16),
          _buildMenuButton(
            context,
            title: 'Favori Satıcılar',
            icon: Icons.people,
            color: Colors.blue,
            onTap: () => _navigateTo(FavoriteView.sellers),
          ),
          const SizedBox(height: 16),
          _buildMenuButton(
            context,
            title: 'Favori Ürünler',
            iconPath: AppIcons.products,
            color: Colors.green,
            onTap: () => _navigateTo(FavoriteView.products),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: color.withOpacity(isDark ? 0.15 : 0.08),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1.5,
              ),
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
                              color: color.withOpacity(0.25),
                            )
                          : Icon(
                              icon,
                              size: 140,
                              color: color.withOpacity(0.25),
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
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: iconPath != null
                                ? SvgIcon(
                                    iconPath: iconPath,
                                    size: 32,
                                    color: color,
                                  )
                                : Icon(icon, size: 32, color: color),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_forward, color: color),
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
        ),
      ),
    );
  }

  Widget _buildFavoriteMarkets(BuildContext context, LanguageViewModel langVM) {
    return Consumer<HomeViewModel>(
      builder: (context, homeVM, child) {
        if (homeVM.state == ViewState.busy) {
          return const Center(child: CustomLoadingIndicator());
        }

        if (homeVM.favoriteMarkets.isEmpty) {
          return _buildEmptyState(context, langVM.translate('no_favorites'),
              icon: Icons.storefront_outlined);
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
              12, 12, 12, 12 + MediaQuery.of(context).padding.bottom),
          itemCount: homeVM.favoriteMarkets.length,
          itemBuilder: (context, index) {
            var market = homeVM.favoriteMarkets[index];
            // Güncel veriyi bul
            try {
              market =
                  homeVM.nearbyMarkets.firstWhere((m) => m.id == market.id);
            } catch (_) {
              try {
                market =
                    homeVM.provinceMarkets.firstWhere((m) => m.id == market.id);
              } catch (_) {}
            }

            final tag = '${market.id}_fav';
            return MarketCard(
              market: market,
              heroTag: tag,
              isHorizontal: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MarketDetailScreen(market: market, heroTag: tag),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFavoriteSellers(BuildContext context, LanguageViewModel langVM) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AuthService.instance.fetchFavoriteSellersDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomLoadingIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
              context, langVM.translate('no_favorite_sellers'),
              icon: Icons.people_outline);
        }

        final sellers = snapshot.data!;
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
          itemCount: sellers.length,
          itemBuilder: (context, index) {
            final seller = sellers[index];
            final displayName = seller['stallName'] ??
                '${seller['firstName'] ?? ''} ${seller['lastName'] ?? ''}'
                    .trim();
            final rating = (seller['rating'] as num?)?.toDouble() ?? 0.0;
            final reviewCount = (seller['reviewCount'] as num?)?.toInt() ?? 0;
            final profilePic = seller['profilePicture'];

            final isDark = Theme.of(context).brightness == Brightness.dark;

            return GestureDetector(
              onTap: () {
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
                      marketName: '', // Detay sayfasında gerekirse çekilebilir
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.withOpacity(0.08)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Satıcı Resmi
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                          width: 2,
                        ),
                        image: (profilePic != null && profilePic.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(profilePic),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (profilePic == null || profilePic.isEmpty)
                          ? Icon(Icons.people,
                              size: 30,
                              color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Bilgiler
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Puanlama
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star,
                                        size: 14, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '($reviewCount)',
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
                    // Ok İkonu
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoriteProducts(
      BuildContext context, LanguageViewModel langVM) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AuthService.instance.fetchFavoriteProductsDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomLoadingIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(context, 'Henüz favori ürününüz yok.',
              iconPath: AppIcons.products);
        }

        final products = snapshot.data!;
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.62,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];

            return ProductCard(
              product: product,
              isPriority: false,
              isFavorite: true,
              onFavoriteToggle: () async {
                // 1. İşlemi anında gerçekleştir
                await AuthService.instance.toggleFavoriteProduct(product['id']);
                setState(() {}); // Listeyi yenile

                // 2. Kullanıcıya "Geri Al" imkanı sun
                if (context.mounted) {
                  CustomSnackbars.showUndo(
                    context,
                    'Ürün favorilerden çıkarıldı',
                    () async {
                      // 3. Geri al dendiğinde işlemi tersine çevirip listeyi tekrar yenile
                      await AuthService.instance
                          .toggleFavoriteProduct(product['id']);
                      if (mounted) setState(() {});
                    },
                  );
                }
              },
              onDetailReturn: () => setState(() {}),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message,
      {IconData? icon, String? iconPath}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconPath != null)
            SvgIcon(iconPath: iconPath, size: 80, color: Colors.grey.shade300)
          else
            Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
