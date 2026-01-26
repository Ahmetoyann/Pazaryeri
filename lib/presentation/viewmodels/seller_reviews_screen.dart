import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/language_viewmodel.dart';
import '../viewmodels/seller_viewmodel.dart';
import '../screens/auth_service.dart';

class SellerReviewsScreen extends StatefulWidget {
  const SellerReviewsScreen({super.key});

  @override
  State<SellerReviewsScreen> createState() => _SellerReviewsScreenState();
}

class _SellerReviewsScreenState extends State<SellerReviewsScreen> {
  bool _showOnlyUnanswered = false;
  List<Map<String, dynamic>> _allReviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final sellerVM = Provider.of<SellerViewModel>(context, listen: false);
    final allReviews = await AuthService.instance.getAllProductReviews();

    // Satıcının ürünlerine ait yorumları filtrele
    final myProductIds = sellerVM.myProducts.map((p) => p.id).toSet();
    final myReviews =
        allReviews.where((r) => myProductIds.contains(r['productId'])).map((r) {
      final product =
          sellerVM.myProducts.firstWhere((p) => p.id == r['productId']);
      return {
        ...r,
        'user': r['userName'] ?? 'Misafir',
        'productName': product.name,
        'type': 'review',
        'isAnswered': true,
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

    // Filtreleme mantığı
    final displayedReviews = _showOnlyUnanswered
        ? _allReviews
            .where((item) =>
                item['type'] == 'question' && item['isAnswered'] == false)
            .toList()
        : _allReviews;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Filtre Seçenekleri
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              FilterChip(
                label: Text(langVM.translate('filter_all')),
                selected: !_showOnlyUnanswered,
                onSelected: (val) {
                  setState(() => _showOnlyUnanswered = false);
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(langVM.translate('filter_unanswered')),
                selected: _showOnlyUnanswered,
                onSelected: (val) {
                  setState(() => _showOnlyUnanswered = true);
                },
              ),
            ],
          ),
        ),
        // Liste
        displayedReviews.isEmpty
            ? Expanded(
                child: Center(
                  child: Text(
                    langVM.translate('no_reviews_yet'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayedReviews.length,
                  itemBuilder: (context, index) {
                    final item = displayedReviews[index];
                    final isQuestion = item['type'] == 'question';

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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['user'] as String,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    if (item['productName'] != null)
                                      Text(
                                        item['productName'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                  ],
                                ),
                                if (!isQuestion)
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
                                if (isQuestion)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text('Soru',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.blue)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(isQuestion
                                ? item['question'] as String
                                : item['comment'] as String),
                            if (isQuestion && item['isAnswered'] == true) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.subdirectory_arrow_right,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Yanıt: ${item['answer']}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (isQuestion && item['isAnswered'] == false) ...[
                              const Divider(height: 24),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: langVM.translate('answer_hint'),
                                  suffixIcon: TextButton(
                                    onPressed: () {
                                      // Simülasyon: Yanıtla butonuna basınca yanıtlanmış olarak işaretle
                                      setState(() {
                                        item['isAnswered'] = true;
                                        item['answer'] =
                                            'Teşekkürler!'; // Örnek yanıt
                                      });
                                    },
                                    child:
                                        Text(langVM.translate('reply_button')),
                                  ),
                                  border: InputBorder.none,
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }
}
