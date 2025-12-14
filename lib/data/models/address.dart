class Address {
  final double latitude;
  final double longitude;
  final String street;
  final String streetNumber;
  final String neighborhood;
  final String district;
  final String city;

  Address({
    required this.latitude,
    required this.longitude,
    required this.street,
    required this.streetNumber,
    required this.neighborhood,
    required this.district,
    required this.city,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    if (neighborhood.isNotEmpty) buffer.write('$neighborhood, ');
    if (street.isNotEmpty) buffer.write('$street ');
    if (streetNumber.isNotEmpty) buffer.write('#$streetNumber, ');
    if (district.isNotEmpty) buffer.write('$district, ');
    if (city.isNotEmpty) buffer.write('$city');
    return buffer.toString();
  }
}
