import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import 'seller_add_product_screen.dart';
import 'seller_product_management_screen.dart';
import '../../widgets/success_dialog.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_bottom_sheets.dart';
import '../../widgets/custom_snackbars.dart';
import '../../widgets/empty_state_view.dart';

class SellerProductsScreen extends StatefulWidget {
  final VoidCallback? onSwitchToAddProductTab;

  const SellerProductsScreen({super.key, this.onSwitchToAddProductTab});

  @override
  State<SellerProductsScreen> createState() => _SellerProductsScreenState();
}

class _SellerProductsScreenState extends State<SellerProductsScreen> {
  final ScrollController _scrollController = ScrollController();

  // Kategori listesi (SellerAddProductScreen'den alındı)
  final List<String> _categories = [
    'category_fruit',
    'category_vegetable',
    'category_delicatessen',
    'category_dairy',
    'category_bakery',
    'category_spices',
    'category_fish',
    'category_clothing',
    'category_electronics',
    'category_second_hand',
    'category_animals',
    'category_home',
    'category_toys',
    'category_books',
    'category_tools',
    'category_plants',
    'category_handmade',
    'category_cosmetics',
    'category_sports',
    'category_automotive',
    'category_antiques',
    'category_jewelry',
    'category_art',
    'category_baby',
    'category_music',
    'category_office',
    'category_other',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Sayfa açıldığında ürünleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SellerViewModel>(context, listen: false).loadProducts();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Listenin sonuna 200 piksel kala yeni verileri yükle
      final sellerVM = Provider.of<SellerViewModel>(context, listen: false);
      if (!sellerVM.isLoadingMore && sellerVM.hasMoreProducts) {
        sellerVM.loadMoreProducts().catchError((e) {
          debugPrint('Error loading more products: $e');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerVM = Provider.of<SellerViewModel>(context);
    final langVM = Provider.of<LanguageViewModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).cardColor;
    final contentColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: sellerVM.categoryFilter,
                hint: Text(langVM.translate('filter_by_category'),
                    style: TextStyle(color: contentColor.withOpacity(0.7))),
                isExpanded: true,
                icon: Icon(Icons.filter_list, color: contentColor),
                style: TextStyle(color: contentColor, fontSize: 16),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(langVM.translate('filter_all'),
                        style: TextStyle(color: contentColor)),
                  ),
                  ..._categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(langVM.translate(category),
                          style: TextStyle(color: contentColor)),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  sellerVM.setCategoryFilter(value);
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildProductList(sellerVM, langVM),
        ),
      ],
    );
  }

  Widget _buildProductList(SellerViewModel sellerVM, LanguageViewModel langVM) {
    if (sellerVM.isLoading && sellerVM.myProducts.isEmpty) {
      return const Center(child: CustomLoadingIndicator());
    }

    if (sellerVM.myProducts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => sellerVM.loadProducts(),
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: EmptyStateView(
                iconPath: AppIcons.inventory,
                title: 'Henüz ürününüz yok',
                message: 'Satışa başlamak için ilk ürününüzü ekleyin.',
                actionLabel: 'İlk Ürünü Ekle',
                actionIcon: Icons.add_shopping_cart_rounded,
                onActionPressed: () {
                  if (widget.onSwitchToAddProductTab != null) {
                    widget.onSwitchToAddProductTab!();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellerAddProductScreen(
                          onProductAdded: () {
                            sellerVM.loadProducts();
                          },
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        try {
          await sellerVM.loadProducts();
        } catch (e) {
          debugPrint('Error refreshing products: $e');
        }
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        // +1 loading indicator için
        itemCount: sellerVM.myProducts.length + 1,
        itemBuilder: (context, index) {
          // Loading Indicator (Listenin en altı)
          if (index == sellerVM.myProducts.length) {
            return sellerVM.isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CustomLoadingIndicator(size: 40)),
                  )
                : const SizedBox(height: 140);
          }

          final product = sellerVM.myProducts[index];
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return Dismissible(
            key: ValueKey(product.id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const SvgIcon(
                  iconPath: AppIcons.delete, color: Colors.white, size: 28),
            ),
            confirmDismiss: (direction) async {
              return true; // "Emin misiniz?" sormadan anında sil
            },
            onDismissed: (direction) async {
              final productId = product.id;
              final scaffoldMessenger = ScaffoldMessenger.of(this.context);
              final localLang = langVM;

              // Geri alabilmek için silinmeden önce Firestore'dan yedeğini alıyoruz
              Map<String, dynamic>? deletedData;
              try {
                final docSnap = await FirebaseFirestore.instance
                    .collection('products')
                    .doc(productId)
                    .get();
                deletedData = docSnap.data();

                await sellerVM.removeProduct(productId);
              } catch (e) {
                debugPrint('Error removing product: $e');
              }

              if (mounted) {
                CustomSnackbars.showUndo(
                  this.context,
                  localLang.translate('success_product_deleted'),
                  () async {
                    if (deletedData != null) {
                      await FirebaseFirestore.instance
                          .collection('products')
                          .doc(productId)
                          .set(deletedData);
                      if (mounted) await sellerVM.loadProducts();
                    }
                  },
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SellerProductManagementScreen(product: product),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Ürün Resmi
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: product.imagePath != null &&
                                  product.imagePath!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: product.imagePath!.startsWith('http')
                                      ? Image.network(
                                          product.imagePath!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                                Icons.broken_image,
                                                color: Colors.grey);
                                          },
                                        )
                                      : Image.file(
                                          File(product.imagePath!),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.broken_image,
                                                      color: Colors.grey),
                                        ),
                                )
                              : Center(
                                  child: SvgIcon(
                                    iconPath: AppIcons.products,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.4),
                                    size: 36,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        // Bilgiler
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${product.price} ₺ / ${langVM.translate(product.unit ?? 'unit_kg')}',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: product.stockQuantity > 0
                                          ? theme.colorScheme.primary
                                              .withOpacity(0.1)
                                          : theme.colorScheme.error
                                              .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${langVM.translate('stock_quantity_label')}: ${product.stockQuantity.toInt()}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: product.stockQuantity > 0
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Switch
                        Column(
                          children: [
                            Switch(
                              value: product.inStock,
                              onChanged: (val) async {
                                if (!val) {
                                  final bool confirm =
                                      await DialogService.showConfirmation(
                                    context,
                                    title: 'Satışı Durdur',
                                    message:
                                        'Bu ürünün satışını durdurmak istediğinize emin misiniz?',
                                    confirmText: langVM.translate('yes'),
                                    cancelText: langVM.translate('no'),
                                    icon: Icons.pause_circle_filled,
                                    confirmColor: theme.colorScheme.primary,
                                  );
                                  if (!confirm) return;
                                }

                                await LoadingOverlay.show(
                                  context,
                                  asyncFunction: () async {
                                    try {
                                      await sellerVM
                                          .toggleProductStock(product.id);
                                      if (!context.mounted) return;

                                      if (val) {
                                        CustomSnackbars.showSuccess(
                                            context,
                                            langVM.translate(
                                                'product_stock_active'));
                                      } else {
                                        CustomSnackbars.showInfo(
                                            context,
                                            langVM.translate(
                                                'product_stock_inactive'));
                                      }
                                    } catch (e) {
                                      debugPrint('Error toggling stock: $e');
                                    }
                                  },
                                );
                              },
                              activeColor: theme.colorScheme.primary,
                              activeTrackColor:
                                  theme.colorScheme.primary.withOpacity(0.2),
                              inactiveThumbColor: Colors.grey.shade400,
                              inactiveTrackColor: Colors.grey.withOpacity(0.2),
                            ),
                            Text(
                              product.inStock ? 'Aktif' : 'Pasif',
                              style: TextStyle(
                                fontSize: 11,
                                color: product.inStock
                                    ? theme.colorScheme.primary
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
