import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/success_dialog.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_sheets.dart';
import '../../widgets/custom_snackbars.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';
import '../../widgets/loading_overlay.dart';

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
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _originalDescText = '';

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

  final Map<String, String> _categoryPaths = {
    'category_fruit': AppIcons.fruit,
    'category_vegetable': AppIcons.vegetable,
    'category_delicatessen': AppIcons.delicatessen,
    'category_dairy': AppIcons.dairy,
    'category_bakery': AppIcons.bakery,
    'category_spices': AppIcons.spices,
    'category_fish': AppIcons.fish,
    'category_clothing': AppIcons.clothing,
    'category_electronics': AppIcons.electronics,
    'category_second_hand': AppIcons.secondHand,
    'category_animals': AppIcons.animals,
    'category_home': AppIcons.homeLiving,
    'category_toys': AppIcons.toys,
    'category_books': AppIcons.books,
    'category_tools': AppIcons.tools,
    'category_plants': AppIcons.plants,
    'category_handmade': AppIcons.handmade,
    'category_cosmetics': AppIcons.cosmetics,
    'category_sports': AppIcons.sports,
    'category_automotive': AppIcons.automotive,
    'category_antiques': AppIcons.antiques,
    'category_jewelry': AppIcons.jewelry,
    'category_art': AppIcons.art,
    'category_baby': AppIcons.baby,
    'category_music': AppIcons.music,
    'category_office': AppIcons.office,
    'category_other': AppIcons.other,
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
    _speech = stt.SpeechToText();
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

    CustomBottomSheets.showImagePicker(
      context: context,
      cameraText: langVM.translate('camera'),
      galleryText: langVM.translate('gallery'),
      onCameraTap: () => sellerVM.pickImage(ImageSource.camera),
      onGalleryTap: () => sellerVM.pickImage(ImageSource.gallery),
    );
  }

  void _toggleListen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
            }
          }
        },
        onError: (val) {
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
          _originalDescText = _descController.text;
        });
        _speech.listen(
          onResult: (val) => setState(() {
            final newText = val.recognizedWords;
            _descController.text = _originalDescText.isEmpty
                ? newText
                : '$_originalDescText $newText';
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  InputDecoration _buildInputDecoration(String label, String? iconPath) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: iconPath != null
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: SvgIcon(
                  iconPath: iconPath,
                  color: theme.colorScheme.primary,
                  size: 24))
          : null,
      filled: true,
      fillColor: isDark ? theme.cardColor : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
      ),
    );
  }

  void _showCategoryPicker(
      FormFieldState<String> state, Map<String, Color> categoryColors) {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    langVM.translate('category_label'),
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final categoryKey = _categories[index];
                      final isSelected = _selectedCategory == categoryKey;
                      final color =
                          categoryColors[categoryKey] ?? theme.primaryColor;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = categoryKey);
                          state.didChange(categoryKey);
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? color : color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : theme.colorScheme.primary.withOpacity(0.2),
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgIcon(
                                iconPath: _categoryPaths[categoryKey]!,
                                size: 32,
                                color: isSelected ? Colors.white : color,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                langVM.translate(categoryKey),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.8),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleFormSubmit(SellerViewModel sellerVM,
      LanguageViewModel langVM, bool stayOnPage) async {
    // İşlem başlamadan önce klavyeyi kapat
    FocusScope.of(context).unfocus();

    // 1. Resim Kontrolü
    bool hasImage = sellerVM.selectedImages.isNotEmpty ||
        (widget.productToEdit != null &&
            widget.productToEdit!.imagePath != null &&
            widget.productToEdit!.imagePath!.isNotEmpty);

    if (!hasImage) {
      CustomSnackbars.showError(context, langVM.translate('add_photo_error'));
      return;
    }

    // 2. Form Validasyonu
    if (!_formKey.currentState!.validate()) {
      CustomSnackbars.showError(
          context, langVM.translate('fill_all_fields_error'));
      return;
    }

    // Stok kontrolü: 0 ise satışı durdur
    final double stock = double.tryParse(_stockController.text) ?? 0;
    if (stock <= 0) {
      _inStock = false;
    }

    try {
      if (widget.productToEdit != null) {
        // GÜNCELLEME İŞLEMİ
        await LoadingOverlay.show(
          context,
          asyncFunction: () async {
            await sellerVM.updateProduct(
              id: widget.productToEdit!.id,
              name: _nameController.text,
              description: _descController.text,
              price: double.tryParse(_priceController.text) ?? 0,
              category: _selectedCategory!,
              stockQuantity: stock,
              unit: _selectedUnit,
              inStock: _inStock,
              currentImagePath: widget.productToEdit!.imagePath,
            );
            await sellerVM.loadProducts();
          },
        );

        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        // EKLEME İŞLEMİ
        await LoadingOverlay.show(
          context,
          asyncFunction: () async {
            await sellerVM.addProduct(
              name: _nameController.text,
              description: _descController.text,
              price: double.tryParse(_priceController.text) ?? 0,
              category: _selectedCategory!,
              stockQuantity: stock,
              unit: _selectedUnit,
              inStock: _inStock,
            );
            await sellerVM.loadProducts();
          },
        );

        if (mounted) {
          await DialogService.showSuccess(
            context,
            message: langVM.translate('success_product_added'),
          );

          if (stayOnPage) {
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
          } else {
            // Eğer sayfa push edildiyse (örn: düzenleme veya yeni sayfa) geri dön
            if (Navigator.canPop(context)) {
              widget.onProductAdded?.call();
              Navigator.pop(context);
            } else {
              // Tab içindeyse (geri gidilecek yer yoksa) formu temizle
              _nameController.clear();
              _priceController.clear();
              _stockController.text = '1';
              _descController.clear();
              setState(() {
                _selectedCategory = null;
                _selectedUnit = 'unit_kg';
                _inStock = true;
              });
              while (sellerVM.selectedImages.isNotEmpty) {
                sellerVM.removeImage(0);
              }
              // Yönlendirme (Tab değişimi) için callback'i çağır
              widget.onProductAdded?.call();
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showError(
            context, '${langVM.translate('error_prefix')}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final sellerVM = Provider.of<SellerViewModel>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Map<String, Color> categoryColors = isDark
        ? {
            'category_fruit': Colors.orange,
            'category_vegetable': Colors.green,
            'category_delicatessen': Colors.redAccent,
            'category_dairy': Colors.blue,
            'category_bakery': Colors.amber.shade700,
            'category_spices': Colors.deepOrange,
            'category_fish': Colors.teal,
            'category_clothing': Colors.purple,
            'category_electronics': Colors.blueGrey,
            'category_second_hand': Colors.brown,
            'category_animals': Colors.orangeAccent,
            'category_home': Colors.teal,
            'category_toys': Colors.pinkAccent,
            'category_books': Colors.indigo,
            'category_tools': Colors.grey,
            'category_plants': Colors.lightGreen,
            'category_handmade': Colors.purpleAccent,
            'category_cosmetics': Colors.pink,
            'category_sports': Colors.lightBlue,
            'category_automotive': Colors.red,
            'category_antiques': Colors.amberAccent,
            'category_jewelry': Colors.cyan,
            'category_art': Colors.deepPurple,
            'category_baby': Colors.lightBlueAccent,
            'category_music': Colors.deepOrangeAccent,
            'category_office': Colors.blueGrey,
            'category_other': Colors.blueGrey,
          }
        : {
            'category_fruit': const Color(0xFFFFB74D), // Orange 300
            'category_vegetable': const Color(0xFF81C784), // Green 300
            'category_delicatessen': const Color(0xFFE57373), // Red 300
            'category_dairy': const Color(0xFF64B5F6), // Blue 300
            'category_bakery': const Color(0xFFFFD54F), // Amber 300
            'category_spices': const Color(0xFFFF8A65), // DeepOrange 300
            'category_fish': const Color(0xFF4DB6AC), // Teal 300
            'category_clothing': const Color(0xFFBA68C8), // Purple 300
            'category_electronics': const Color(0xFF90A4AE), // BlueGrey 300
            'category_second_hand': const Color(0xFFA1887F), // Brown 300
            'category_animals': const Color(0xFFFFCC80), // OrangeAccent 100
            'category_home': const Color(0xFF4DB6AC), // Teal 300
            'category_toys': const Color(0xFFF48FB1), // Pink 200
            'category_books': const Color(0xFF7986CB), // Indigo 300
            'category_tools': const Color(0xFFBDBDBD), // Grey 400
            'category_plants': const Color(0xFFAED581), // LightGreen 300
            'category_handmade': const Color(0xFFCE93D8), // Purple 200
            'category_cosmetics': const Color(0xFFF06292), // Pink 300
            'category_sports': const Color(0xFF4FC3F7), // LightBlue 300
            'category_automotive': const Color(0xFFE57373), // Red 300
            'category_antiques': const Color(0xFFFFD54F), // Amber 300
            'category_jewelry': const Color(0xFF4DD0E1), // Cyan 300
            'category_art': const Color(0xFF9575CD), // DeepPurple 300
            'category_baby': const Color(0xFF4FC3F7), // LightBlue 300
            'category_music': const Color(0xFFFF8A65), // DeepOrange 300
            'category_office': const Color(0xFF90A4AE), // BlueGrey 300
            'category_other': const Color(0xFF90A4AE), // BlueGrey 300
          };

    return Scaffold(
      appBar: widget.productToEdit != null
          ? CustomAppBar(title: Text(langVM.translate('edit_product_title')))
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
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
                          langVM.translate('existing_photo_hint'),
                          style: TextStyle(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
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
                    color: isDark ? theme.cardColor : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgIcon(
                          iconPath: AppIcons.camera,
                          size: 56,
                          color: theme.colorScheme.primary.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        langVM.translate('add_photo_button'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                                child: const SvgIcon(
                                    iconPath: AppIcons.close,
                                    size: 18,
                                    color: Colors.white),
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
                decoration: _buildInputDecoration(
                    // İkon eklemedik, sade kalsın veya AppIcons.products eklenebilir
                    langVM.translate('product_name_label'),
                    null),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return langVM.translate('error_prefix');
                  }
                  if (v.length < 3)
                    return langVM.translate('min_3_chars_error');
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: _buildInputDecoration(
                        langVM.translate('product_desc_label'), null)
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    color: _isListening ? Colors.red : Colors.grey,
                    onPressed: _toggleListen,
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? langVM.translate('error_required')
                    : null,
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
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _showCategoryPicker(state, categoryColors),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color:
                                isDark ? theme.cardColor : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: state.hasError
                                ? Border.all(color: theme.colorScheme.error)
                                : Border.all(
                                    color: theme.dividerColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              if (_selectedCategory != null) ...[
                                SvgIcon(
                                  iconPath: _categoryPaths[_selectedCategory]!,
                                  size: 24,
                                  color: categoryColors[_selectedCategory] ??
                                      theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    langVM.translate(_selectedCategory!),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ] else
                                Expanded(
                                  child: Text(
                                    langVM.translate('category_label'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              Icon(Icons.arrow_drop_down,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6)),
                            ],
                          ),
                        ),
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                          child: Text(
                            state.errorText!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
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
                          langVM.translate('product_price_label'),
                          null), // Fiyat ikonu yok, null
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
                          langVM.translate('stock_quantity_label'),
                          AppIcons.inventory),
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
                dropdownColor: theme.cardColor,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration:
                    _buildInputDecoration(langVM.translate('unit_label'), null),
                items: _units
                    .map((u) => DropdownMenuItem(
                        value: u, child: Text(langVM.translate(u))))
                    .toList(),
                onChanged: (v) => setState(() => _selectedUnit = v!),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? theme.cardColor : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: theme.dividerColor.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SwitchListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text(langVM.translate('stock_status_label')),
                  subtitle: Text(
                      langVM.translate(_inStock ? 'in_stock' : 'out_of_stock')),
                  value: _inStock,
                  onChanged: (val) => setState(() => _inStock = val),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _handleFormSubmit(sellerVM, langVM, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                      ),
                      child: Text(
                        widget.productToEdit != null
                            ? langVM.translate('update_button')
                            : langVM.translate('publish_product_button'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
