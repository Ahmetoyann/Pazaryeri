import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/market_repository.dart';
import '../../data/models/market.dart';
import 'notification_service.dart';
import '../screens/auth_service.dart';
import 'app_strings.dart';

class SellerViewModel extends ChangeNotifier {
  final MarketRepository _marketRepository;

  SellerViewModel(this._marketRepository);

  Market? _selectedMarket;
  Market? get selectedMarket => _selectedMarket;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<XFile> _selectedImages = [];
  List<XFile> get selectedImages => _selectedImages;

  List<SellerProduct> _myProducts = [];
  List<SellerProduct> get myProducts => List.unmodifiable(_myProducts);

  String _stallName = '';
  String get stallName => _stallName;

  String _stallDescription = '';
  String get stallDescription => _stallDescription;

  bool _isStallOpen = false;
  bool get isStallOpen => _isStallOpen;

  // Pagination Değişkenleri
  String? _categoryFilter;
  String? get categoryFilter => _categoryFilter;

  DocumentSnapshot? _lastDocument;
  bool _hasMoreProducts = true;
  bool _isLoadingMore = false;
  bool get hasMoreProducts => _hasMoreProducts;
  bool get isLoadingMore => _isLoadingMore;
  static const int _productsLimit = 10;

  // Pazar Seçimi
  void selectMarket(Market market) {
    _selectedMarket = market;
    notifyListeners();
  }

  // ID ile Pazar Yükle (Otomatik Giriş İçin)
  Future<void> loadMarketById(String marketId) async {
    final markets = await _marketRepository.fetchAllMarkets();
    try {
      _selectedMarket = markets.firstWhere((m) => m.id == marketId);
      notifyListeners();
    } catch (e) {
      debugPrint('Pazar bulunamadı: $e');
    }
  }

  // Pazarları Getir
  Future<List<Market>> getMarkets() async {
    return await _marketRepository.fetchAllMarkets();
  }

