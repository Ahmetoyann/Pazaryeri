import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/market_repository.dart';
import '../../data/models/market.dart';
import 'notification_service.dart';
import 'auth_service.dart';
import 'app_strings.dart';

class SellerViewModel extends ChangeNotifier {
  final MarketRepository _marketRepository;

  SellerViewModel(this._marketRepository) {
    _loadMockData();
    _loadReplyTemplates();
  }

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

  bool _hasMoreProducts = true;
  bool _isLoadingMore = false;
  bool get hasMoreProducts => _hasMoreProducts;
  bool get isLoadingMore => _isLoadingMore;
  static const int _productsLimit = 10;

  static const String _keyMockProducts = 'mock_products_data';

  List<String> _replyTemplates = [];
  List<String> get replyTemplates => List.unmodifiable(_replyTemplates);
  static const String _keyReplyTemplates = 'seller_reply_templates';

  // --- MOCK VERİ (GEÇİCİ VERİTABANI) ---
  // Firestore yerine bu listeyi kullanıyoruz.
  final List<SellerProduct> _mockDatabase = [
    SellerProduct(
      id: '101',
      sellerId: 'system',
      name: 'Domates (Salkım)',
      description: 'Mis kokulu yerli domates.',
      price: 35.0,
      category: 'Sebze',
      stockQuantity: 50,
      unit: 'kg',
      inStock: true,
      imagePath:
          'https://post.healthline.com/wp-content/uploads/2020/09/tomatoes-1200x628-facebook-1200x628.jpg',
      viewCount: 125,
      salesCount: 42,
    ),
    SellerProduct(
      id: '102',
      sellerId: 'system',
      name: 'Salatalık',
      description: 'Çıtır çıtır Çengelköy.',
      price: 20.0,
      category: 'Sebze',
      stockQuantity: 30,
      unit: 'kg',
      inStock: true,
      viewCount: 85,
      salesCount: 18,
    ),
    SellerProduct(
      id: '103',
      sellerId: 'system',
      name: 'Amasya Elması',
      description: 'Kütür kütür kırmızı elma.',
      price: 25.0,
      category: 'Meyve',
      stockQuantity: 100,
      unit: 'kg',
      inStock: true,
      viewCount: 210,
      salesCount: 65,
    ),
    SellerProduct(
      id: '104',
      sellerId: 'system',
      name: 'Köy Yumurtası',
      description: 'Günlük taze yumurta (15\'li).',
      price: 60.0,
      category: 'Şarküteri',
      stockQuantity: 20,
      unit: 'adet',
      inStock: true,
      viewCount: 45,
      salesCount: 12,
    ),
  ];
  // -------------------------------------

