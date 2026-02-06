import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/custom_app_bar.dart';
import 'product_detail_screen.dart';

class MyRatingsScreen extends StatefulWidget {
  const MyRatingsScreen({super.key});

  @override
  State<MyRatingsScreen> createState() => _MyRatingsScreenState();
}

class _MyRatingsScreenState extends State<MyRatingsScreen> {
  Future<void> _deleteReview(String reviewId) async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(langVM.translate('delete_review_title')),
        content: Text(langVM.translate('delete_review_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(langVM.translate('no')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              langVM.translate('yes'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.instance.deleteProductReview(reviewId);
      setState(() {});
    }
  }

  Future<void> _editReview(Map<String, dynamic> review) async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final commentController = TextEditingController(text: review['comment']);
    double currentRating = (review['rating'] as num).toDouble();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(langVM.translate('edit_review_title')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          currentRating = index + 1.0;
                        });
                      },
                      icon: Icon(
                        index < currentRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: langVM.translate('comment_hint'),
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
                  await AuthService.instance.updateProductReview(
                    review['id'],
                    commentController.text.trim(),
                    currentRating,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text(langVM.translate('update')),
              ),
            ],
          );
        },
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context);
    final userId = authVM.currentUser?.id;

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(langVM.translate('my_ratings_title')),
      ),
      body: userId == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: AuthService.instance.getUserProductReviews(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          '${langVM.translate('error_prefix')}: ${snapshot.error}'));
                }

                final reviews = snapshot.data ?? [];

                if (reviews.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_border,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          langVM.translate('no_ratings_yet'),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final date = review['date'] != null
                        ? DateTime.tryParse(review['date'].toString())
                        : null;
                    final formattedDate = date != null
                        ? DateFormat('dd MMM yyyy', langVM.currentLanguage)
                            .format(date)
                        : '';
                    final rating =
                        (review['rating'] as num?)?.toDouble() ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (review['product'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                  product: review['product'],
                                  sellerName: review['sellerName'] ?? 'Satıcı',
                                  highlightReviewId: review['id'],
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Ürün artık mevcut değil.')),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.4)),
                                      image: (review['productImage'] != null &&
                                              review['productImage']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                  review['productImage']),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: (review['productImage'] == null ||
                                            review['productImage']
                                                .toString()
                                                .isEmpty)
                                        ? Icon(Icons.shopping_bag_outlined,
                                            color: Colors.grey.shade400)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          review['productName'] ?? 'Ürün',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (review['sellerName'] != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            review['sellerName'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              formattedDate,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                            if (review['isEdited'] == true) ...[
                                              const SizedBox(width: 4),
                                              Text(
                                                '(${langVM.translate('edited')})',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontStyle: FontStyle.italic,
                                                    color:
                                                        Colors.grey.shade400),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      size: 20,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    onPressed: () => _editReview(review),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    onPressed: () =>
                                        _deleteReview(review['id']),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    starIndex < rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 20,
                                  );
                                }),
                              ),
                              if (review['comment'] != null &&
                                  review['comment'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  review['comment'],
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                              if (review['sellerReply'] != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.storefront,
                                            size: 18,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            langVM.translate(
                                                'seller_reply_label'),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        review['sellerReply'],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
