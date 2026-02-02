import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserReviews();
  }

  Future<void> _loadUserReviews() async {
    final userId = context.read<AuthViewModel>().currentUser?.id;
    if (userId != null) {
      final allReviews = await AuthService.instance.getReviews();
      if (mounted) {
        setState(() {
          _reviews = allReviews.where((r) => r['userId'] == userId).toList();
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      await AuthService.instance.deleteReview(reviewId);
      _loadUserReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(langVM.translate('my_reviews')),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.comment_bank_outlined,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        langVM.translate('no_reviews_yet'),
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _reviews.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  review['marketName'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      review['date'] as String,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () =>
                                          _deleteReview(review['id']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(5, (starIndex) {
                                return Icon(
                                  starIndex < (review['rating'] as int)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 18,
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              review['comment'] as String,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
