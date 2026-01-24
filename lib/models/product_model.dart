class ProductModel {
  final String id;
  final String businessId;
  final String businessName; // <-- YENİ EKLENDİ
  final String name;
  final double originalPrice;
  final double discountedPrice;
  final int stock;
  final bool isActive;

  ProductModel({
    required this.id,
    required this.businessId,
    required this.businessName, // <-- Constructor'a eklendi
    required this.name,
    required this.originalPrice,
    required this.discountedPrice,
    required this.stock,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'businessName': businessName, // <-- Map'e eklendi
      'name': name,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'stock': stock,
      'isActive': isActive,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      businessId: map['businessId'] ?? '',
      businessName: map['businessName'] ?? 'Restoran', // <-- Okurken varsayılan
      name: map['name'] ?? '',
      originalPrice: (map['originalPrice'] ?? 0).toDouble(),
      discountedPrice: (map['discountedPrice'] ?? 0).toDouble(),
      stock: map['stock'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }
}