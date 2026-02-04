import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../Customer/customer_seller_detail_screen.dart';
import '../../widgets/custom_app_bar.dart';

class FavoriteSellersScreen extends StatefulWidget {
  const FavoriteSellersScreen({super.key});

  @override
  State<FavoriteSellersScreen> createState() => _FavoriteSellersScreenState();
}

class _FavoriteSellersScreenState extends State<FavoriteSellersScreen> {
  List<Map<String, dynamic>> _favoriteSellers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final sellers = await AuthService.instance.fetchFavoriteSellersDetails();
    if (mounted) {
      setState(() {
        _favoriteSellers = sellers;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar:
          CustomAppBar(title: Text(langVM.translate('favorite_sellers_title'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteSellers.isEmpty
              ? Center(
                  child: Text(
                    langVM.translate('no_favorite_sellers'),
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
                  itemCount: _favoriteSellers.length,
                  itemBuilder: (context, index) {
                    final seller = _favoriteSellers[index];
                    // İsim oluşturma (Ad Soyad veya Tezgah Adı)
                    String displayName = seller['stallName'] ?? '';
                    if (displayName.isEmpty) {
                      displayName =
                          '${seller['firstName'] ?? ''} ${seller['lastName'] ?? ''}'
                              .trim();
                    }
                    if (displayName.isEmpty) displayName = 'Satıcı';

                    final description =
                        seller['stallDescription'] ?? 'Açıklama yok';
                    final stallLocation = seller['stallLocation'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          backgroundImage: (seller['profilePicture'] != null &&
                                  seller['profilePicture'].isNotEmpty)
                              ? NetworkImage(seller['profilePicture'])
                              : null,
                          child: (seller['profilePicture'] == null ||
                                  seller['profilePicture'].isEmpty)
                              ? Text(
                                  displayName.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                )
                              : null,
                        ),
                        title: Text(displayName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerSellerDetailScreen(
                                sellerId: seller['id'],
                                sellerName: displayName,
                                sellerDescription: description,
                                stallLocation: stallLocation,
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
