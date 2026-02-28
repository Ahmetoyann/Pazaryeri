import 'package:flutter/material.dart';
import '../../core/location/location_service.dart';
import '../../data/models/address.dart';
import '../../data/models/market.dart';
import '../../core/regions/provinces.dart';
import '../../data/repositories/market_repository.dart';
import 'auth_service.dart';
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
  List<String> _allCities = [];
  Map<String, List<String>> _allDistricts = {};
  String? _selectedCityFilter;
  String? _selectedDistrictFilter;

  List<String> get allCities => _allCities;
  List<String> get districtsForSelectedCity => _selectedCityFilter != null
      ? (_allDistricts[_selectedCityFilter] ?? [])
      : [];
  String? get selectedCityFilter => _selectedCityFilter;
  String? get selectedDistrictFilter => _selectedDistrictFilter;

  // Saat kontrolü: 05:00 - 20:30 arası açık kabul edilir
  // Public getter olarak değiştirildi, böylece UI tarafından erişilebilir
  bool get isWithinOpenHours {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = 5 * 60; // 05:00
    final endMinutes = 20 * 60 + 30; // 20:30
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

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
      _populateFilters(markets);
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

      // Saat kontrolü ile listeleri ayır (Market objelerini değiştirmeden)
      final bool isOpenTime = isWithinOpenHours;

      final open = markets
          .where((m) => m.openDays.contains(today) && isOpenTime)
          .toList();
      final closed = markets
          .where((m) =>
              !m.openDays.contains(today) ||
              (m.openDays.contains(today) && !isOpenTime))
          .toList();
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
      _populateFilters(fetched);
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

      // Saat kontrolü ile listeleri ayır
      final bool isOpenTime = isWithinOpenHours;

      final open = fetched
          .where((m) => m.openDays.contains(today) && isOpenTime)
          .toList();
      final closed = fetched
          .where((m) =>
              !m.openDays.contains(today) ||
              (m.openDays.contains(today) && !isOpenTime))
          .toList();
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
    // Reset filters to nearby markets
    _populateFilters(nearbyMarkets);
    notifyListeners();
  }

  void updateDayFilter(String? day) {
    selectedDay = day;
    notifyListeners();
  }

  void _populateFilters(List<Market> markets) {
    final cities = markets
        .map((m) => m.address.city)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    cities.sort();
    _allCities = ['Tümü', ...cities];

    _allDistricts.clear();
    for (var city in cities) {
      final districts = markets
          .where((m) => m.address.city == city)
          .map((m) => m.address.district)
          .where((d) => d.isNotEmpty)
          .toSet()
          .toList();
      districts.sort();
      _allDistricts[city] = ['Tümü', ...districts];
    }
  }

  void updateCityFilter(String? city) {
    _selectedCityFilter = (city == 'Tümü' || city == null) ? null : city;
    _selectedDistrictFilter = null; // İl değiştiğinde ilçe sıfırlanır
    notifyListeners();
  }

  void updateDistrictFilter(String? district) {
    _selectedDistrictFilter =
        (district == 'Tümü' || district == null) ? null : district;
    notifyListeners();
  }

  List<Market> get filteredNearbyMarkets {
    return _applyFilters(nearbyMarkets);
  }

  List<Market> get filteredProvinceMarkets {
    return _applyFilters(provinceMarkets);
  }

  List<Market> _applyFilters(List<Market> markets) {
    var filtered = markets;

    if (_selectedCityFilter != null) {
      filtered =
          filtered.where((m) => m.address.city == _selectedCityFilter).toList();
    }
    if (_selectedDistrictFilter != null) {
      filtered = filtered
          .where((m) => m.address.district == _selectedDistrictFilter)
          .toList();
    }

    if (selectedDay != null) {
      filtered =
          filtered.where((m) => m.openDays.contains(selectedDay)).toList();
    }

    return filtered;
  }

  // --- FAVORİLER ---

  Future<void> loadFavorites() async {
    _favoriteIds = await AuthService.instance.getFavorites();
    if (_favoriteIds.isNotEmpty) {
      favoriteMarkets = await _marketRepository.fetchMarketsByIds(_favoriteIds);
    } else {
      favoriteMarkets = [];
    }
    notifyListeners();
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
