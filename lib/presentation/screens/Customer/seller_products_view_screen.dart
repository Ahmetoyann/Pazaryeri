import 'dart:io';
import 'package:flutter/material.dart';
import '../../viewmodels/auth_service.dart';
import 'product_detail_screen.dart';

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
  List<String> _categories = ['Tümü'];
  String _selectedCategory = 'Tümü';
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  double _averageRating = 0.0;
  int _reviewCount = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      // Ürünleri ve istatistikleri paralel olarak çek
      final results = await Future.wait([
        AuthService.instance.getSellerProducts(widget.seller['id']),
        AuthService.instance.getSellerStats(widget.seller['id']),
      ]);

      final products = results[0] as List<Map<String, dynamic>>;
      final stats = results[1] as Map<String, dynamic>;

      // Kategorileri çıkar
      final categories = <String>{'Tümü'};
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
          _averageRating = (stats['averageRating'] as num).toDouble();
          _reviewCount = stats['reviewCount'] as int;
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
      _filteredProducts = _allProducts.where((product) {
        final matchesCategory = _selectedCategory == 'Tümü' ||
            product['category'] == _selectedCategory;
        final matchesSearch = (product['name'] ?? '')
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stallName = widget.seller['stallName'] ??
        widget.seller['name'] ??
        '${widget.seller['firstName']} ${widget.seller['lastName']}';

    return Scaffold(
      appBar: AppBar(
        title: Text('$stallName Ürünleri'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Hata: $_errorMessage'))
              : Column(
                  children: [
                    // Satıcı Puanı ve Bilgisi
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).primaryColor.withOpacity(0.05),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 24),
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
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arama Çubuğu
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Ürün ara...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 16),
                        ),
                        onChanged: (value) {
                          _searchQuery = value;
                          _applyFilters();
                        },
                      ),
                    ),
                    // Kategori Filtresi
                    if (_categories.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        color: Colors.grey[100],
                        child: Row(
                          children: [
                            const Text('Kategori:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                isExpanded: true,
                                underline: Container(
                                    height: 1,
                                    color: Theme.of(context).primaryColor),
                                items: _categories.map((String category) {
                                  return DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    _selectedCategory = newValue;
                                    _applyFilters();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: _filteredProducts.isEmpty
                          ? const Center(
                              child: Text('Bu kategoride ürün bulunamadı.'))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredProducts.length,
                              separatorBuilder: (ctx, i) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return ListTile(
                                  leading:
                                      _buildProductImage(product['imagePath']),
                                  title: Text(product['name']),
                                  subtitle: Text(
                                      '${product['price']} ₺ / ${product['unit'] ?? 'Birim'}'),
                                  trailing: product['inStock'] == true
                                      ? const Icon(Icons.check_circle,
                                          color: Colors.green, size: 16)
                                      : const Icon(Icons.remove_circle,
                                          color: Colors.red, size: 16),
                                  onTap: () {
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
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildProductImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.shopping_basket, color: Colors.grey),
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
                color: Colors.grey[200],
                child: const Icon(Icons.error, color: Colors.grey),
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
                color: Colors.grey[200],
                child: const Icon(Icons.error, color: Colors.grey),
              ),
            ),
    );
  }
}
