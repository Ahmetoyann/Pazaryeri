import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/success_dialog.dart';

class SellerAddProductScreen extends StatefulWidget {
  final SellerProduct? productToEdit;
  final VoidCallback? onProductAdded;
  const SellerAddProductScreen(
      {super.key, this.productToEdit, this.onProductAdded});

  @override
  State<SellerAddProductScreen> createState() => _SellerAddProductScreenState();
}

class _SellerAddProductScreenState extends State<SellerAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedCategory;
  String _selectedUnit = 'unit_kg';
  bool _inStock = true;

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

  final Map<String, Color> _categoryColors = {
    'category_fruit': Colors.orange,
    'category_vegetable': Colors.green,
    'category_delicatessen': Colors.redAccent,
    'category_dairy': Colors.blue,
    'category_bakery': Colors.amber.shade700,
    'category_spices': Colors.deepOrange,
    'category_fish': Colors.teal,
    'category_clothing': Colors.purple,
    'category_other': Colors.blueGrey,
  };

  final List<String> _units = [
    'unit_kg',
    'unit_piece',
    'unit_bunch',
    'unit_package',
    'unit_box',
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
    } else {
      _stockController.text = '1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showImagePicker(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final sellerVM = Provider.of<SellerViewModel>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(langVM.translate('camera')),
              onTap: () {
                Navigator.pop(ctx);
                sellerVM.pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(langVM.translate('gallery')),
              onTap: () {
                Navigator.pop(ctx);
                sellerVM.pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
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

  Future<void> _handleFormSubmit(SellerViewModel sellerVM,
      LanguageViewModel langVM, bool stayOnPage) async {
    if (_formKey.currentState!.validate()) {
      if (widget.productToEdit != null) {
        // GÜNCELLEME İŞLEMİ
        await sellerVM.updateProduct(
          id: widget.productToEdit!.id,
          name: _nameController.text,
          description: _descController.text,
          price: double.tryParse(_priceController.text) ?? 0,
          category: _selectedCategory!,
          stockQuantity: double.tryParse(_stockController.text) ?? 0,
          unit: _selectedUnit,
          inStock: _inStock,
          currentImagePath: widget.productToEdit!.imagePath,
        );

        await sellerVM.loadProducts();

        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        // EKLEME İŞLEMİ
        await sellerVM.addProduct(
          name: _nameController.text,
          description: _descController.text,
          price: double.tryParse(_priceController.text) ?? 0,
          category: _selectedCategory!,
          stockQuantity: double.tryParse(_stockController.text) ?? 0,
          unit: _selectedUnit,
          inStock: _inStock,
        );

        await sellerVM.loadProducts();

        if (mounted) {
          await DialogService.showSuccess(
            context,
            message: langVM.translate('success_product_added'),
          );
          _nameController.clear();
          _priceController.clear();
          _stockController.text = '1';
          _descController.clear();
          setState(() {
            _selectedCategory = null;
            _selectedUnit = 'unit_kg';
            _inStock = true;
          });
          // Görselleri temizle
          while (sellerVM.selectedImages.isNotEmpty) {
            sellerVM.removeImage(0);
          }

          if (!stayOnPage) {
            widget.onProductAdded?.call();
          }
        }
      }
    }
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
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        widget.productToEdit!.imagePath!,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Mevcut fotoğraf. Değiştirmek için aşağıdan yeni fotoğraf seçiniz.",
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            // Fotoğraf Alanı
            GestureDetector(
              onTap: () => _showImagePicker(context),
              child: Container(
                height: 150,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo,
                        size: 48,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text(
                      langVM.translate('add_photo_button'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (sellerVM.selectedImages.isNotEmpty)
              Container(
                height: 120,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: sellerVM.selectedImages.length,
                  itemBuilder: (context, index) {
                    final image = sellerVM.selectedImages[index];
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: FileImage(File(image.path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 16,
                          child: GestureDetector(
                            onTap: () => sellerVM.removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 14, color: Colors.white),
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
              decoration:
                  _buildInputDecoration(langVM.translate('product_name_label')),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return langVM.translate('error_prefix');
                }
                if (v.length < 3) return 'En az 3 karakter giriniz';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration:
                  _buildInputDecoration(langVM.translate('product_desc_label')),
            ),
            const SizedBox(height: 24),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
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
                        final color = _categoryColors[categoryKey] ??
                            Theme.of(context).primaryColor;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = categoryKey);
                            state.didChange(categoryKey);
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected
                                        ? color
                                        : Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _categoryIcons[categoryKey],
                                        size: 32,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      langVM.translate(categoryKey),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? color
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: color,
                                      size: 24,
                                    ),
                                  ),
                                ),
                            ],
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
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: _buildInputDecoration(
                        langVM.translate('product_price_label')),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return langVM.translate('error_prefix');
                      }
                      final val = double.tryParse(v);
                      if (val == null || val <= 0)
                        return langVM.translate('error_prefix');
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDecoration(
                        langVM.translate('stock_quantity_label')),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return langVM.translate('error_prefix');
                      }
                      final val = double.tryParse(v);
                      if (val == null || val <= 0)
                        return langVM.translate('error_prefix');
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedUnit,
              dropdownColor: const Color(0xFF1B5E20).withOpacity(0.95),
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration(langVM.translate('unit_label')),
              items: _units
                  .map((u) => DropdownMenuItem(
                      value: u, child: Text(langVM.translate(u))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedUnit = v!),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              tileColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: Colors.white.withOpacity(0.3))),
              title: Text(langVM.translate('stock_status_label')),
              subtitle: Text(
                  langVM.translate(_inStock ? 'in_stock' : 'out_of_stock')),
              value: _inStock,
              onChanged: (val) => setState(() => _inStock = val),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (widget.productToEdit == null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: sellerVM.isLoading
                          ? null
                          : () => _handleFormSubmit(sellerVM, langVM, true),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        langVM.translate('save_and_add_new'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: sellerVM.isLoading
                        ? null
                        : () => _handleFormSubmit(sellerVM, langVM, false),
                    child: sellerVM.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            widget.productToEdit != null
                                ? langVM.translate('update_button')
                                : langVM.translate('publish_product_button'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
