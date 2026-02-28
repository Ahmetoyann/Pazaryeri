import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../viewmodels/language_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/auth_service.dart';
import '../../core/constants/app_icons.dart';
import '../widgets/svg_icon.dart';
import '../screens/Customer/product_detail_screen.dart';

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isPriority;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onDetailReturn;

  const ProductCard({
    super.key,
    required this.product,
    this.isPriority = false,
    required this.isFavorite,
    required this.onFavoriteToggle,
    this.onDetailReturn,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final theme = Theme.of(context);
    final product = widget.product;

    // Resim listesini hazırla
    List<String> images = [];
    if (product['images'] != null && (product['images'] as List).isNotEmpty) {
      images = List<String>.from(product['images']);
    } else if (product['imagePath'] != null &&
        product['imagePath'].toString().isNotEmpty) {
      images = [product['imagePath'].toString()];
    }

    final price = product['price'];
    final unit = product['unit'] ?? 'unit_kg';
    final double stock = (product['stockQuantity'] as num?)?.toDouble() ?? 0;
    final bool isLowStock = stock > 0 && stock < 10;
    final bool outOfStock = product['inStock'] == false || stock <= 0;

    return GestureDetector(
      onTap: () => _navigateToDetail(context),
      onLongPress: () => _showQuickPreview(context),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isPriority
                ? theme.colorScheme.primary
                : Colors.white.withOpacity(0.1),
            width: widget.isPriority ? 2.0 : 1.0,
          ),
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
            // Ürün Resmi
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    images.isNotEmpty
                        ? PageView.builder(
                            itemCount: images.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final img = images[index];
                              return Container(
                                width: double.infinity,
                                color: Colors.grey.withOpacity(0.05),
                                child: img.startsWith('http')
                                    ? Image.network(
                                        img,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image,
                                                    color: Colors.grey),
                                      )
                                    : Image.file(
                                        File(img),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image,
                                                    color: Colors.grey),
                                      ),
                              );
                            },
                          )
                        : Container(
                            width: double.infinity,
                            color: Colors.grey.withOpacity(0.05),
                            child: const SvgIcon(
                                iconPath: AppIcons.basket,
                                size: 40,
                                color: Colors.grey),
                          ),
                    if (outOfStock)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            langVM.translate('out_of_stock'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Puan Ortalaması (Sol Üst)
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: AuthService.instance
                                .getProductReviews(product['id']),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              final reviews = snapshot.data!;
                              double total = 0;
                              for (var r in reviews) {
                                total += (r['rating'] as num).toDouble();
                              }
                              double avg = total / reviews.length;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star,
                                        size: 12, color: Colors.amber),
                                    const SizedBox(width: 2),
                                    Text(
                                      avg.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          // En Yakın Etiketi
                          if (widget.isPriority)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.white, size: 10),
                                  const SizedBox(width: 4),
                                  Text(
                                    langVM.translate('sort_smart'),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Stok Durumu Etiketi
                          if (outOfStock || isLowStock)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: outOfStock
                                    ? Colors.black.withOpacity(0.7)
                                    : Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                langVM.translate(outOfStock
                                    ? 'out_of_stock'
                                    : 'critical_stock'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          final authVM = context.read<AuthViewModel>();
                          if (await authVM.checkGuestStatus(context)) {
                            widget.onFavoriteToggle();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: widget.isFavorite ? Colors.red : Colors.grey,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (index) {
                            return Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? theme.colorScheme.primary
                                    : Colors.white.withOpacity(0.8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Ürün Bilgileri
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$price ₺',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                          ),
                        ),
                        TextSpan(
                          text: ' / ${langVM.translate(unit)}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                            fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToDetail(BuildContext context) async {
    // Satıcı adını bul
    String sellerName = 'Satıcı';
    if (widget.product['sellerId'] != null) {
      try {
        final sellerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.product['sellerId'])
            .get();
        if (sellerDoc.exists) {
          final sData = sellerDoc.data()!;
          sellerName = sData['stallName'] ??
              '${sData['firstName']} ${sData['lastName']}';
        }
      } catch (_) {}
    }

    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            product: widget.product,
            sellerName: sellerName,
          ),
        ),
      );
      // Detay sayfasından dönüldüğünde tetiklenecek callback (örn: favorileri yenilemek için)
      if (widget.onDetailReturn != null) {
        widget.onDetailReturn!();
      }
    }
  }

  void _showQuickPreview(BuildContext context) {
    final theme = Theme.of(context);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final imagePath = widget.product['imagePath'];
    final price = widget.product['price'];
    final unit = widget.product['unit'] ?? 'unit_kg';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                      child: SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: (imagePath != null && imagePath.isNotEmpty)
                            ? (imagePath.startsWith('http')
                                ? Image.network(
                                    imagePath,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image,
                                                color: Colors.grey, size: 50),
                                  )
                                : Image.file(
                                    File(imagePath),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image,
                                                color: Colors.grey, size: 50),
                                  ))
                            : const Icon(Icons.shopping_basket,
                                color: Colors.grey, size: 80),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product['name'] ?? '',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$price ₺ / ${langVM.translate(unit)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (widget.product['description'] != null &&
                          widget.product['description']
                              .toString()
                              .isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.product['description'],
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _navigateToDetail(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Detayları Gör'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
