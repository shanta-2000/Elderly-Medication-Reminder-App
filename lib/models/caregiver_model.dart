class Caregiver {
  Caregiver({
    this.id = '',
    required this.userId,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.address,
    this.fcmToken = '',
  });

  final String id;
  final String userId;
  final String password;
  final String fullName;
  final String phone;
  final String email;
  final String address;
  final String fcmToken;

  Caregiver copyWith({
    String? id,
    String? userId,
    String? password,
    String? fullName,
    String? phone,
    String? email,
    String? address,
    String? fcmToken,
  }) {
    return Caregiver(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'address': address,
      'fcmToken': fcmToken,
    };
  }

  factory Caregiver.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return Caregiver(
      id: id,
      userId: map['userId']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      fcmToken: map['fcmToken']?.toString() ?? '',
    );
  }
}