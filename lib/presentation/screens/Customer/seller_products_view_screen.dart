import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_service.dart';
import '../../viewmodels/language_viewmodel.dart';
import 'product_detail_screen.dart';
import '../../widgets/custom_app_bar.dart';

class SellerProductsViewScreen extends StatefulWidget {
  final Map<String, dynamic> seller;

  const SellerProductsViewScreen({super.key, required this.seller});

  @override
  State<SellerProductsViewScreen> createState() =>
      _SellerProductsViewScreenState();
}

class _SellerProductsViewScreenState extends State<SellerProductsViewScreen> {
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<String> _categories = ['filter_all'];
  String _selectedCategory = 'filter_all';
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  double _averageRating = 0.0;
  int _reviewCount = 0;
  String _sortOption = 'default';
  bool _isFavorite = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final favorites = await AuthService.instance.getFavoriteSellers();
    if (mounted) {
      setState(() {
        _isFavorite = favorites.contains(widget.seller['id']);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    if (AuthService.instance.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(langVM.translate('guest_message'))),
      );
      return;
    }

    await AuthService.instance.toggleFavoriteSeller(widget.seller['id']);

    if (mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
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

  Future<void> _loadProducts() async {
    try {
      // Ürünleri ve tüm yorumları paralel olarak çek
      final results = await Future.wait([
        AuthService.instance.getSellerProducts(widget.seller['id']),
        AuthService.instance.getAllProductReviews(),
      ]);

      final products = results[0] as List<Map<String, dynamic>>;
      final allReviews = results[1] as List<Map<String, dynamic>>;

      // Satıcının ürünlerine ait yorumları filtrele, ürün puanlarını ve istatistikleri hesapla
      final productIds = products.map((p) => p['id']).toSet();
      final sellerReviews =
          allReviews.where((r) => productIds.contains(r['productId'])).toList();

      for (var product in products) {
        final pReviews =
            allReviews.where((r) => r['productId'] == product['id']);
        if (pReviews.isNotEmpty) {
          double sum = pReviews.fold(0.0, (p, c) => p + (c['rating'] as num));
          product['averageRating'] = sum / pReviews.length;
        } else {
          product['averageRating'] = 0.0;
        }
      }

      double totalRating = 0.0;
      for (var r in sellerReviews) {
        if (r['rating'] != null) {
          totalRating += (r['rating'] as num).toDouble();
        }
      }

      // Kategorileri çıkar
      final categories = <String>{'filter_all'};
      for (var product in products) {
        if (product.containsKey('category')) {
          categories.add(product['category']);
        }
      }

      if (mounted) {
        setState(() {
          _allProducts = products;
          _filteredProducts = products;
          _categories = categories.toList();
          _averageRating =
              sellerReviews.isEmpty ? 0.0 : totalRating / sellerReviews.length;
          _reviewCount = sellerReviews.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      var temp = _allProducts.where((product) {
        final matchesCategory = _selectedCategory == 'filter_all' ||
            product['category'] == _selectedCategory;
        final matchesSearch = (product['name'] ?? '')
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();

      if (_sortOption == 'rating_desc') {
        temp.sort((a, b) => (b['averageRating'] as double)
            .compareTo(a['averageRating'] as double));
      } else if (_sortOption == 'rating_asc') {
        temp.sort((a, b) => (a['averageRating'] as double)
            .compareTo(b['averageRating'] as double));
      }
      _filteredProducts = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final stallName = widget.seller['stallName'] ??
        widget.seller['name'] ??
        '${widget.seller['firstName']} ${widget.seller['lastName']}';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: Text('$stallName Ürünleri'),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            color: _isFavorite ? Colors.red : Colors.white,
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Hata: $_errorMessage'))
              : Padding(
                  padding: const EdgeInsets.only(top: 110),
                  child: Column(
                    children: [
                      // Satıcı Puanı ve Bilgisi
                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                _averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '($_reviewCount Değerlendirme)',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Arama Çubuğu
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Ürün ara...',
                            hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6)),
                            prefixIcon: Icon(Icons.search,
                                color: Colors.white.withValues(alpha: 0.6)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.3))),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.3))),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 2)),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                          ),
                          onChanged: (value) {
                            _searchQuery = value;
                            _applyFilters();
                          },
                        ),
                      ),
                      // Filtreleme ve Sıralama
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            if (_categories.length > 1)
                              Expanded(
                                flex: 3,
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.3)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCategory,
                                      isExpanded: true,
                                      dropdownColor: const Color(0xFF1B5E20)
                                          .withValues(alpha: 0.95),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 13),
                                      icon: const Icon(Icons.filter_list,
                                          color: Colors.white, size: 18),
                                      items: _categories.map((String category) {
                                        return DropdownMenuItem<String>(
                                          value: category,
                                          child: Text(
                                            langVM.translate(category),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() =>
                                              _selectedCategory = newValue);
                                          _applyFilters();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.3)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _sortOption,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF1B5E20)
                                        .withValues(alpha: 0.95),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 13),
                                    icon: const Icon(Icons.sort,
                                        color: Colors.white, size: 18),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'default',
                                          child: Text('Varsayılan')),
                                      DropdownMenuItem(
                                          value: 'rating_desc',
                                          child: Text('Puan (Azalan)')),
                                      DropdownMenuItem(
                                          value: 'rating_asc',
                                          child: Text('Puan (Artan)')),
                                    ],
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() => _sortOption = newValue);
                                        _applyFilters();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _filteredProducts.isEmpty
                            ? const Center(
                                child: Text('Bu kategoride ürün bulunamadı.'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                            color:
                                                Colors.white.withOpacity(0.3)),
                                      ),
                                      child: ListTile(
                                        leading: _buildProductImage(
                                            product['imagePath']),
                                        title: Text(product['name']),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                '${product['price']} ₺ / ${langVM.translate(product['unit'] ?? 'unit_kg')}'),
                                            if ((product['averageRating'] ??
                                                    0) >
                                                0)
                                              Row(
                                                children: [
                                                  const Icon(Icons.star,
                                                      size: 14,
                                                      color: Colors.amber),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    (product['averageRating']
                                                            as double)
                                                        .toStringAsFixed(1),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                              alpha: 0.6),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                        trailing: product['inStock'] == true
                                            ? const Icon(Icons.check_circle,
                                                color: Colors.green, size: 20)
                                            : const Icon(Icons.remove_circle,
                                                color: Colors.red, size: 20),
                                        onTap: () {
                                          // Görüntülenme sayısını artır
                                          AuthService.instance
                                              .incrementProductViewCount(
                                                  product['id']);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProductDetailScreen(
                                                product: product,
                                                sellerName: stallName,
                                              ),
                                            ),
                                          );
                                        },
                                      ));
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProductImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.shopping_basket,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: path.startsWith('http')
          ? Image.network(
              path,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 48,
                height: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.1),
                child: Icon(Icons.error,
                    color: Theme.of(context).colorScheme.error),
              ),
            )
          : Image.file(
              File(path),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 48,
                height: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.1),
                child: Icon(Icons.error,
                    color: Theme.of(context).colorScheme.error),
              ),
            ),
    );
  }
}
