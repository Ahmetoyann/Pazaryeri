import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import 'product_detail_screen.dart';
import '../../viewmodels/auth_service.dart';

class CustomerSellerDetailScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String sellerDescription;
  final String stallLocation;

  const CustomerSellerDetailScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.sellerDescription,
    required this.stallLocation,
  });

  @override
  State<CustomerSellerDetailScreen> createState() =>
      _CustomerSellerDetailScreenState();
}

class _CustomerSellerDetailScreenState
    extends State<CustomerSellerDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
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

  // Mock products generator
  List<Map<String, dynamic>> _getMockProducts() {
    return [
      {
        'id': 'p1',
        'name': 'Amasya Elması',
        'price': 25.0,
        'unit': 'kg',
        'inStock': true,
        'image': null,
        'stockQuantity': 50.0,
      },
      {
        'id': 'p2',
        'name': 'Çengelköy Salatalık',
        'price': 30.0,
        'unit': 'kg',
        'inStock': true,
        'image': null,
        'stockQuantity': 8.0,
      },
      {
        'id': 'p3',
        'name': 'Domates',
        'price': 15.0,
        'unit': 'kg',
        'inStock': false,
        'image': null,
        'stockQuantity': 0.0,
      },
      {
        'id': 'p4',
        'name': 'Köy Biberi',
        'price': 40.0,
        'unit': 'kg',
        'inStock': true,
        'image': null,
        'stockQuantity': 100.0,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final products = _getMockProducts();

    return Scaffold(
      appBar: AppBar(
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Seller Info Header
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      widget.sellerName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 32, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.sellerName,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.sellerDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: Colors.orange.shade800),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${langVM.translate('stall_location')}: ${widget.stallLocation}',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Products Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                langVM.translate('seller_products'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final bool inStock = product['inStock'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            product: product,
                            sellerName: widget.sellerName,
                          ),
                        ),
                      );
                    },
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.shopping_basket, color: Colors.grey),
                    ),
                    title: Text(product['name']),
                    subtitle: Text(
                      '${product['price']} ₺ / ${product['unit']}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            inStock ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: inStock
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Text(
                        langVM.translate(inStock ? 'in_stock' : 'out_of_stock'),
                        style: TextStyle(
                          fontSize: 12,
                          color: inStock
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
