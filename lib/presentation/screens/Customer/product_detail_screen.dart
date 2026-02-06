import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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
  final String? highlightReviewId;
  final String? highlightQuestionId;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.sellerName,
    this.highlightReviewId,
    this.highlightQuestionId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _allReviews = [];
  int _selectedRatingFilter = 0;
  bool _isLoading = true;
  String? _successMessage;
  int _currentImageIndex = 0;
  List<Map<String, dynamic>> _otherSellers = [];
  List<Map<String, dynamic>> _questions = [];
  final Map<String, GlobalKey> _reviewKeys = {};
  final Map<String, GlobalKey> _questionKeys = {};

  final Map<String, Color> _categoryColors = {
    'category_fruit': Colors.orange,
    'category_vegetable': Colors.green,
    'category_delicatessen': Colors.redAccent,
    'category_dairy': Colors.blue,
    'category_bakery': Colors.amber,
    'category_spices': Colors.deepOrange,
    'category_fish': Colors.teal,
    'category_clothing': Colors.purple,
    'category_other': Colors.blueGrey,
  };

  final Map<String, IconData> _categoryIcons = {
    'category_fruit': Icons.eco,
    'category_vegetable': Icons.grass,
    'category_delicatessen': Icons.breakfast_dining,
    'category_dairy': Icons.local_drink,
    'category_bakery': Icons.bakery_dining,
    'category_spices': Icons.local_fire_department,
    'category_fish': Icons.set_meal,
    'category_clothing': Icons.checkroom,
    'category_other': Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadOtherSellers();
    _loadQuestions();
  }

  Future<void> _loadReviews() async {
    final reviews =
        await AuthService.instance.getProductReviews(widget.product['id']);
    if (mounted) {
      setState(() {
        _allReviews = reviews;
        _applyFilter();
        _isLoading = false;
      });

      if (widget.highlightReviewId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _scrollToHighlightedItem(widget.highlightReviewId!, _reviewKeys);
          });
        });
      }
    }
  }

  void _applyFilter() {
    if (_selectedRatingFilter == 0) {
      _reviews = List.from(_allReviews);
    } else {
      _reviews = _allReviews.where((r) {
        final rating = r['rating'];
        return (rating is num) && rating.toInt() == _selectedRatingFilter;
      }).toList();
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

  Future<void> _loadQuestions() async {
    final questions =
        await AuthService.instance.getProductQuestions(widget.product['id']);
    if (mounted) {
      setState(() {
        _questions = questions;
      });

      if (widget.highlightQuestionId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _scrollToHighlightedItem(
                widget.highlightQuestionId!, _questionKeys);
          });
        });
      }
    }
  }

  void _scrollToHighlightedItem(String id, Map<String, GlobalKey> keys) {
    final key = keys[id];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
        alignment: 0.5,
      );
    } else {
      // Eğer ilk denemede bulunamazsa (render gecikmesi), kısa süre sonra tekrar dene
      Future.delayed(const Duration(milliseconds: 500), () {
        final retryKey = keys[id];
        if (retryKey != null && retryKey.currentContext != null) {
          Scrollable.ensureVisible(
            retryKey.currentContext!,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
            alignment: 0.5,
          );
        }
      });
    }
  }

  Future<void> _showAddReviewDialog() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    final commentController = TextEditingController();
    int rating = 0;
    XFile? reviewImage;
    final ImagePicker picker = ImagePicker();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
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
                    langVM.translate('add_review'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          iconSize: 40,
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () => setState(() => rating = index + 1),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: langVM.translate('write_review_hint'),
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 70,
                            maxWidth: 1024,
                          );
                          if (image != null) {
                            setState(() => reviewImage = image);
                          }
                        },
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Fotoğraf Ekle'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                      if (reviewImage != null) ...[
                        const SizedBox(width: 8),
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(reviewImage!.path),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => reviewImage = null),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.cancel,
                                    color: Colors.red, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ]
                    ],
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
                      ),
                      onPressed: () async {
                        if (rating == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(langVM.translate('please_rate'))),
                          );
                          return;
                        }
                        if (commentController.text.trim().isEmpty) return;

                        String? imageUrl;
                        if (reviewImage != null) {
                          // Yükleme işlemi
                          imageUrl = await AuthService.instance
                              .uploadReviewImage(File(reviewImage!.path));
                        }

                        final newReview = {
                          'id':
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          'productId': widget.product['id'],
                          'sellerId': widget.product['sellerId'],
                          'userId': authVM.currentUser?.id ?? 'guest',
                          'userName':
                              '${authVM.currentUser?.firstName} ${authVM.currentUser?.lastName}',
                          'userProfilePicture':
                              authVM.currentUser?.profilePicturePath,
                          'rating': rating,
                          'comment': commentController.text.trim(),
                          'date': DateTime.now().toIso8601String(),
                          'imageUrl': imageUrl,
                        };

                        await AuthService.instance.addProductReview(newReview);
                        if (mounted) {
                          Navigator.pop(context);
                          _loadReviews();
                          setState(() {
                            _successMessage =
                                langVM.translate('review_success');
                          });
                        }
                      },
                      child: Text(langVM.translate('send_button')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAskQuestionDialog() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final questionController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
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
                'Soru Sor',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: questionController,
                decoration: InputDecoration(
                  hintText: 'Sorunuzu buraya yazın...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 3,
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
                  ),
                  onPressed: () async {
                    if (questionController.text.trim().isEmpty) return;

                    final newQuestion = {
                      'productId': widget.product['id'],
                      'userId': authVM.currentUser?.id ?? 'guest',
                      'userName':
                          '${authVM.currentUser?.firstName} ${authVM.currentUser?.lastName}',
                      'question': questionController.text.trim(),
                      'date': DateTime.now().toIso8601String(),
                    };

                    await AuthService.instance.askProductQuestion(newQuestion);
                    if (mounted) {
                      Navigator.pop(context);
                      _loadQuestions();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sorunuz gönderildi.')),
                      );
                    }
                  },
                  child: Text(langVM.translate('send_button')),
                ),
              ),
            ],
          ),
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
                                  .withValues(alpha: 0.1),
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
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
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
                      'Fiyat: $price ₺ / ${langVM.translate(unit ?? 'unit_kg')}',
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

  Future<void> _confirmDeleteReview(
    BuildContext context,
    String reviewId,
  ) async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yorumu Sil'),
        content: const Text('Bu yorumu silmek istediğinize emin misiniz?'),
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
      _loadReviews();
    }
  }

  Future<void> _confirmDeleteQuestion(
    BuildContext context,
    String questionId,
  ) async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soruyu Sil'),
        content: const Text('Bu soruyu silmek istediğinize emin misiniz?'),
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
      await AuthService.instance.deleteProductQuestion(questionId);
      _loadQuestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final product = widget.product;
    final bool inStock = product['inStock'];
    final double stockQuantity =
        (product['stockQuantity'] as num?)?.toDouble() ?? 0;
    final bool isLowStock = inStock && stockQuantity > 0 && stockQuantity < 5;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? Colors.white : Theme.of(context).colorScheme.primary;
    final contentColor = isDark ? Colors.black : Colors.white;

    // Kategoriye göre stil belirle
    final category = product['category'] as String? ?? 'category_other';
    final categoryColor =
        _categoryColors[category] ?? Theme.of(context).primaryColor;
    final categoryIcon = _categoryIcons[category] ?? Icons.category;

    final List<String> images = [];
    if (product['images'] != null && (product['images'] as List).isNotEmpty) {
      images.addAll((product['images'] as List).map((e) => e.toString()));
    } else if (product['imagePath'] != null &&
        product['imagePath'].toString().isNotEmpty) {
      images.add(product['imagePath'].toString());
    }

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
                  GestureDetector(
                    onTap: () {
                      if (images.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _FullScreenImageGallery(
                              images: images,
                              initialIndex: _currentImageIndex,
                            ),
                          ),
                        );
                      }
                    },
                    child: Hero(
                      tag: 'product_image_${product['id']}',
                      child: Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: categoryColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: images.isNotEmpty
                                  ? PageView.builder(
                                      itemCount: images.length,
                                      onPageChanged: (index) {
                                        setState(
                                            () => _currentImageIndex = index);
                                      },
                                      itemBuilder: (context, index) {
                                        final img = images[index];
                                        return ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          child: img.startsWith('http')
                                              ? Image.network(
                                                  img,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    debugPrint(
                                                        'Ürün resmi yükleme hatası: $error');
                                                    return Icon(categoryIcon,
                                                        size: 64,
                                                        color: categoryColor
                                                            .withOpacity(0.5));
                                                  },
                                                )
                                              : Image.file(
                                                  File(img),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Icon(categoryIcon,
                                                          size: 64,
                                                          color: categoryColor
                                                              .withOpacity(
                                                                  0.5)),
                                                ),
                                        );
                                      },
                                    )
                                  : Center(
                                      child: Icon(categoryIcon,
                                          size: 100,
                                          color:
                                              categoryColor.withOpacity(0.5)),
                                    ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: categoryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(categoryIcon,
                                    size: 20, color: Colors.white),
                              ),
                            ),
                            if (images.length > 1)
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children:
                                      List.generate(images.length, (index) {
                                    return Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentImageIndex == index
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.5),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${product['price']} ₺ / ${langVM.translate(product['unit'] ?? 'unit_kg')}',
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
                      Icon(Icons.store,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        widget.sellerName,
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLowStock
                              ? Colors.orange.withValues(alpha: 0.1)
                              : (inStock
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isLowStock
                                ? Colors.orange
                                : (inStock
                                    ? Colors.green.withValues(alpha: 0.5)
                                    : Colors.red.withValues(alpha: 0.5)),
                          ),
                        ),
                        child: Text(
                          isLowStock
                              ? '${langVM.translate('critical_stock')} (${stockQuantity % 1 == 0 ? stockQuantity.toInt() : stockQuantity} ${langVM.translate(product['unit'] ?? 'unit_kg')})'
                              : langVM.translate(
                                  inStock ? 'in_stock' : 'out_of_stock'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isLowStock ? FontWeight.bold : null,
                            color: isLowStock
                                ? Colors.orange
                                : (inStock ? Colors.green : Colors.red),
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
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                  const Divider(height: 32),

                  // Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        langVM.translate('product_reviews'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedRatingFilter,
                            dropdownColor: backgroundColor,
                            style: TextStyle(color: contentColor),
                            isDense: true,
                            icon: Icon(Icons.filter_list,
                                size: 20, color: contentColor),
                            items: [
                              DropdownMenuItem(
                                value: 0,
                                child: Text('Tümü',
                                    style: TextStyle(color: contentColor)),
                              ),
                              ...List.generate(5, (index) {
                                final stars = 5 - index;
                                return DropdownMenuItem(
                                  value: stars,
                                  child: Row(
                                    children: [
                                      Text('$stars',
                                          style:
                                              TextStyle(color: contentColor)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.star,
                                          size: 16, color: Colors.amber),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedRatingFilter = val;
                                  _applyFilter();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_reviews.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              langVM.translate('no_reviews_for_product'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6)),
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
                        final isHighlighted =
                            widget.highlightReviewId == review['id'];

                        if (!_reviewKeys.containsKey(review['id'])) {
                          _reviewKeys[review['id']] = GlobalKey();
                        }

                        return Card(
                          key: _reviewKeys[review['id']],
                          margin: const EdgeInsets.only(bottom: 12),
                          color: isHighlighted
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isHighlighted
                                ? BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2)
                                : BorderSide(
                                    color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.1),
                                          backgroundImage: (review[
                                                          'userProfilePicture'] !=
                                                      null &&
                                                  review['userProfilePicture']
                                                      .toString()
                                                      .isNotEmpty)
                                              ? NetworkImage(
                                                  review['userProfilePicture'])
                                              : null,
                                          child: (review['userProfilePicture'] ==
                                                      null ||
                                                  review['userProfilePicture']
                                                      .toString()
                                                      .isEmpty)
                                              ? Text(
                                                  (review['userName'] ?? 'M')[0]
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          review['userName'] ?? 'Misafir',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        ...List.generate(5, (starIndex) {
                                          return Icon(
                                            starIndex <
                                                    (review['rating'] as int)
                                                ? Icons.star
                                                : Icons.star_border,
                                            size: 16,
                                            color: Colors.amber,
                                          );
                                        }),
                                        if (review['userId'] ==
                                            authVM.currentUser?.id)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8.0),
                                            child: GestureDetector(
                                              onTap: () => _confirmDeleteReview(
                                                  context, review['id']),
                                              child: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(review['comment'] ?? ''),
                                const SizedBox(height: 4),
                                if (review['imageUrl'] != null &&
                                    review['imageUrl']
                                        .toString()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => Scaffold(
                                            backgroundColor: Colors.black,
                                            appBar: AppBar(
                                                backgroundColor: Colors.black,
                                                iconTheme: const IconThemeData(
                                                    color: Colors.white)),
                                            body: Center(
                                              child: InteractiveViewer(
                                                child: Image.network(
                                                    review['imageUrl']),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(review['imageUrl'],
                                          height: 100, fit: BoxFit.cover),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      review['date'] != null
                                          ? DateTime.parse(review['date'])
                                              .toString()
                                              .split(' ')[0]
                                          : '',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5)),
                                    ),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            if (authVM.currentUser == null)
                                              return;
                                            if (review['id'] == null) return;

                                            await AuthService.instance
                                                .toggleProductReviewLike(
                                              review['id'],
                                              authVM.currentUser!.id,
                                            );
                                            _loadReviews();
                                          },
                                          child: Icon(
                                            (review['likes'] as List?)
                                                        ?.contains(authVM
                                                            .currentUser?.id) ==
                                                    true
                                                ? Icons.thumb_up
                                                : Icons.thumb_up_outlined,
                                            size: 16,
                                            color: (review['likes'] as List?)
                                                        ?.contains(authVM
                                                            .currentUser?.id) ==
                                                    true
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(review['likes'] as List?)?.length ?? 0}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (review['sellerReply'] != null &&
                                    review['sellerReply']
                                        .toString()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
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
                                              size: 16,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Satıcı Yanıtı',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          review['sellerReply'],
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        if (review['replyDate'] != null)
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                review['replyDate'] is Timestamp
                                                    ? () {
                                                        final dt = (review[
                                                                    'replyDate']
                                                                as Timestamp)
                                                            .toDate();
                                                        return '${dt.day}.${dt.month}.${dt.year}';
                                                      }()
                                                    : '',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.6),
                                                ),
                                              ),
                                            ),
                                          ),
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
                  const Divider(height: 32),

                  // Questions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        langVM.translate('questions_title'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final authVM = context.read<AuthViewModel>();
                          if (await authVM.checkGuestStatus(context)) {
                            _showAskQuestionDialog();
                          }
                        },
                        icon: const Icon(Icons.add_comment),
                        label: const Text('Soru Sor'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_questions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Henüz soru sorulmamış.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final question = _questions[index];
                        final isCurrentUser = question['userId'] != null &&
                            question['userId'] == authVM.currentUser?.id;
                        final isHighlighted =
                            widget.highlightQuestionId == question['id'];

                        if (!_questionKeys.containsKey(question['id'])) {
                          _questionKeys[question['id']] = GlobalKey();
                        }

                        return Card(
                          key: _questionKeys[question['id']],
                          margin: const EdgeInsets.only(bottom: 12),
                          color: isHighlighted
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isHighlighted
                                ? BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2)
                                : BorderSide(
                                    color: Colors.white.withOpacity(0.3)),
                          ),
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
                                      question['userName'] ?? 'Misafir',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          question['date'] != null
                                              ? DateTime.parse(question['date'])
                                                  .toString()
                                                  .split(' ')[0]
                                              : '',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                        if (isCurrentUser)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () =>
                                                _confirmDeleteQuestion(
                                                    context, question['id']),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(question['question'] ?? ''),
                                if (question['sellerReply'] != null &&
                                    question['sellerReply']
                                        .toString()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
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
                                              size: 16,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Satıcı Yanıtı',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          question['sellerReply'],
                                          style: const TextStyle(fontSize: 13),
                                        ),
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
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final authVM = context.read<AuthViewModel>();
          if (await authVM.checkGuestStatus(context)) {
            _showAddReviewDialog();
          }
        },
        tooltip: langVM.translate('add_review'),
        child: const Icon(Icons.rate_review),
      ),
    );
  }
}

class _FullScreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageGallery({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageGallery> createState() =>
      _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<_FullScreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final img = widget.images[index];
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: img.startsWith('http')
                  ? Image.network(img, fit: BoxFit.contain)
                  : Image.file(File(img), fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
