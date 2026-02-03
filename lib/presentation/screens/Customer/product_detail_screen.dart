import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../widgets/status_message_widget.dart';
import 'seller_products_view_screen.dart';
import '../../widgets/custom_app_bar.dart';
import 'customer_seller_detail_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String sellerName;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.sellerName,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String? _successMessage;
  List<Map<String, dynamic>> _otherSellers = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadOtherSellers();
  }

  Future<void> _loadReviews() async {
    final reviews =
        await AuthService.instance.getProductReviews(widget.product['id']);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOtherSellers() async {
    final sellers = await AuthService.instance.getSellersSellingProduct(
      widget.product['name'],
      widget.product['sellerId'],
    );
    if (mounted) {
      setState(() {
        _otherSellers = sellers;
      });
    }
  }

  Future<void> _showAddReviewDialog() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    if (!authVM.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(langVM.translate('guest_message'))),
      );
      return;
    }

    final commentController = TextEditingController();
    int rating = 5;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(langVM.translate('add_review')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () => setState(() => rating = index + 1),
                      );
                    }),
                  ),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: langVM.translate('write_review_hint'),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(langVM.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (commentController.text.trim().isEmpty) return;

                    final newReview = {
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'productId': widget.product['id'],
                      'sellerId': widget.product['sellerId'],
                      'userId': authVM.currentUser?.id ?? 'guest',
                      'userName':
                          '${authVM.currentUser?.firstName} ${authVM.currentUser?.lastName}',
                      'rating': rating,
                      'comment': commentController.text.trim(),
                      'date': DateTime.now().toIso8601String(),
                    };

                    await AuthService.instance.addProductReview(newReview);
                    if (mounted) {
                      Navigator.pop(context);
                      _loadReviews();
                      setState(() {
                        _successMessage = langVM.translate('review_success');
                      });
                    }
                  },
                  child: Text(langVM.translate('send_button')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMarketSellers() {
    // Ürünün ait olduğu market ID'si (Veride yoksa varsayılan '1' atanır)
    final String marketId = widget.product['marketId']?.toString() ?? '1';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Pazardaki Satıcılar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: AuthService.instance.getMarketSellers(marketId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Hata: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Satıcı bulunamadı.'));
                      }

                      final sellers = snapshot.data!;
                      return ListView.separated(
                        controller: scrollController,
                        itemCount: sellers.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final seller = sellers[index];
                          final displayName = seller['stallName'] ??
                              '${seller['firstName'] ?? ''} ${seller['lastName'] ?? ''}'
                                  .trim();
                          final rating = seller['rating'] ?? 0.0;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              child: Text(
                                  displayName.isNotEmpty ? displayName[0] : '?',
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor)),
                            ),
                            title: Text(displayName),
                            subtitle: Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 16, color: Colors.amber),
                                Text(' $rating'),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SellerProductsViewScreen(seller: seller),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showOtherSellers() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Bu Ürünü Satan Diğer Satıcılar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _otherSellers.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final seller = _otherSellers[index];
                  final displayName = seller['stallName'] ??
                      '${seller['firstName']} ${seller['lastName']}';
                  final price = seller['productPrice'];
                  final unit = seller['productUnit'];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (seller['profilePicture'] != null &&
                              seller['profilePicture'].isNotEmpty)
                          ? NetworkImage(seller['profilePicture'])
                          : null,
                      child: (seller['profilePicture'] == null ||
                              seller['profilePicture'].isEmpty)
                          ? Text(displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?')
                          : null,
                    ),
                    title: Text(displayName),
                    subtitle: Text(
                      'Fiyat: $price ₺ / $unit',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context); // Sheet'i kapat
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerSellerDetailScreen(
                            sellerId: seller['id'],
                            sellerName: displayName,
                            sellerDescription: seller['stallDescription'] ?? '',
                            stallLocation: seller['stallLocation'] ?? '',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final product = widget.product;
    final bool inStock = product['inStock'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: Text(product['name']),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_successMessage != null)
                    StatusMessageWidget(
                      message: _successMessage!,
                      type: StatusType.success,
                      autoCloseDuration: const Duration(seconds: 3),
                      onClose: () => setState(() => _successMessage = null),
                    ),
                  // Product Header
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (product['imagePath'] != null &&
                            product['imagePath'].toString().isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                backgroundColor: Colors.black,
                                appBar: AppBar(
                                  backgroundColor: Colors.black,
                                  iconTheme:
                                      const IconThemeData(color: Colors.white),
                                ),
                                body: Center(
                                  child: InteractiveViewer(
                                    child: product['imagePath']
                                            .toString()
                                            .startsWith('http')
                                        ? Image.network(
                                            product['imagePath'],
                                            fit: BoxFit.contain,
                                          )
                                        : Image.file(
                                            File(product['imagePath']),
                                            fit: BoxFit.contain,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      },
                      child: Hero(
                        tag: 'product_image_${product['id']}',
                        child: Container(
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(24),
                            image: (product['imagePath'] != null &&
                                    product['imagePath'].toString().isNotEmpty)
                                ? DecorationImage(
                                    image: product['imagePath']
                                            .toString()
                                            .startsWith('http')
                                        ? NetworkImage(product['imagePath'])
                                        : FileImage(File(product['imagePath']))
                                            as ImageProvider,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: (product['imagePath'] == null ||
                                  product['imagePath'].toString().isEmpty)
                              ? const Icon(Icons.shopping_basket,
                                  size: 64, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product['name'],
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Text(
                        '${product['price']} ₺ / ${product['unit']}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.store, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        widget.sellerName,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: inStock
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: inStock
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Text(
                          langVM
                              .translate(inStock ? 'in_stock' : 'out_of_stock'),
                          style: TextStyle(
                            fontSize: 12,
                            color: inStock
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showMarketSellers,
                      icon: const Icon(Icons.store_mall_directory),
                      label: const Text('Pazardaki Satıcılar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_otherSellers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showOtherSellers,
                        icon: const Icon(Icons.compare_arrows),
                        label: Text(
                            '${_otherSellers.length} Satıcıda Daha Var - Fiyatları Gör'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                  const Divider(height: 32),

                  // Reviews Section
                  Text(
                    langVM.translate('product_reviews'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  if (_reviews.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              langVM.translate('no_reviews_for_product'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      review['userName'] ?? 'Misafir',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Row(
                                      children: List.generate(5, (starIndex) {
                                        return Icon(
                                          starIndex < (review['rating'] as int)
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 16,
                                          color: Colors.amber,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(review['comment'] ?? ''),
                                const SizedBox(height: 4),
                                Text(
                                  review['date'] != null
                                      ? DateTime.parse(review['date'])
                                          .toString()
                                          .split(' ')[0]
                                      : '',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReviewDialog,
        tooltip: langVM.translate('add_review'),
        child: const Icon(Icons.rate_review),
      ),
    );
  }
}
