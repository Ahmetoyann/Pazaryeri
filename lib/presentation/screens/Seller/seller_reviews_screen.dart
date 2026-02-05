import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../widgets/success_dialog.dart';

class SellerReviewsScreen extends StatefulWidget {
  const SellerReviewsScreen({super.key});

  @override
  State<SellerReviewsScreen> createState() => _SellerReviewsScreenState();
}

class _SellerReviewsScreenState extends State<SellerReviewsScreen> {
  List<Map<String, dynamic>> _allReviews = [];
  List<Map<String, dynamic>> _filteredReviews = [];
  List<Map<String, dynamic>> _allQuestions = [];
  List<Map<String, dynamic>> _filteredQuestions = [];
  Map<String, Map<String, dynamic>> _productStats = {};
  String? _selectedProductId;
  bool _isLoading = true;
  int _selectedTab = 0; // 0: Değerlendirmeler, 1: Sorular

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviews();
    });
  }

  Future<void> _loadReviews() async {
    final sellerVM = Provider.of<SellerViewModel>(context, listen: false);

    // Eğer ürünler henüz yüklenmediyse bekle (SellerMainScreen yüklüyor ama garanti olsun)
    if (sellerVM.myProducts.isEmpty && !sellerVM.isLoading) {
      await sellerVM.loadProducts();
    }

    // Sadece satıcının ürünlerine ait yorumları çek (Optimize edilmiş sorgu)
    final myProductIds = sellerVM.myProducts.map((p) => p.id).toList();
    final myReviewsRaw =
        await AuthService.instance.getReviewsForProducts(myProductIds);
    final myQuestionsRaw =
        await AuthService.instance.getQuestionsForProducts(myProductIds);

    final myReviews = myReviewsRaw.map((r) {
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

    final myQuestions = myQuestionsRaw.map((q) {
      final product = sellerVM.myProducts.firstWhere(
        (p) => p.id == q['productId'],
        orElse: () => SellerProduct(
            id: '',
            sellerId: '',
            name: 'Bilinmeyen Ürün',
            description: '',
            price: 0,
            category: ''),
      );
      return {
        ...q,
        'user': q['userName'] ?? 'Misafir',
        'productName': product.name,
      };
    }).toList();

    // Yanıtlanmamış soruları en üstte göster, diğerlerini tarihe göre sırala
    myQuestions.sort((a, b) {
      final bool isAnsweredA =
          a['sellerReply'] != null && (a['sellerReply'] as String).isNotEmpty;
      final bool isAnsweredB =
          b['sellerReply'] != null && (b['sellerReply'] as String).isNotEmpty;

      if (!isAnsweredA && isAnsweredB) return -1;
      if (isAnsweredA && !isAnsweredB) return 1;

      final String dateA = a['date'] ?? '';
      final String dateB = b['date'] ?? '';
      return dateB.compareTo(dateA);
    });

    // İstatistikleri hesapla
    final stats = <String, Map<String, dynamic>>{};
    for (var p in sellerVM.myProducts) {
      stats[p.id] = {
        'totalRating': 0.0,
        'count': 0,
      };
    }

    for (var r in myReviews) {
      final pid = r['productId'];
      if (stats.containsKey(pid)) {
        stats[pid]!['totalRating'] += (r['rating'] as num).toDouble();
        stats[pid]!['count'] = (stats[pid]!['count'] as int) + 1;
      }
    }

    if (mounted) {
      setState(() {
        _allReviews = myReviews;
        _allQuestions = myQuestions;
        _productStats = stats;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedProductId == null) {
      _filteredReviews = List.from(_allReviews);
      _filteredQuestions = List.from(_allQuestions);
    } else {
      _filteredReviews = _allReviews
          .where((r) => r['productId'] == _selectedProductId)
          .toList();
      _filteredQuestions = _allQuestions
          .where((q) => q['productId'] == _selectedProductId)
          .toList();
    }
  }

  void _onFilterChanged(String? productId) {
    setState(() {
      _selectedProductId = productId;
      _applyFilter();
    });
  }

  Future<void> _showReplyBottomSheet(String id,
      {bool isQuestion = false}) async {
    final TextEditingController _replyController = TextEditingController();
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              isQuestion
                  ? 'Soruyu Yanıtla'
                  : langVM.translate('reply_to_review_title'),
              style: TextStyle(
                color: Colors.orange,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _replyController,
              autofocus: true,
              style: const TextStyle(
                color: Colors.orange,
              ),
              decoration: InputDecoration(
                hintText: langVM.translate('answer_hint'),
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (_replyController.text.trim().isNotEmpty) {
                    try {
                      if (isQuestion) {
                        await AuthService.instance.replyToProductQuestion(
                          id,
                          _replyController.text.trim(),
                        );
                      } else {
                        await AuthService.instance.replyToProductReview(
                          id,
                          _replyController.text.trim(),
                        );
                      }
                      if (mounted) {
                        Navigator.pop(context);
                        await DialogService.showSuccess(
                          context,
                          message: langVM.translate('reply_sent_success'),
                          duration: const Duration(seconds: 3),
                        );
                        _loadReviews(); // Listeyi yenile
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context);
                        DialogService.showError(context, message: 'Hata: $e');
                      }
                    }
                  }
                },
                child: Text(langVM.translate('send_button')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final sellerVM = Provider.of<SellerViewModel>(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Özet Kartları (Yatay Liste)
        if (sellerVM.myProducts.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount:
                  _selectedProductId == null ? sellerVM.myProducts.length : 1,
              itemBuilder: (context, index) {
                final product = _selectedProductId == null
                    ? sellerVM.myProducts[index]
                    : sellerVM.myProducts
                        .firstWhere((p) => p.id == _selectedProductId);

                final stat = _productStats[product.id];
                final count = stat?['count'] as int? ?? 0;
                final total = stat?['totalRating'] as double? ?? 0.0;
                final avg = count > 0 ? total / count : 0.0;

                return Card(
                  margin: const EdgeInsets.only(right: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  color: _selectedProductId == product.id
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: Container(
                    width: 160,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 20, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              avg.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          '$count Değerlendirme',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        // Sekme Seçimi
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _selectedTab = 0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTab == 0
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).cardColor,
                    foregroundColor:
                        _selectedTab == 0 ? Colors.white : Colors.grey,
                  ),
                  child: Text('Puanlama'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _selectedTab = 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTab == 1
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).cardColor,
                    foregroundColor:
                        _selectedTab == 1 ? Colors.white : Colors.grey,
                  ),
                  child: const Text('Soru'),
                ),
              ),
            ],
          ),
        ),
        // Filtreleme Alanı
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: DropdownButtonFormField<String>(
            value: _selectedProductId,
            dropdownColor: const Color(0xFF1B5E20).withOpacity(0.95),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: langVM.translate('filter_by_product'),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.5), width: 2)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(langVM.translate('filter_all')),
              ),
              ...sellerVM.myProducts.map((product) {
                return DropdownMenuItem<String>(
                  value: product.id,
                  child: SizedBox(
                    width: 200,
                    child: Text(product.name, overflow: TextOverflow.ellipsis),
                  ),
                );
              }).toList(),
            ],
            onChanged: _onFilterChanged,
          ),
        ),
        // Yorum Listesi
        if (_selectedTab == 0)
          Expanded(
            child: _filteredReviews.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          langVM.translate('no_reviews_yet'),
                          style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _filteredReviews.length,
                    itemBuilder: (context, index) {
                      final item = _filteredReviews[index];
                      final date = item['date'] != null
                          ? DateTime.parse(item['date'])
                              .toString()
                              .split(' ')[0]
                          : '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.5)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(item['comment'] as String),
                              // Yanıt Alanı
                              if (item['sellerReply'] != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border(
                                      left: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        langVM.translate('seller_reply_label'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(item['sellerReply']),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          )
        else
          Expanded(
            child: _filteredQuestions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.help_outline,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz soru yok',
                          style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _filteredQuestions.length,
                    itemBuilder: (context, index) {
                      final item = _filteredQuestions[index];
                      final date = item['date'] != null
                          ? DateTime.parse(item['date'])
                              .toString()
                              .split(' ')[0]
                          : '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                  ),
                                  Text(
                                    date,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.5)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(item['question'] ?? ''),
                              // Yanıt Alanı
                              if (item['sellerReply'] != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border(
                                      left: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        langVM.translate('seller_reply_label'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(item['sellerReply']),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _showReplyBottomSheet(
                                        item['id'],
                                        isQuestion: true),
                                    icon: const Icon(Icons.reply, size: 18),
                                    label:
                                        Text(langVM.translate('reply_button')),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
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
