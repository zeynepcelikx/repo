import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String customerId;
  final String businessId;
  final String productId;
  final String productName;
  final double price;
  final DateTime orderDate;
  final String status; // 'active', 'completed', 'cancelled'

  OrderModel({
    required this.id,
    required this.customerId,
    required this.businessId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.orderDate,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'businessId': businessId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'orderDate': Timestamp.fromDate(orderDate), // Firestore için tarih formatı
      'status': status,
    };
  }
}