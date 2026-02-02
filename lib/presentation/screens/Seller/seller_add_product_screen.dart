import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/success_dialog.dart';

class SellerAddProductScreen extends StatefulWidget {
  final SellerProduct? productToEdit;
  const SellerAddProductScreen({super.key, this.productToEdit});

  @override
  State<SellerAddProductScreen> createState() => _SellerAddProductScreenState();
}

class _SellerAddProductScreenState extends State<SellerAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedCategory;
  String _selectedUnit = 'unit_kg';
  bool _inStock = true;

  final List<String> _categories = [
    'category_fruit',
    'category_vegetable',
    'category_delicatessen',
  ];

  final Map<String, IconData> _categoryIcons = {
    'category_fruit': Icons.eco,
    'category_vegetable': Icons.grass,
    'category_delicatessen': Icons.breakfast_dining,
  };

  final List<String> _units = [
    'unit_kg',
    'unit_piece',
    'unit_bunch',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      final p = widget.productToEdit!;
      _nameController.text = p.name;
      _descController.text = p.description;
      _priceController.text = p.price.toString();
      _stockController.text = p.stockQuantity.toString();
      _selectedCategory = p.category;
      _selectedUnit = p.unit;
      _inStock = p.inStock;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final sellerVM = Provider.of<SellerViewModel>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Düzenleme Modunda Mevcut Resmi Göster
            if (widget.productToEdit != null &&
                widget.productToEdit!.imagePath != null &&
                sellerVM.selectedImages.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.productToEdit!.imagePath!,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Mevcut fotoğraf. Değiştirmek için aşağıdan yeni fotoğraf seçiniz.",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            // Fotoğraf Alanı
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: sellerVM.selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return GestureDetector(
                      onTap: () => sellerVM.pickImage(ImageSource.gallery),
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo, color: Colors.grey),
                            const SizedBox(height: 4),
                            Text(langVM.translate('add_photo_button'),
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }
                  final image = sellerVM.selectedImages[index - 1];
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(image.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => sellerVM.removeImage(index - 1),
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: langVM.translate('product_name_label'),
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  v!.isEmpty ? langVM.translate('error_prefix') : null,
            ),
            const SizedBox(height: 16),
            FormField<String>(
              validator: (value) {
                if (_selectedCategory == null) {
                  return langVM.translate('category_error');
                }
                return null;
              },
              builder: (FormFieldState<String> state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langVM.translate('category_label'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final categoryKey = _categories[index];
                        final isSelected = _selectedCategory == categoryKey;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = categoryKey);
                            state.didChange(categoryKey);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _categoryIcons[categoryKey],
                                  size: 32,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  langVM.translate(categoryKey),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                        child: Text(
                          state.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: langVM.translate('product_price_label'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: langVM.translate('stock_quantity_label'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedUnit,
              decoration: InputDecoration(
                labelText: langVM.translate('unit_label'),
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              ),
              items: _units
                  .map((u) => DropdownMenuItem(
                      value: u, child: Text(langVM.translate(u))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedUnit = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: langVM.translate('stall_location_label'),
                hintText: langVM.translate('stall_location_hint'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(langVM.translate('stock_status_label')),
              subtitle: Text(
                  langVM.translate(_inStock ? 'in_stock' : 'out_of_stock')),
              value: _inStock,
              onChanged: (val) => setState(() => _inStock = val),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: sellerVM.isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        if (widget.productToEdit != null) {
                          // GÜNCELLEME İŞLEMİ
                          await sellerVM.updateProduct(
                            id: widget.productToEdit!.id,
                            name: _nameController.text,
                            description: _descController.text,
                            price: double.tryParse(_priceController.text) ?? 0,
                            category: _selectedCategory!,
                            stockQuantity:
                                double.tryParse(_stockController.text) ?? 0,
                            unit: _selectedUnit,
                            inStock: _inStock,
                            currentImagePath: widget.productToEdit!.imagePath,
                          );
                          if (mounted) {
                            Navigator.pop(context); // Sayfayı kapat
                          }
                        } else {
                          // EKLEME İŞLEMİ
                          await sellerVM.addProduct(
                            name: _nameController.text,
                            description: _descController.text,
                            price: double.tryParse(_priceController.text) ?? 0,
                            stallLocation: _locationController.text,
                            category: _selectedCategory!,
                            stockQuantity:
                                double.tryParse(_stockController.text) ?? 0,
                            unit: _selectedUnit,
                            inStock: _inStock,
                          );
                          if (mounted) {
                            await showSuccessDialog(
                              context,
                              message:
                                  langVM.translate('success_product_added'),
                            );
                            _nameController.clear();
                            _priceController.clear();
                            _stockController.clear();
                            _locationController.clear();
                            setState(() {
                              _selectedCategory = null;
                              _selectedUnit = 'unit_kg';
                              _inStock = true;
                            });
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: sellerVM.isLoading
                  ? const CircularProgressIndicator()
                  : Text(widget.productToEdit != null
                      ? langVM.translate('update_button')
                      : langVM.translate('publish_product_button')),
            ),
          ],
        ),
      ),
    );
  }
}
