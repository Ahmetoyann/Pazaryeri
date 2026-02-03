import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/auth_service.dart';

class SellerReviewsScreen extends StatefulWidget {
  const SellerReviewsScreen({super.key});

  @override
  State<SellerReviewsScreen> createState() => _SellerReviewsScreenState();
}

class _SellerReviewsScreenState extends State<SellerReviewsScreen> {
  List<Map<String, dynamic>> _allReviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final sellerVM = Provider.of<SellerViewModel>(context, listen: false);

    // Eğer ürünler henüz yüklenmediyse bekle (SellerMainScreen yüklüyor ama garanti olsun)
    if (sellerVM.myProducts.isEmpty && !sellerVM.isLoading) {
      await sellerVM.loadProducts();
    }

    final allReviews = await AuthService.instance.getAllProductReviews();

    // Satıcının ürünlerine ait yorumları filtrele
    final myProductIds = sellerVM.myProducts.map((p) => p.id).toSet();
    final myReviews =
        allReviews.where((r) => myProductIds.contains(r['productId'])).map((r) {
      final product = sellerVM.myProducts.firstWhere(
        (p) => p.id == r['productId'],
        orElse: () => SellerProduct(
            id: '',
            sellerId: '',
            name: 'Bilinmeyen Ürün',
            description: '',
            price: 0,
            category: ''),
      );
      return {
        ...r,
        'user': r['userName'] ?? 'Misafir',
        'productName': product.name,
      };
    }).toList();

    if (mounted) {
      setState(() {
        _allReviews = myReviews;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rate_review_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              langVM.translate('no_reviews_yet'),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allReviews.length,
      itemBuilder: (context, index) {
        final item = _allReviews[index];
        final date = item['date'] != null
            ? DateTime.parse(item['date']).toString().split(' ')[0]
            : '';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['user'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (item['productName'] != null)
                            Text(
                              item['productName'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < (item['rating'] as int)
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        Text(
                          date,
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(item['comment'] as String),
              ],
            ),
          ),
        );
      },
    );
  }
}
