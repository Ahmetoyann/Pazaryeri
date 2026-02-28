import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/presentation/widgets/svg_icon.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../widgets/success_dialog.dart';
import '../../widgets/custom_bottom_sheets.dart';
import 'package:flutter_application_1/core/constants/app_icons.dart';
import '../../widgets/loading_overlay.dart';

class SellerReviewsScreen extends StatefulWidget {
  final String? highlightReviewId;
  const SellerReviewsScreen({super.key, this.highlightReviewId});

  @override
  State<SellerReviewsScreen> createState() => _SellerReviewsScreenState();
}

class _SellerReviewsScreenState extends State<SellerReviewsScreen> {
  List<Map<String, dynamic>> _sellerReviews = [];
  List<Map<String, dynamic>> _productReviews = [];
  List<Map<String, dynamic>> _filteredProductReviews = [];
  Map<String, Map<String, dynamic>> _productStats = {};
  String? _selectedProductId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviews();
    });
  }

  Future<void> _loadReviews() async {
    final sellerVM = Provider.of<SellerViewModel>(context, listen: false);
    final currentUserId = AuthService.instance.currentUserId;

    if (currentUserId == null) return;

    // Eğer ürünler henüz yüklenmediyse bekle
    if (sellerVM.myProducts.isEmpty) {
      await sellerVM.loadProducts();
    }

    // 1. Satıcı Değerlendirmelerini Çek
    final sellerReviews =
        await AuthService.instance.getSellerReviews(currentUserId);

    // 2. Ürün Değerlendirmelerini Çek
    final myProductIds = sellerVM.myProducts.map((p) => p.id).toList();
    final myReviewsRaw =
        await AuthService.instance.getReviewsForProducts(myProductIds);

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
        final rating = (r['rating'] as num?)?.toDouble() ?? 0.0;
        stats[pid]!['totalRating'] += rating;
        stats[pid]!['count'] = (stats[pid]!['count'] as int) + 1;
      }
    }

    if (mounted) {
      setState(() {
        _sellerReviews = sellerReviews;
        _productReviews = myReviews;
        _productStats = stats;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedProductId == null) {
      _filteredProductReviews = List.from(_productReviews);
    } else {
      _filteredProductReviews = _productReviews
          .where((r) => r['productId'] == _selectedProductId)
          .toList();
    }
  }

  void _onFilterChanged(String? productId) {
    setState(() {
      _selectedProductId = productId;
      _applyFilter();
    });
  }

  Future<void> _showReplyBottomSheet(String id) async {
    final TextEditingController _replyController = TextEditingController();
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    await CustomBottomSheets.showContent(
      context: context,
      title: langVM.translate('reply_to_review_title'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _replyController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: langVM.translate('answer_hint'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
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
                  final replyText = _replyController.text.trim();
                  try {
                    await AuthService.instance.replyToProductReview(
                      id,
                      replyText,
                    );
                    if (mounted) {
                      Navigator.pop(context);

                      // Anlık güncelleme
                      setState(() {
                        final index =
                            _productReviews.indexWhere((r) => r['id'] == id);
                        if (index != -1) {
                          _productReviews[index]['sellerReply'] = replyText;
                          _productReviews[index]['replyDate'] = Timestamp.now();
                          _applyFilter();
                        }
                      });

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
    );
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final sellerVM = Provider.of<SellerViewModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CustomLoadingIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'Değerlendirme'),
                Tab(text: 'Ürün Değerlendirme'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSellerReviewsTab(langVM),
                _buildProductReviewsTab(langVM, sellerVM, isDark, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerReviewsTab(LanguageViewModel langVM) {
    if (_sellerReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              langVM.translate('no_reviews_yet'),
              style: TextStyle(
                  fontSize: 17,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _sellerReviews.length,
      itemBuilder: (context, index) {
        final review = _sellerReviews[index];
        final date = review['date'] != null
            ? DateTime.parse(review['date']).toString().split(' ')[0]
            : '';
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: (review['userImage'] != null &&
                                review['userImage'].toString().isNotEmpty)
                            ? NetworkImage(review['userImage'])
                            : null,
                        child: (review['userImage'] == null ||
                                review['userImage'].toString().isEmpty)
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        review['userName'] ?? 'Kullanıcı',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(date,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < ((review['rating'] as num?)?.toDouble() ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    size: 20,
                    color: Colors.amber,
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(review['comment'] ?? ''),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductReviewsTab(LanguageViewModel langVM,
      SellerViewModel sellerVM, bool isDark, BuildContext context) {
    final backgroundColor = Theme.of(context).cardColor;
    final contentColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        // Özet Kartları (Yatay Liste)
        if (sellerVM.myProducts.isNotEmpty)
          SizedBox(
            height: 130,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                final isSelected = _selectedProductId == product.id;

                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.05)
                        : (isDark ? Theme.of(context).cardColor : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 20, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            avg.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 19, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        '$count Değerlendirme',
                        style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        // Filtreleme Alanı
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedProductId,
                hint: Text(langVM.translate('filter_by_product'),
                    style: TextStyle(color: contentColor.withOpacity(0.7))),
                isExpanded: true,
                icon: Icon(
                  Icons.filter_list,
                  color: contentColor,
                ),
                style: TextStyle(color: contentColor, fontSize: 17),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(langVM.translate('filter_all'),
                        style: TextStyle(color: contentColor)),
                  ),
                  ...sellerVM.myProducts.map((product) {
                    return DropdownMenuItem<String>(
                      value: product.id,
                      child: SizedBox(
                        width: 200,
                        child: Text(product.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: contentColor)),
                      ),
                    );
                  }).toList(),
                ],
                onChanged: _onFilterChanged,
              ),
            ),
          ),
        ),
        // Yorum Listesi
        Expanded(
          child: _filteredProductReviews.isEmpty
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
                            fontSize: 17,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: _filteredProductReviews.length,
                  itemBuilder: (context, index) {
                    final item = _filteredProductReviews[index];
                    final date = item['date'] != null
                        ? DateTime.parse(item['date']).toString().split(' ')[0]
                        : '';
                    final isHighlighted =
                        widget.highlightReviewId == item['id'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.05)
                            : (isDark
                                ? Theme.of(context).cardColor
                                : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: isHighlighted
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
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
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    if (item['productName'] != null)
                                      Text(
                                        item['productName'],
                                        style: TextStyle(
                                          fontSize: 13,
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
                                        i <
                                                ((item['rating'] as num?)
                                                        ?.toDouble() ??
                                                    0)
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
                                        fontSize: 11,
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
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border(
                                  left: BorderSide.none,
                                  top: BorderSide(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withOpacity(0.1)),
                                  right: BorderSide(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withOpacity(0.1)),
                                  bottom: BorderSide(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withOpacity(0.1)),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    langVM.translate('seller_reply_label'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color:
                                          Theme.of(context).colorScheme.primary,
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
                    );
                  },
                ),
        ),
      ],
    );
  }
}
