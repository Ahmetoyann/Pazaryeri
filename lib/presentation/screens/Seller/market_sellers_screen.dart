import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../Customer/customer_seller_detail_screen.dart';

// Mock Seller Model for UI demonstration
class MockSeller {
  final String id;
  final String name;
  final String description;
  final String stallLocation;
  final String? imageUrl;
  final double rating;

  MockSeller({
    required this.id,
    required this.name,
    required this.description,
    required this.stallLocation,
    this.imageUrl,
    this.rating = 0.0,
  });
}

class MarketSellersScreen extends StatelessWidget {
  final String marketId;
  final String marketName;

  const MarketSellersScreen({
    super.key,
    required this.marketId,
    required this.marketName,
  });

  // Mock data generator
  List<MockSeller> _getMockSellers() {
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
    final sellers = _getMockSellers();

    return Scaffold(
      appBar: AppBar(
        title: Text('$marketName - ${langVM.translate('sellers_title')}'),
      ),
      body: sellers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store_mall_directory_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    langVM.translate('no_sellers_found'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sellers.length,
              itemBuilder: (context, index) {
                final seller = sellers[index];
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
                    title: Text(seller.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      seller.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
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
                    },
                  ),
                );
              },
            ),
    );
  }
}
