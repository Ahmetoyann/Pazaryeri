import 'package:flutter/material.dart';
import '../../core/location/location_service.dart';
import '../../data/models/address.dart';
import '../../data/models/market.dart';
import '../../core/regions/provinces.dart';
import '../../data/repositories/market_repository.dart';
import '../screens/auth_service.dart';
import 'notification_service.dart';

enum ViewState { idle, busy, error }

class HomeViewModel extends ChangeNotifier {
  final LocationService _locationService;
  final MarketRepository _marketRepository;

  HomeViewModel(this._locationService, this._marketRepository);

  ViewState state = ViewState.idle;
  Address? currentAddress;
  List<Market> nearbyMarkets = [];
  String? selectedProvince;
  List<Market> provinceMarkets = [];
  List<Market> favoriteMarkets = [];
  List<String> _favoriteIds = [];
  String? errorMessage;
  String? selectedDay;

  Future<void> loadData() async {
    try {
      state = ViewState.busy;
      notifyListeners();

      final coord = await _locationService.getCurrentCoordinates();
      print('HomeViewModel: got coords ${coord.latitude}, ${coord.longitude}');
      final address = await _locationService.getAddressFromCoordinates(
        lat: coord.latitude,
        lng: coord.longitude,
      );
      print('HomeViewModel: reverse-geocoded city:${address.city}');
      // If loading the user's current location, clear any selected provincial filter
      selectedProvince = null;
      provinceMarkets = [];
      currentAddress = address;

      final markets = await _marketRepository.fetchNearbyMarkets(
        forAddress: address,
      );
      print('HomeViewModel: loaded ${markets.length} markets from repository');
      if (markets.isNotEmpty) {
        final cities = markets.map((m) => m.address.city).toSet();
        print('HomeViewModel: loaded market cities: ${cities.join(', ')}');
      }
      // Put markets open today at the top of the list
      final todayMap = {
        1: 'Pazartesi',
        2: 'Salı',
        3: 'Çarşamba',
        4: 'Perşembe',
        5: 'Cuma',
        6: 'Cumartesi',
        7: 'Pazar',
      };
      final today = todayMap[DateTime.now().weekday]!;
      final open = markets.where((m) => m.openDays.contains(today)).toList();
      final closed = markets.where((m) => !m.openDays.contains(today)).toList();
      open.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
      closed.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
      nearbyMarkets = [...open, ...closed];

      if (nearbyMarkets.isEmpty) {
        // Provide a friendly message; UI will show the retry button in empty state
        errorMessage =
            'Yakında pazar bulunamadı. Lütfen konumunuzun doğru olduğunu ve gerekli izinlerin verildiğini doğrulayın.';
      } else {
        errorMessage = null;
      }

      // Load favorites as well
      await loadFavorites();

      state = ViewState.idle;
      notifyListeners();
    } catch (e) {
      state = ViewState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadMarketsForProvince(String province) async {
    try {
      state = ViewState.busy;
      notifyListeners();
      // Find coordinates for the province if possible
      // We'll create a fake Address with province name as city
      // Try to find coords using a local map (some provinces may be missing coords — repository will handle it)
      final coords = await _getProvinceCoords(province);
      final address = Address(
        latitude: coords[0],
        longitude: coords[1],
        street: '',
        streetNumber: '',
        neighborhood: '',
        district: '',
        city: province,
      );
      selectedProvince = province;
      final fetched = await _marketRepository.fetchNearbyMarkets(
        forAddress: address,
      );
      // Move markets that are open today to the top of the list
      final todayMap = {
        1: 'Pazartesi',
        2: 'Salı',
        3: 'Çarşamba',
        4: 'Perşembe',
        5: 'Cuma',
        6: 'Cumartesi',
        7: 'Pazar',
      };
      final today = todayMap[DateTime.now().weekday]!;
      final open = fetched.where((m) => m.openDays.contains(today)).toList();
      final closed = fetched.where((m) => !m.openDays.contains(today)).toList();
      open.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
      closed.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
      provinceMarkets = [...open, ...closed];
      state = ViewState.idle;
      notifyListeners();
    } catch (e) {
      state = ViewState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearProvinceSelection() {
    selectedProvince = null;
    provinceMarkets = [];
    notifyListeners();
  }

  void updateDayFilter(String? day) {
    selectedDay = day;
    notifyListeners();
  }

  List<Market> get filteredNearbyMarkets {
    if (selectedDay == null) return nearbyMarkets;
    return nearbyMarkets.where((m) => m.openDays.contains(selectedDay)).toList();
  }

  List<Market> get filteredProvinceMarkets {
    if (selectedDay == null) return provinceMarkets;
    return provinceMarkets.where((m) => m.openDays.contains(selectedDay)).toList();
  }

  // --- FAVORİLER ---

  Future<void> loadFavorites() async {
    _favoriteIds = await AuthService.instance.getFavorites();
    if (_favoriteIds.isNotEmpty) {
      favoriteMarkets = await _marketRepository.fetchMarketsByIds(_favoriteIds);
      _checkOpenFavoritesAndNotify();
    } else {
      favoriteMarkets = [];
    }
    notifyListeners();
  }

  Future<void> _checkOpenFavoritesAndNotify() async {
    final todayMap = {
      1: 'Pazartesi',
      2: 'Salı',
      3: 'Çarşamba',
      4: 'Perşembe',
      5: 'Cuma',
      6: 'Cumartesi',
      7: 'Pazar',
    };
    final today = todayMap[DateTime.now().weekday]!;

    for (final market in favoriteMarkets) {
      if (market.openDays.contains(today)) {
        await NotificationService.instance.showNotification(
          id: market.id.hashCode,
          title: 'Favori Pazarınız Açık! 🔔',
          body:
              '${market.name} bugün hizmet veriyor. Taze ürünleri kaçırmayın!',
        );
      }
    }
  }

  Future<void> toggleFavorite(String marketId) async {
    await AuthService.instance.toggleFavorite(marketId);
    await loadFavorites(); // Listeyi yenile
  }

  bool isFavorite(String marketId) => _favoriteIds.contains(marketId);

  Future<List<double>> _getProvinceCoords(String province) async {
    // See if the repo or core has a coord map; we'll try to import statically if available
    try {
      // Not a circular import — provinces map is in core/regions
      await Future.value(true);
      // As a minimal approach, if province coords are not defined, fallback to currentAddress coordinates
      if (currentAddress != null && currentAddress!.city == province) {
        return [currentAddress!.latitude, currentAddress!.longitude];
      }
    } catch (_) {}
    // Default fallback: try to use province coords map
    final coords = kProvinceCoords[province];
    if (coords != null && coords.length == 2) {
      return coords;
    }
    // Fallback to currentAddress or 0.0
    if (currentAddress != null)
      return [currentAddress!.latitude, currentAddress!.longitude];
    return [0.0, 0.0];
  }
}
