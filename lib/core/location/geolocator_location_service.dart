import 'location_service.dart';
import '../../data/models/address.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:flutter/foundation.dart';

class GeolocatorLocationService implements LocationService {
  @override
  Future<Coordinate?> getCurrentCoordinates() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Konum servisi devre dışı.');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('Konum izni reddedildi.');
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      return Coordinate(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('Konum alınırken beklenmeyen bir hata oluştu: $e');
      return null;
    }
  }

  @override
  Future<Address> getAddressFromCoordinates(
      {required double lat, required double lng}) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        return _emptyAddress(lat, lng);
      }
      final p = placemarks.first;
      return Address(
        latitude: lat,
        longitude: lng,
        street: p.street ?? '',
        streetNumber: '',
        neighborhood: p.subLocality ?? p.locality ?? '',
        district: p.subAdministrativeArea ?? p.administrativeArea ?? '',
        city: p.locality ?? p.administrativeArea ?? '',
      );
    } catch (e) {
      debugPrint('Adres çevrilirken hata oluştu: $e');
      // Web'de veya geocoding servisi çöktüğünde boş adres dönerek uygulamanın çökmesini engelleriz
      return _emptyAddress(lat, lng);
    }
  }

  Address _emptyAddress(double lat, double lng) {
    return Address(
      latitude: lat,
      longitude: lng,
      street: '',
      streetNumber: '',
      neighborhood: '',
      district: '',
      city: '',
    );
  }
}
