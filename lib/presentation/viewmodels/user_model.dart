class User {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String phoneNumber;
  final String email;
  final String? profilePicturePath;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.phoneNumber,
    required this.email,
    this.profilePicturePath,
  });
}
