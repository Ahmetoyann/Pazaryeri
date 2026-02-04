import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import 'seller_add_product_screen.dart';

class SellerProductManagementScreen extends StatefulWidget {
  final SellerProduct product;

  const SellerProductManagementScreen({super.key, required this.product});

  @override
  State<SellerProductManagementScreen> createState() =>
      _SellerProductManagementScreenState();
}

class _SellerProductManagementScreenState
    extends State<SellerProductManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _salesController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _stockController =
        TextEditingController(text: widget.product.stockQuantity.toString());
    _salesController =
        TextEditingController(text: widget.product.salesCount.toString());
  }

  @override
  void dispose() {
    _priceController.dispose();
    _stockController.dispose();
    _salesController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(String label, IconData icon,
      {String? suffixText, String? helperText}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixText: suffixText,
      helperText: helperText,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.5), width: 2)),
    );
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final double price = double.parse(_priceController.text);
      final double stock = double.parse(_stockController.text);
      final int sales = int.parse(_salesController.text);

      // Firestore güncellemesi
      await AuthService.instance.updateProductInDb(widget.product.id, {
        'price': price,
        'stockQuantity': stock,
        'salesCount': sales,
      });

      // ViewModel'i yenile (Listeyi ve istatistikleri güncellemek için)
      if (mounted) {
        await Provider.of<SellerViewModel>(context, listen: false)
            .loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Ürün bilgileri ve istatistikler güncellendi')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gelir hesaplaması (Fiyat * Satış Adedi)
    double currentPrice = double.tryParse(_priceController.text) ?? 0;
    int currentSales = int.tryParse(_salesController.text) ?? 0;
    double revenue = currentPrice * currentSales;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Detaylı Düzenle',
            onPressed: () {
              // İsim, resim vb. değiştirmek için eski sayfaya yönlendir
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SellerAddProductScreen(productToEdit: widget.product),
                ),
              ).then((_) {
                Navigator.pop(context);
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hızlı Düzenleme & İstatistik',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),

              // Fiyat
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _buildInputDecoration(
                    'Birim Fiyat (₺)', Icons.price_change),
                onChanged: (val) => setState(() {}),
                validator: (v) => v!.isEmpty ? 'Fiyat giriniz' : null,
              ),
              const SizedBox(height: 16),

              // Stok
              TextFormField(
                controller: _stockController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _buildInputDecoration(
                    'Stok Miktarı', Icons.inventory,
                    suffixText: widget.product.unit),
                validator: (v) => v!.isEmpty ? 'Stok giriniz' : null,
              ),
              const SizedBox(height: 16),

              // Satış Adedi (Gelir için)
              TextFormField(
                controller: _salesController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration(
                    'Toplam Satış Miktarı', Icons.shopping_cart,
                    helperText: 'Gelir bu değere göre hesaplanır'),
                onChanged: (val) => setState(() {}),
                validator: (v) => v!.isEmpty ? 'Satış adedi giriniz' : null,
              ),
              const SizedBox(height: 24),

              // Gelir Gösterimi
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, size: 32),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Toplam Gelir'),
                          Text(
                            '${revenue.toStringAsFixed(2)} ₺',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProduct,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Güncelle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
