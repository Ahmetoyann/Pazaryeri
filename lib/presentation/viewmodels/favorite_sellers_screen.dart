import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/language_viewmodel.dart';
import '../screens/auth_service.dart';
import '../viewmodels/customer_seller_detail_screen.dart';
import '../viewmodels/market_sellers_screen.dart'; // MockSeller sınıfı için

class FavoriteSellersScreen extends StatefulWidget {
  const FavoriteSellersScreen({super.key});

  @override
  State<FavoriteSellersScreen> createState() => _FavoriteSellersScreenState();
}

class _FavoriteSellersScreenState extends State<FavoriteSellersScreen> {
  List<String> _favoriteSellerIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await AuthService.instance.getFavoriteSellers();
    if (mounted) {
      setState(() {
        _favoriteSellerIds = favorites;
        _isLoading = false;
      });
    }
  }

  // Mock veri tabanı (MarketSellersScreen'deki verilerle eşleşmeli)
  List<MockSeller> _getAllMockSellers() {
    return [
      MockSeller(
        id: 's1',
        name: 'Ahmet Amca\'nın Yeri',
        description: 'Taze mevsim sebzeleri, kendi bahçemizden.',
        stallLocation: 'Girişten sağa dönünce 3. tezgah',
        rating: 4.8,
      ),
      MockSeller(
        id: 's2',
        name: 'Organik Köy Ürünleri',
        description: 'Köy yumurtası, peynir ve tereyağı.',
        stallLocation: 'Orta koridor, 12 numara',
        rating: 4.5,
      ),
      MockSeller(
        id: 's3',
        name: 'Fatma Teyze Meyveleri',
        description: 'En tatlı elmalar ve armutlar burada.',
        stallLocation: 'Sebzecilerin karşısı',
        rating: 4.9,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final allSellers = _getAllMockSellers();
    final favoriteSellers = allSellers
        .where((seller) => _favoriteSellerIds.contains(seller.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(langVM.translate('favorite_sellers_title')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteSellers.isEmpty
              ? Center(
                  child: Text(
                    langVM.translate('no_favorite_sellers'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favoriteSellers.length,
                  itemBuilder: (context, index) {
                    final seller = favoriteSellers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            seller.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        title: Text(seller.name),
                        subtitle: Text(seller.description),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerSellerDetailScreen(
                                sellerId: seller.id,
                                sellerName: seller.name,
                                sellerDescription: seller.description,
                                stallLocation: seller.stallLocation,
                              ),
                            ),
                          );
                          // Detay sayfasından dönünce listeyi yenile (favoriden çıkarılmış olabilir)
                          _loadFavorites();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