  Future<void> _loadMockData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyMockProducts);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      _mockDatabase.clear();
      for (var item in jsonList) {
        var product = SellerProduct.fromMap(item);
        // Yerel resim dosyası kontrolü: Dosya silinmişse path'i temizle
        if (product.imagePath != null &&
            !product.imagePath!.startsWith('http')) {
          if (!await File(product.imagePath!).exists()) {
            product = SellerProduct(
              id: product.id,
              sellerId: product.sellerId,
              name: product.name,
              description: product.description,
              price: product.price,
              category: product.category,
              imagePath: null, // Resim bulunamadı, null set et
              inStock: product.inStock,
              viewCount: product.viewCount,
              stockQuantity: product.stockQuantity,
              unit: product.unit,
            );
          }
        }
        _mockDatabase.add(product);
      }
      notifyListeners();
    } else {
      await _saveMockData();
    }
  }

  Future<void> _saveMockData() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString =
        json.encode(_mockDatabase.map((e) => e.toMap()).toList());
    await prefs.setString(_keyMockProducts, jsonString);
  }

  Future<void> _loadReplyTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    _replyTemplates = prefs.getStringList(_keyReplyTemplates) ?? [];
    notifyListeners();
  }

  Future<void> addReplyTemplate(String template) async {
    if (_replyTemplates.contains(template)) return;
    _replyTemplates.add(template);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyReplyTemplates, _replyTemplates);
    notifyListeners();
  }

  Future<void> removeReplyTemplate(String template) async {
    _replyTemplates.remove(template);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyReplyTemplates, _replyTemplates);
    notifyListeners();
  }

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
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality:
          70, // %70 kalite (Gözle görülür fark olmadan boyutu düşürür)
      maxWidth: 800, // Genişliği maksimum 800px ile sınırla
      maxHeight: 800, // Yüksekliği 800px ile sınırla
    );
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
    _myProducts = []; // Listeyi sıfırla
    notifyListeners();

    final userId = AuthService.instance.currentUserId;
    if (userId != null) {
      await _fetchProductsFromFirestore(userId);
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
      await _fetchProductsFromFirestore(userId);
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  // Yardımcı Metod: Sayfa Çekme Mantığı
  Future<void> _fetchProductsFromFirestore(String userId) async {
    try {
      final productsData = await AuthService.instance.getSellerProducts(userId);
      List<SellerProduct> products =
          productsData.map((data) => SellerProduct.fromMap(data)).toList();

      if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
        products =
            products.where((p) => p.category == _categoryFilter).toList();
      }

      _myProducts = products;
      // Pagination şimdilik kapalı
      _hasMoreProducts = false;
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

  // Resmi kalıcı dizine kopyalayan yardımcı metod
  Future<String?> _saveImageLocally(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(sourcePath)}';
      final savedImage =
          await File(sourcePath).copy('${directory.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      debugPrint('Resim yerel olarak kaydedilemedi: $e');
      return null;
    }
  }

  Future<bool> addProduct({
    required String name,
    required String description,
    required double price,
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
        // Firebase Storage'a yükle
        imageUrl = await AuthService.instance
            .uploadProductImage(File(_selectedImages.first.path));
      } catch (e) {
        _isLoading = false;
        notifyListeners();
        throw Exception('Resim yüklenirken bir sorun oluştu: $e');
      }
    }

    final userId = AuthService.instance.currentUserId;
    if (userId == null) return false;

    final userData = await AuthService.instance.getUserData();
    final marketId = userData?['sellerMarketId'] ?? '';

    final newProductMap = {
      'sellerId': userId,
      'marketId': marketId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imagePath': imageUrl,
      'inStock': inStock,
      'stockQuantity': stockQuantity,
      'unit': unit,
      'viewCount': 0,
      'salesCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await AuthService.instance.addProductToDb(newProductMap);
    await loadProducts(); // Listeyi yenile

    // Bildirim için geçici ürün nesnesi oluştur
    final newProduct = SellerProduct.fromMap(newProductMap..['id'] = 'temp');

    _isLoading = false;
    _checkLowStock(newProduct);
    _selectedImages.clear(); // Formu temizle
    notifyListeners();
    return true;
  }

  Future<void> removeProduct(String productId) async {
    try {
      final product = _myProducts.firstWhere((p) => p.id == productId);
      if (product.imagePath != null) {
        await AuthService.instance.deleteImageFromStorage(product.imagePath!);
      }
      await AuthService.instance.deleteProductFromDb(productId);
      await loadProducts();
    } catch (e) {
      debugPrint('Ürün silinemedi: $e');
    }
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
        // Firebase Storage'a yükle
        imageUrl = await AuthService.instance
            .uploadProductImage(File(_selectedImages.first.path));
      } catch (e) {
        _isLoading = false;
        notifyListeners();

        // İnternet hatası ise işlemi tekrar deneme kuyruğuna ekle
        if (e.toString().contains('İnternet Bağlantısı Yok')) {
          AuthService.instance.setRetryOperation(() => addProduct(
                name: name,
                description: description,
                price: price,
                category: category,
                stockQuantity: stockQuantity,
                unit: unit,
                inStock: inStock,
              ));
        }

        throw Exception('Resim yüklenirken bir sorun oluştu: $e');
      }
    }

    final updateMap = {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imagePath': imageUrl,
      'inStock': inStock,
      'stockQuantity': stockQuantity,
      'unit': unit,
    };

    await AuthService.instance.updateProductInDb(id, updateMap);
    await loadProducts();

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
      await loadProducts();

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
  final String sellerId;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? imagePath;
  final bool inStock;
  final int viewCount;
  final double salesCount;
  final double stockQuantity;
  final String unit;

  SellerProduct({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imagePath,
    this.inStock = true,
    this.viewCount = 0,
    this.salesCount = 0.0,
    this.stockQuantity = 0,
    this.unit = 'unit_kg',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imagePath': imagePath,
      'inStock': inStock,
      'viewCount': viewCount,
      'salesCount': salesCount,
      'stockQuantity': stockQuantity,
      'unit': unit,
    };
  }

  factory SellerProduct.fromMap(Map<String, dynamic> map) {
    return SellerProduct(
      id: map['id'],
      sellerId: map['sellerId'] ?? 'system',
      name: map['name'],
      description: map['description'],
      price: (map['price'] as num).toDouble(),
      category: map['category'],
      imagePath: map['imagePath'],
      inStock: map['inStock'] ?? true,
      viewCount: map['viewCount'] ?? 0,
      salesCount: (map['salesCount'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (map['stockQuantity'] as num).toDouble(),
      unit: map['unit'] ?? 'unit_kg',
    );
  }
}