  // Fotoğraf Ekleme
  Future<void> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      _selectedImages.add(image);
      notifyListeners();
    }
  }

  void removeImage(int index) {
    _selectedImages.removeAt(index);
    notifyListeners();
  }

  // Ürünleri Veritabanından Yükle (İlk Sayfa / Yenileme)
  Future<void> loadProducts() async {
    if (_isLoading) return;
    _isLoading = true;
    _hasMoreProducts = true;
    _lastDocument = null;
    _myProducts = []; // Listeyi sıfırla
    notifyListeners();

    final userId = AuthService.instance.currentUserId;
    if (userId != null) {
      await _fetchProductsPage(userId);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Sonraki Sayfayı Yükle
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    final userId = AuthService.instance.currentUserId;
    if (userId != null) {
      await _fetchProductsPage(userId);
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  // Yardımcı Metod: Sayfa Çekme Mantığı
  Future<void> _fetchProductsPage(String userId) async {
    try {
      final snapshot = await AuthService.instance.fetchSellerProductsPaginated(
        userId,
        limit: _productsLimit,
        startAfter: _lastDocument,
        category: _categoryFilter,
      );

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;

        final newProducts = snapshot.docs.map((doc) {
          final data = doc.data();
          return SellerProduct(
            id: doc.id,
            name: data['name'] ?? '',
            description: data['description'] ?? '',
            price: (data['price'] as num?)?.toDouble() ?? 0.0,
            category: data['category'] ?? '',
            imagePath: data['imagePath'],
            inStock: data['inStock'] ?? true,
            viewCount: data['viewCount'] ?? 0,
            stockQuantity: (data['stockQuantity'] as num?)?.toDouble() ?? 0.0,
            unit: data['unit'] ?? 'unit_kg',
          );
        }).toList();

        _myProducts.addAll(newProducts);

        // Eğer gelen veri limiti doldurmuyorsa, daha fazla veri yok demektir
        if (snapshot.docs.length < _productsLimit) {
          _hasMoreProducts = false;
        }
      } else {
        _hasMoreProducts = false;
      }
    } catch (e) {
      debugPrint('Ürünler sayfalanırken hata: $e');
      _hasMoreProducts = false;
    }
  }

  Future<void> setCategoryFilter(String? category) async {
    // Eğer filtre değişmediyse tekrar yükleme yapma
    if (_categoryFilter == category) return;
    _categoryFilter = category;
    await loadProducts(); // Filtre değiştiğinde ürünleri baştan yükle
  }

  Future<bool> addProduct({
    required String name,
    required String description,
    required double price,
    required String stallLocation,
    required String category,
    required double stockQuantity,
    required String unit,
    bool inStock = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    String? imageUrl;
    // Eğer resim seçildiyse yükle
    if (_selectedImages.isNotEmpty) {
      try {
        imageUrl = await AuthService.instance
            .uploadProductImage(File(_selectedImages.first.path));
      } catch (e) {
        debugPrint('Resim yükleme hatası: $e');
      }
    }

    final productData = {
      'sellerId': AuthService.instance.currentUserId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imagePath': imageUrl,
      'inStock': inStock,
      'stockQuantity': stockQuantity,
      'unit': unit,
      'viewCount': 0,
      'createdAt': DateTime.now().toIso8601String(),
    };

    final id = await AuthService.instance.addProductToDb(productData);

    final newProduct = SellerProduct(
      id: id,
      name: name,
      description: description,
      price: price,
      category: category,
      imagePath: imageUrl,
      inStock: inStock,
      stockQuantity: stockQuantity,
      unit: unit,
      viewCount: 0,
    );
    _myProducts.add(newProduct);

    _isLoading = false;
    _checkLowStock(newProduct);
    _selectedImages.clear(); // Formu temizle
    notifyListeners();
    return true;
  }

  Future<void> removeProduct(String productId) async {
    await AuthService.instance.deleteProductFromDb(productId);
    _myProducts.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required String description,
    required double price,
    required String category,
    required double stockQuantity,
    required String unit,
    required bool inStock,
    String? currentImagePath,
  }) async {
    _isLoading = true;
    notifyListeners();

    String? imageUrl = currentImagePath;

    // Eğer yeni resim seçildiyse yükle
    if (_selectedImages.isNotEmpty) {
      try {
        imageUrl = await AuthService.instance
            .uploadProductImage(File(_selectedImages.first.path));
      } catch (e) {
        debugPrint('Resim yükleme hatası: $e');
      }
    }

    final data = {
      'name': name,
      'description': description,
      'price': price,
      'stockQuantity': stockQuantity,
      'unit': unit,
      'category': category,
      'inStock': inStock,
      'imagePath': imageUrl,
    };

    await AuthService.instance.updateProductInDb(id, data);

    final index = _myProducts.indexWhere((p) => p.id == id);
    if (index != -1) {
      final oldProduct = _myProducts[index];
      _myProducts[index] = SellerProduct(
        id: id,
        name: name,
        description: description,
        price: price,
        category: category,
        imagePath: imageUrl,
        inStock: inStock,
        viewCount: oldProduct.viewCount,
        stockQuantity: stockQuantity,
        unit: unit,
      );
      _checkLowStock(_myProducts[index]);
    }

    _isLoading = false;
    _selectedImages.clear();
    notifyListeners();
  }

  Future<void> toggleProductStock(String productId) async {
    final index = _myProducts.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final p = _myProducts[index];
      final newStatus = !p.inStock;

      await AuthService.instance
          .updateProductInDb(productId, {'inStock': newStatus});

      _myProducts[index] = SellerProduct(
        id: p.id,
        name: p.name,
        description: p.description,
        price: p.price,
        category: p.category,
        imagePath: p.imagePath,
        inStock: newStatus,
        viewCount: p.viewCount,
        stockQuantity: p.stockQuantity,
        unit: p.unit,
      );
      notifyListeners();
    }
  }

  Future<void> updateSellerProfile({
    required String name,
    required String description,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Veritabanını güncelle
    final userEmail =
        (await AuthService.instance.getUserData())?['email'] ?? '';
    await AuthService.instance.updateUserInDb({
      'stallName': name,
      'stallDescription': description,
    }, userEmail);

    _stallName = name;
    _stallDescription = description;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleStallStatus(bool value) async {
    _isStallOpen = value;
    notifyListeners();
    // Burada veritabanı güncelleme işlemi yapılabilir
  }

  Future<void> _checkLowStock(SellerProduct product) async {
    if (product.stockQuantity < 10) {
      final langCode = await AuthService.instance.getLanguage();
      final title = AppStrings.getString('low_stock_title', langCode);
      final messagePart = AppStrings.getString('low_stock_message', langCode);
      final unitLabel = AppStrings.getString(product.unit, langCode);

      await NotificationService.instance.showNotification(
        id: product.id.hashCode,
        title: title,
        body:
            '${product.name} $messagePart (${product.stockQuantity} $unitLabel)',
      );
    }
  }
}

class SellerProduct {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? imagePath;
  final bool inStock;
  final int viewCount;
  final double stockQuantity;
  final String unit;

  SellerProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imagePath,
    this.inStock = true,
    this.viewCount = 0,
    this.stockQuantity = 0,
    this.unit = 'unit_kg',
  });
}
