class UserModel {
  final String uid;
  final String email;
  final String role; // 'customer' veya 'business'
  final int balance; // İşletmeler için kredi/kontör bakiyesi

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.balance = 0,
  });

  // Veritabanından (JSON) gelen veriyi Uygulamaya (Dart Object) çevirir
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      role: map['role'] ?? 'customer', // Varsayılan müşteri
      balance: map['balance'] ?? 0,
    );
  }

  // Uygulamadan Veritabanına (JSON) gönderir
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'balance': balance,
    };
  }
}