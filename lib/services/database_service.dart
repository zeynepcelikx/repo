import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- İŞLETME FONKSİYONLARI ---

  // 1. Ürün Ekleme
  Future<void> addProduct(ProductModel product) async {
    try {
      // 'products' koleksiyonuna ekliyoruz. ID'yi Firestore otomatik üretiyor.
      await _firestore.collection('products').add(product.toMap());
    } catch (e) {
      print("Ürün ekleme hatası: $e");
      rethrow;
    }
  }

  // 2. İşletmenin Kendi Ürünlerini Getirme (Canlı Takip - Stream)
  Stream<List<ProductModel>> getProductsByBusiness(String businessId) {
    return _firestore
        .collection('products')
        .where('businessId', isEqualTo: businessId) // Sadece bu dükkana ait ürünler
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // 3. Ürünü Silme
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  // 4. SİPARİŞİ TAMAMLAMA (QR OKUTULUNCA ÇALIŞIR)
  Future<void> completeOrder(String orderId) async {
    final orderRef = _firestore.collection('orders').doc(orderId);

    try {
      // Sipariş verisini çek
      DocumentSnapshot orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        throw Exception("Sipariş bulunamadı! QR Kod geçersiz olabilir.");
      }

      // Sipariş zaten teslim edilmiş mi kontrol et
      String currentStatus = orderSnap.get('status');
      if (currentStatus == 'completed') {
        throw Exception("Bu sipariş zaten teslim edilmiş! ⚠️");
      }

      // Durumu 'completed' (tamamlandı) olarak güncelle
      await orderRef.update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(), // Teslim tarihini kaydet
      });

    } catch (e) {
      print("Sipariş tamamlama hatası: $e");
      rethrow;
    }
  }

  // --- MÜŞTERİ FONKSİYONLARI ---

  // 5. GÜVENLİ SATIN ALMA İŞLEMİ (Transaction)
  // Bu fonksiyon aynı anda iki kişinin son ürünü almasını engeller.
  Future<void> purchaseProduct({
    required String productId,
    required String customerId,
    required String businessId,
    required String productName,
    required double price,
  }) async {
    final productRef = _firestore.collection('products').doc(productId);
    final ordersRef = _firestore.collection('orders');

    try {
      await _firestore.runTransaction((transaction) async {
        // A. Ürünün güncel halini anlık olarak oku
        DocumentSnapshot productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception("Ürün bulunamadı!");
        }

        // B. Stok kontrolü yap (Veritabanındaki güncel stok)
        int currentStock = productSnapshot.get('stock');

        if (currentStock <= 0) {
          throw Exception("Üzgünüz, bu ürün az önce tükendi! 😔");
        }

        // C. Stoktan 1 düş ve güncelle
        transaction.update(productRef, {'stock': currentStock - 1});

        // D. Sipariş fişini oluştur
        OrderModel newOrder = OrderModel(
          id: '', // Firestore ID'yi kendi verecek
          customerId: customerId,
          businessId: businessId,
          productId: productId,
          productName: productName,
          price: price,
          orderDate: DateTime.now(),
          status: 'active', // İlk başta aktif, teslim edilince 'completed' olacak
        );

        // E. Siparişi 'orders' koleksiyonuna kaydet
        transaction.set(ordersRef.doc(), newOrder.toMap());
      });
    } catch (e) {
      print("Satın alma işlem hatası: $e");
      rethrow; // Hatayı ekrana basabilmek için yukarı fırlat
    }
  }
}