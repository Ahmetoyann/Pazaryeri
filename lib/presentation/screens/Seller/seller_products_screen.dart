import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import 'seller_add_product_screen.dart';
import 'seller_product_management_screen.dart';
import '../../widgets/success_dialog.dart';

class SellerProductsScreen extends StatefulWidget {
  const SellerProductsScreen({super.key});

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
    'category_other',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Listenin sonuna 200 piksel kala yeni verileri yükle
      final sellerVM = Provider.of<SellerViewModel>(context, listen: false);
      if (!sellerVM.isLoadingMore && sellerVM.hasMoreProducts) {
        sellerVM.loadMoreProducts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerVM = Provider.of<SellerViewModel>(context);
    final langVM = Provider.of<LanguageViewModel>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: DropdownButtonFormField<String>(
            value: sellerVM.categoryFilter,
            hint: Text(langVM.translate('filter_by_category'),
                style: TextStyle(color: Colors.white.withOpacity(0.7))),
            isExpanded: true,
            dropdownColor: const Color(0xFF1B5E20).withOpacity(0.95),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
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
              ..._categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(langVM.translate(category)),
                );
              }).toList(),
            ],
            onChanged: (value) {
              sellerVM.setCategoryFilter(value);
            },
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
      return const Center(child: CircularProgressIndicator());
    }

    if (sellerVM.myProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(langVM.translate('no_products_yet')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => sellerVM.loadProducts(),
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
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox(height: 80); // Bottom bar boşluğu
          }

          final product = sellerVM.myProducts[index];
          return Dismissible(
            key: ValueKey(product.id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 16),
              color: Theme.of(context).colorScheme.error,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await DialogService.showConfirmation(
                context,
                title: langVM.translate('delete_product_title'),
                message: langVM.translate('delete_product_confirm'),
                confirmText: langVM.translate('yes'),
                cancelText: langVM.translate('no'),
                icon: Icons.delete_forever,
              );
            },
            onDismissed: (direction) {
              sellerVM.removeProduct(product.id);
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(8),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product.imagePath != null &&
                          product.imagePath!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: product.imagePath!.startsWith('http')
                              ? Image.network(
                                  product.imagePath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error),
                                )
                              : Image.file(
                                  File(product.imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error),
                                ),
                        )
                      : Icon(Icons.image,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.4)),
                ),
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${product.price} ₺ / ${langVM.translate(product.unit ?? 'unit_kg')}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${langVM.translate('stock_quantity_label')}: ${product.stockQuantity} ${langVM.translate(product.unit ?? 'unit_kg')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: Switch(
                  value: product.inStock,
                  onChanged: (val) {
                    sellerVM.toggleProductStock(product.id);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              val
                                  ? Icons.check_circle
                                  : Icons.remove_circle_outline,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                langVM.translate(val
                                    ? 'product_stock_active'
                                    : 'product_stock_inactive'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor:
                            val ? Colors.green : Colors.grey.shade700,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(
                            bottom: 100, left: 16, right: 16),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  activeColor: Colors.white,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.5),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SellerProductManagementScreen(product: product),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
