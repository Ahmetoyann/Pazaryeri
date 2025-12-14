import '../../data/models/address.dart';

abstract class LocationService {
  /// Returns current coordinates as a simple pair: (lat, lng)
  Future<Coordinate> getCurrentCoordinates();

  /// Returns a full Address (reverse geocoding) for given coordinates.
  Future<Address> getAddressFromCoordinates({required double lat, required double lng});
}

class Coordinate {
  final double latitude;
  final double longitude;
  Coordinate(this.latitude, this.longitude);
}
