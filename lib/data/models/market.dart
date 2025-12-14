import 'address.dart';

// Extend Market with products list and occupancy percentage (0-100)

class Market {
  final String id;
  final String name;
  final String description;
  final Address address;
  final double distanceInMeters;
  final List<String> products;
  final List<String> openDays; // e.g., ['Pazartesi', 'Cuma']

  Market({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.distanceInMeters,
    this.products = const [],
    this.openDays = const [],
  });
}
