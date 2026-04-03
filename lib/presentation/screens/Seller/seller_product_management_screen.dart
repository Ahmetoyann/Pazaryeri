import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import 'seller_add_product_screen.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_snackbars.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';

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
  bool _inStock = true;
  List<String> _existingImages = [];
  List<String> _deletedImages = [];
  List<XFile> _newImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _stockController =
        TextEditingController(text: widget.product.stockQuantity.toString());
    _salesController =
        TextEditingController(text: widget.product.salesCount.toString());
    _inStock = widget.product.inStock;
    _loadProductImages();
  }

  Future<void> _loadProductImages() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null && data['images'] != null) {
          setState(() {
            _existingImages = List<String>.from(data['images']);
          });
        } else if (data != null && data['imagePath'] != null) {
          setState(() {
            _existingImages = [data['imagePath']];
          });
        }
      }
    } catch (e) {
      debugPrint('Resimler yüklenemedi: $e');
    }
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (images.isNotEmpty) {
        setState(() {
          _newImages.addAll(images);
        });
      }
    } catch (e) {
      debugPrint('Resim seçme hatası: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image != null) {
        setState(() {
          _newImages.add(image);
        });
      }
    } catch (e) {
      debugPrint('Kamera hatası: $e');
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const SvgIcon(
                    iconPath: AppIcons.gallery, color: Colors.grey),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImagesFromGallery();
                },
              ),
              ListTile(
                leading: const SvgIcon(
                    iconPath: AppIcons.camera, color: Colors.grey),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _stockController.dispose();
    _salesController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(String label, String iconPath,
      {String? suffixText, String? helperText}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: SvgIcon(
              iconPath: iconPath, color: colorScheme.primary, size: 28)),
      suffixText: suffixText,
      helperText: helperText,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.5))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.5))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2)),
    );
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await LoadingOverlay.show(
        context,
        asyncFunction: () async {
          final double price = double.parse(_priceController.text);
          final double stock = double.parse(_stockController.text);
          final double sales = double.parse(_salesController.text);

          // Stok 0 ise otomatik olarak satışı durdur
          if (stock <= 0) {
            _inStock = false;
          }

          // Yeni resimleri yükle
          List<String> newImageUrls = [];
          for (var image in _newImages) {
            final file = File(image.path);
            if (await file.exists()) {
              try {
                final url = await AuthService.instance.uploadProductImage(file);
                newImageUrls.add(url);
              } catch (e) {
                throw Exception('Resim yüklenirken hata oluştu: $e');
              }
            }
          }

          // Silinen resimleri Storage'dan temizle
          for (String url in _deletedImages) {
            await AuthService.instance.deleteImageFromStorage(url);
          }

          // Firestore güncellemesi
          final Map<String, dynamic> updateData = {
            'price': price,
            'stockQuantity': stock,
            'salesCount': sales,
            'inStock': _inStock,
          };

          // Resim listesini güncelle (Mevcut + Yeni)
          List<String> finalImages = [..._existingImages, ...newImageUrls];
          updateData['images'] = finalImages;

          // Ana resim kontrolü (Eğer hiç resim kalmadıysa veya ana resim silindiyse)
          if (finalImages.isNotEmpty) {
            if (widget.product.imagePath == null ||
                !finalImages.contains(widget.product.imagePath)) {
              updateData['imagePath'] = finalImages.first;
            }
          } else {
            updateData['imagePath'] = null;
          }

          await AuthService.instance
              .updateProductInDb(widget.product.id, updateData);

          // ViewModel'i yenile (Listeyi ve istatistikleri güncellemek için)
          if (mounted) {
            await Provider.of<SellerViewModel>(context, listen: false)
                .loadProducts();
          }
        },
      );

      if (mounted) {
        CustomSnackbars.showSuccess(
            context, 'Ürün bilgileri ve istatistikler güncellendi');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showError(context, 'Hata: $e');
      }
    }
  }

  Widget _buildStockHistoryChart(BuildContext context) {
    double currentStock = double.tryParse(_stockController.text) ?? 0;
    double totalSales = double.tryParse(_salesController.text) ?? 0;
    // Basit bir simülasyon: Başlangıç stoğu = Şu anki + Satılan
    double initialStock = currentStock + totalSales;
    if (initialStock == 0) initialStock = 10; // Grafik boş görünmesin diye

    List<FlSpot> spots = [];
    for (int i = 0; i <= 6; i++) {
      // 7 günlük simülasyon (0..6)
      double progress = i / 6.0;
      double value = initialStock - (totalSales * progress);
      if (value < 0) value = 0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Stok Hareket Grafiği',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          height: 260,
          padding: const EdgeInsets.fromLTRB(12, 24, 24, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Başlangıç',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              )),
                        );
                      }
                      if (value == 6) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Bugün',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              )),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ));
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: initialStock * 1.2,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(widget.product.name),
        actions: [
          IconButton(
            icon: const SvgIcon(iconPath: AppIcons.edit, size: 28),
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

              // Fotoğraflar Bölümü
              Text('Ürün Fotoğrafları',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Resim Ekle Butonu
                    GestureDetector(
                      onTap: _showImageSourceActionSheet,
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.5)),
                        ),
                        child: SvgIcon(
                            iconPath: AppIcons.camera,
                            size: 36,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    // Yeni Seçilen Resimler
                    ..._newImages.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.5)),
                              image: DecorationImage(
                                image: FileImage(File(entry.value.path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => _removeNewImage(entry.key),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const SvgIcon(
                                    iconPath: AppIcons.close,
                                    size: 16,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    // Mevcut Resimler
                    ..._existingImages.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final String url = entry.value;
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.5)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.broken_image,
                                        color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 16,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _deletedImages.add(url);
                                  _existingImages.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const SvgIcon(
                                    iconPath: AppIcons.close,
                                    size: 16,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Fiyat
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _buildInputDecoration('Birim Fiyat (₺)',
                    AppIcons.products), // Fiyat ikonu yok, products kullandım
                validator: (v) => v!.isEmpty ? 'Fiyat giriniz' : null,
              ),
              const SizedBox(height: 16),

              // Stok
              TextFormField(
                controller: _stockController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    _buildInputDecoration('Stok Miktarı', AppIcons.inventory),
                validator: (v) => v!.isEmpty ? 'Stok giriniz' : null,
                onChanged: (val) {
                  setState(() {}); // Grafiği güncelle
                },
              ),
              const SizedBox(height: 16),

              // Satış Adedi
              TextFormField(
                controller: _salesController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _buildInputDecoration(
                    'Toplam Satış Miktarı', AppIcons.basket),
                validator: (v) => v!.isEmpty ? 'Satış adedi giriniz' : null,
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 24),

              _buildStockHistoryChart(context),
              const SizedBox(height: 24),

              CustomButton(
                text: _inStock ? 'Satışı Durdur' : 'Satışı Başlat',
                icon: _inStock
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                backgroundColor: _inStock
                    ? Colors.red.withOpacity(0.2)
                    : Colors.green.withOpacity(0.2),
                foregroundColor: _inStock ? Colors.red : Colors.green,
                onPressed: () {
                  setState(() {
                    _inStock = !_inStock;
                  });
                },
              ),
              const SizedBox(height: 16),

              CustomButton(
                text: 'Güncelle',
                onPressed: _updateProduct,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
