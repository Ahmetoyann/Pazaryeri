import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import 'seller_add_product_screen.dart';

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
            hint: Text(langVM.translate('filter_by_category')),
            isExpanded: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
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
            const Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey),
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
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(langVM.translate('delete_product_title')),
                  content: Text(langVM.translate('delete_product_confirm')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(langVM.translate('no')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(langVM.translate('yes')),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) {
              sellerVM.removeProduct(product.id);
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.all(8),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    image: product.imagePath != null
                        ? DecorationImage(
                            image: NetworkImage(product.imagePath!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: product.imagePath == null
                      ? const Icon(Icons.image, color: Colors.grey)
                      : null,
                ),
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${product.price} ₺ / ${langVM.translate(product.unit)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${langVM.translate('stock')}: ${product.stockQuantity} ${langVM.translate(product.unit)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: Switch(
                  value: product.inStock,
                  onChanged: (val) => sellerVM.toggleProductStock(product.id),
                  activeColor: Colors.green,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SellerAddProductScreen(productToEdit: product),
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
