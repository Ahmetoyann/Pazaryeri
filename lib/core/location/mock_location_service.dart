import 'location_service.dart';
import '../../data/models/address.dart';

/// A Mock location service that simulates a current position and address.
class MockLocationService implements LocationService {
  @override
  Future<Coordinate> getCurrentCoordinates() async {
    // Coordinates in Istanbul (example) — convert as you like.
    return Coordinate(41.0082, 28.9784);
  }

  @override
  Future<Address> getAddressFromCoordinates({required double lat, required double lng}) async {
    // Simulate a reverse-geocoded Address
    return Address(
      latitude: lat,
      longitude: lng,
      street: 'İstiklal Caddesi',
      streetNumber: '25',
      neighborhood: 'Beyoğlu',
      district: 'Beyoğlu',
      city: 'İstanbul',
    );
  }
}
