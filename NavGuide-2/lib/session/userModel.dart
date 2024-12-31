class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String disabilityType;
  final String gender;
  final String address;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.disabilityType,
    required this.gender,
    required this.address,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? 'Unknown',
      email: data['email'] ?? 'Unknown',
      firstName: data['firstName'] ?? 'Unknown',
      lastName: data['lastName'] ?? 'Unknown',
      phone: data['phone'] ?? 'Unknown',
      disabilityType: data['disabilityType'] ?? 'Unknown',
      gender: data['gender'] ?? 'Unknown',
      address: data['address'] ?? 'Unknown',
    );
  }
}
