import 'location_service.dart';
import '../../data/models/address.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;

class GeolocatorLocationService implements LocationService {
  @override
  Future<Coordinate> getCurrentCoordinates() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      // The permission was denied or denied forever.
      throw Exception('Konum izni verilmedi. Lütfen uygulama ayarlarından konum izni verin.');
    }
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return Coordinate(pos.latitude, pos.longitude);
  }

  @override
  Future<Address> getAddressFromCoordinates({required double lat, required double lng}) async {
    final placemarks = await geo.placemarkFromCoordinates(lat, lng);
    if (placemarks.isEmpty) {
      return Address(latitude: lat, longitude: lng, street: '', streetNumber: '', neighborhood: '', district: '', city: '');
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
  }
}
