import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../data/repositories/market_repository.dart';
import '../../data/models/market.dart';
import 'notification_service.dart';
import 'auth_service.dart';
import 'app_strings.dart';

class SellerViewModel extends ChangeNotifier {
  final MarketRepository _marketRepository;

  SellerViewModel(this._marketRepository) {
    _loadMockData();
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

  // --- MOCK VERİ (GEÇİCİ VERİTABANI) ---
  // Firestore yerine bu listeyi kullanıyoruz.
  final List<SellerProduct> _mockDatabase = [
    SellerProduct(
      id: '101',
      name: 'Domates (Salkım)',
      description: 'Mis kokulu yerli domates.',
      price: 35.0,
      category: 'Sebze',
      stockQuantity: 50,
      unit: 'kg',
      inStock: true,
      imagePath:
          'https://post.healthline.com/wp-content/uploads/2020/09/tomatoes-1200x628-facebook-1200x628.jpg',
    ),
    SellerProduct(
      id: '102',
      name: 'Salatalık',
      description: 'Çıtır çıtır Çengelköy.',
      price: 20.0,
      category: 'Sebze',
      stockQuantity: 30,
      unit: 'kg',
      inStock: true,
    ),
    SellerProduct(
      id: '103',
      name: 'Amasya Elması',
      description: 'Kütür kütür kırmızı elma.',
      price: 25.0,
      category: 'Meyve',
      stockQuantity: 100,
      unit: 'kg',
      inStock: true,
    ),
    SellerProduct(
      id: '104',
      name: 'Köy Yumurtası',
      description: 'Günlük taze yumurta (15\'li).',
      price: 60.0,
      category: 'Şarküteri',
      stockQuantity: 20,
      unit: 'adet',
      inStock: true,
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
      // Ağ gecikmesi simülasyonu
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock veriden filtreleme yap
      List<SellerProduct> filtered = _mockDatabase;
      if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
        filtered =
            filtered.where((p) => p.category == _categoryFilter).toList();
      }

      // Pagination simülasyonu (Basitçe hepsini getiriyoruz)
      _myProducts = List.from(filtered);
      _hasMoreProducts = false; // Mock veride sayfalama yapmıyoruz
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
        // Firebase yerine yerel depolamaya kaydet
        imageUrl = await _saveImageLocally(_selectedImages.first.path);
      } catch (e) {
        debugPrint('Resim yükleme hatası: $e');
      }
    }

    // Benzersiz ID oluştur
    final id = DateTime.now().millisecondsSinceEpoch.toString();

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

    _mockDatabase.add(newProduct); // Mock DB'ye ekle
    _myProducts.add(newProduct);
    await _saveMockData();

    _isLoading = false;
    _checkLowStock(newProduct);
    _selectedImages.clear(); // Formu temizle
    notifyListeners();
    return true;
  }

  Future<void> removeProduct(String productId) async {
    // Silinecek ürünü bul
    final index = _mockDatabase.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final product = _mockDatabase[index];
      // Eğer yerel bir resim dosyası varsa (URL değilse) sil
      if (product.imagePath != null && !product.imagePath!.startsWith('http')) {
        try {
          final file = File(product.imagePath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Resim silinemedi: $e');
        }
      }
      _mockDatabase.removeAt(index); // Mock DB'den sil
    }

    _myProducts.removeWhere((p) => p.id == productId);
    await _saveMockData();
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
        // Firebase yerine yerel depolamaya kaydet
        imageUrl = await _saveImageLocally(_selectedImages.first.path);
      } catch (e) {
        debugPrint('Resim yükleme hatası: $e');
      }
    }

    // Mock DB güncelle
    final dbIndex = _mockDatabase.indexWhere((p) => p.id == id);
    if (dbIndex != -1) {
      final old = _mockDatabase[dbIndex];
      _mockDatabase[dbIndex] = SellerProduct(
        id: id,
        name: name,
        description: description,
        price: price,
        category: category,
        imagePath: imageUrl ?? old.imagePath,
        inStock: inStock,
        viewCount: old.viewCount,
        stockQuantity: stockQuantity,
        unit: unit,
      );
    }
    await _saveMockData();

    // UI Listesini güncelle
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

      // Mock DB güncelle
      final dbIndex = _mockDatabase.indexWhere((item) => item.id == productId);
      if (dbIndex != -1) {
        // Basitçe yeniden oluşturuyoruz, gerçekte copyWith daha iyi olurdu
        final old = _mockDatabase[dbIndex];
        _mockDatabase[dbIndex] = SellerProduct(
          id: old.id,
          name: old.name,
          description: old.description,
          price: old.price,
          category: old.category,
          imagePath: old.imagePath,
          inStock: newStatus,
          viewCount: old.viewCount,
          stockQuantity: old.stockQuantity,
          unit: old.unit,
        );
        await _saveMockData();
      }

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imagePath': imagePath,
      'inStock': inStock,
      'viewCount': viewCount,
      'stockQuantity': stockQuantity,
      'unit': unit,
    };
  }

  factory SellerProduct.fromMap(Map<String, dynamic> map) {
    return SellerProduct(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: (map['price'] as num).toDouble(),
      category: map['category'],
      imagePath: map['imagePath'],
      inStock: map['inStock'] ?? true,
      viewCount: map['viewCount'] ?? 0,
      stockQuantity: (map['stockQuantity'] as num).toDouble(),
      unit: map['unit'] ?? 'unit_kg',
    );
  }
}
