import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> productData; // Ürün bilgilerini dışarıdan alıyoruz

  const ProductDetailScreen({super.key, required this.productData});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isLoading = false;

  // --- SİPARİŞİ VERİTABANINA KAYDETME FONKSİYONU ---
  void _placeOrder() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Hata Ayıklama: Veriyi görelim
      print("📝 Sipariş oluşturuluyor...");
      print("📦 Ürün Verisi: ${widget.productData}");

      // Fiyat ve Satıcı ID kontrolü (Güvenli Veri)
      // Ana sayfadan 'price' olarak düzeltilmiş veriyi gönderdiğimiz için onu kullanıyoruz.
      double finalPrice = double.tryParse(widget.productData['price'].toString()) ?? 0.0;

      // Satıcı ID'si 'businessId' veya 'userId' olabilir, ikisini de dene.
      String sellerId = widget.productData['businessId'] ?? widget.productData['userId'] ?? '';

      if (sellerId.isEmpty) {
        throw "Satıcı bilgisi bulunamadı (businessId eksik).";
      }

      await FirebaseFirestore.instance.collection('orders').add({
        'customerId': user.uid,
        'customerEmail': user.email,
        'sellerId': sellerId, // Düzeltilen ID
        'businessName': widget.productData['businessName'] ?? 'Bilinmeyen Restoran', // Restoran adı
        'productId': widget.productData['id'],
        'productName': widget.productData['name'],
        'price': finalPrice, // Düzeltilen Fiyat
        'imageUrl': widget.productData['imageUrl'],
        'status': 'active', // active, completed, cancelled
        'orderDate': FieldValue.serverTimestamp(),
      });

      print("✅ Sipariş başarıyla veritabanına eklendi!");

      if (!mounted) return;

      // 2. Başarılı Mesajı Göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Tebrikler! 🎉"),
          content: const Text("Yemeği başarıyla kurtardın! Dükkana gidip teslim alabilirsin."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Dialogu kapat
                Navigator.pop(context); // Detay ekranını kapat (Listeye dön)
              },
              child: const Text("Tamam"),
            )
          ],
        ),
      );

    } catch (e) {
      print("🚨 Sipariş Hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verileri Güvenli Çekelim
    final String name = widget.productData['name'] ?? 'İsimsiz Ürün';
    final String desc = widget.productData['description'] ?? 'Açıklama yok.';
    final String? imageUrl = widget.productData['imageUrl'];

    // Fiyatları Ana Sayfadan düzeltilmiş haliyle ('price') alıyoruz
    final double price = double.tryParse(widget.productData['price'].toString()) ?? 0.0;

    // Eski Fiyat (İndirim hesabı için)
    double oldPrice = 0.0;
    if (widget.productData['originalPrice'] != null) {
      oldPrice = double.tryParse(widget.productData['originalPrice'].toString()) ?? 0.0;
    }
    // Eğer eski fiyat yoksa veya şu anki fiyattan düşükse, sanal bir eski fiyat oluştur (Görsel düzelmesi için)
    if (oldPrice <= price) {
      oldPrice = price * 1.2; // %20 fazlası gibi göster
    }

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Column(
        children: [
          // Ürün Resmi
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Image.network('https://cdn-icons-png.flaticon.com/512/2921/2921822.png'),
            ),
          ),

          // Detaylar
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("${oldPrice.toStringAsFixed(2)} ₺",
                              style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 16)),
                          Text("${price.toStringAsFixed(2)} ₺",
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Ürün Açıklaması", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(desc, style: const TextStyle(color: Colors.grey)),

                  const Spacer(),

                  // SATIN AL BUTONU
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _isLoading ? null : _placeOrder, // Tıklanınca fonksiyon çalışır
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("HEMEN KURTAR ♻️", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10), // Alt boşluk
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}