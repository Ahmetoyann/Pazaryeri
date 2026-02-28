import 'address.dart';

// Extend Market with products list and occupancy percentage (0-100)

class Market {
  final String id;
  final String name;
  final String description;
  final Address address;
  final double distanceInMeters;
  final List<String> openDays; // e.g., ['Pazartesi', 'Cuma']
  final double occupancy;

  Market({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.distanceInMeters,
    this.openDays = const [],
    double? occupancy,
  }) : occupancy = occupancy ??
            (0.3 +
                (id.hashCode.abs() % 61) / 100.0); // Varsayılan: %30-%90 arası
}
