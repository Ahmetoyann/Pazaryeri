import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/market_card.dart';
import 'market_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // Ekran açıldığında favorileri güncelleyelim
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(langVM.translate('favorites_title')),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<HomeViewModel>(
        builder: (context, homeVM, child) {
          if (homeVM.state == ViewState.busy) {
            return const Center(child: CircularProgressIndicator());
          }

          if (homeVM.favoriteMarkets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    langVM.translate('no_favorites'),
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: homeVM.favoriteMarkets.length,
            itemBuilder: (context, index) {
              final market = homeVM.favoriteMarkets[index];
              return Dismissible(
                key: Key(market.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                onDismissed: (direction) {
                  homeVM.toggleFavorite(market.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${market.name} favorilerden kaldırıldı'),
                      action: SnackBarAction(
                        label: 'Geri Al',
                        onPressed: () => homeVM.toggleFavorite(market.id),
                      ),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    MarketCard(
                      market: market,
                      isHorizontal: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MarketDetailScreen(market: market),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 40,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                          tooltip: 'Favorilerden Kaldır',
                          onPressed: () {
                            homeVM.toggleFavorite(market.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${market.name} favorilerden kaldırıldı',
                                ),
                                duration: const Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: 'Geri Al',
                                  onPressed: () =>
                                      homeVM.toggleFavorite(market.id),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
