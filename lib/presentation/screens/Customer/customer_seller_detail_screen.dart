import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import 'product_detail_screen.dart';
import '../../viewmodels/auth_service.dart';
import '../../widgets/custom_app_bar.dart';

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
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _productsByCategory = {};
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products =
        await AuthService.instance.getSellerProducts(widget.sellerId);

    // Ürünleri kategorilere ayır
    final byCategory = <String, List<Map<String, dynamic>>>{};
    final categoriesSet = <String>{};

    for (var p in products) {
      final cat = p['category'] as String? ?? 'Diğer';
      categoriesSet.add(cat);
      if (!byCategory.containsKey(cat)) {
        byCategory[cat] = [];
      }
      byCategory[cat]!.add(p);
    }

    if (mounted) {
      setState(() {
        _products = products;
        _productsByCategory = byCategory;
        _categories = categoriesSet.toList()..sort();
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
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
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 110),
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
                  length: _categories.length,
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 110),
                            child: _buildSellerInfo(context, langVM),
                          ),
                        ),
                        SliverPersistentHeader(
                          delegate: _SliverAppBarDelegate(
                            TabBar(
                              isScrollable: true,
                              labelColor: Theme.of(context).colorScheme.primary,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor:
                                  Theme.of(context).colorScheme.primary,
                              tabs: _categories
                                  .map((c) => Tab(text: langVM.translate(c)))
                                  .toList(),
                            ),
                            Theme.of(context).cardColor,
                          ),
                          pinned: true,
                        ),
                      ];
                    },
                    body: TabBarView(
                      children: _categories.map((cat) {
                        final catProducts = _productsByCategory[cat]!;
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: catProducts.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(
                                context, catProducts[index], langVM);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
    );
  }

  Widget _buildSellerInfo(BuildContext context, LanguageViewModel langVM) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product,
      LanguageViewModel langVM) {
    final bool inStock = product['inStock'] ?? false;
    final String? imagePath = product['imagePath'];

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
            image: (imagePath != null && imagePath.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(imagePath),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: (imagePath == null || imagePath.isEmpty)
              ? const Icon(Icons.shopping_basket, color: Colors.grey)
              : null,
        ),
        title: Text(product['name']),
        subtitle: Text(
          '${product['price']} ₺ / ${product['unit']}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: inStock ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: inStock ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Text(
                langVM.translate(inStock ? 'in_stock' : 'out_of_stock'),
                style: TextStyle(
                  fontSize: 12,
                  color: inStock ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _backgroundColor;

  _SliverAppBarDelegate(this._tabBar, this._backgroundColor);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: _backgroundColor,
          child: _tabBar,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
