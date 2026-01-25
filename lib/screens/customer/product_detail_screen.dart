import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDetailScreen({super.key, required this.productData});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _shopData;
  bool _isFavorite = false; // Favori durumu

  @override
  void initState() {
    super.initState();
    _fetchShopDetails();
    _checkIfFavorite(); // Sayfa açılınca kontrol et
  }

  // --- FAVORİ KONTROLÜ ---
  void _checkIfFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.productData['id']) // Ürün ID'si ile kayıt yapacağız
        .get();

    if (mounted) {
      setState(() {
        _isFavorite = doc.exists;
      });
    }
  }

  // --- FAVORİYE EKLE / ÇIKAR ---
  void _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isFavorite = !_isFavorite); // Anlık UI tepkisi

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.productData['id']);

    if (_isFavorite) {
      // Ekle
      await ref.set(widget.productData);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Favorilere eklendi ❤️"), duration: Duration(milliseconds: 800)));
    } else {
      // Çıkar
      await ref.delete();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Favorilerden çıkarıldı 💔"), duration: Duration(milliseconds: 800)));
    }
  }

  void _fetchShopDetails() async {
    String sellerId = widget.productData['userId'] ?? widget.productData['businessId'] ?? '';
    if (sellerId.isNotEmpty) {
      try {
        DocumentSnapshot shopDoc = await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
        if (shopDoc.exists) {
          setState(() {
            _shopData = shopDoc.data() as Map<String, dynamic>;
          });
        }
      } catch (e) {
        print("Dükkan bilgileri alınamadı: $e");
      }
    }
  }

  // --- SİPARİŞİ VERME VE BİLDİRİM GÖNDERME FONKSİYONU ---
  void _placeOrder() async {
    int currentStock = int.tryParse(widget.productData['stock'].toString()) ?? 0;
    if (currentStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Üzgünüz, ürün tükenmiş! 😔")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot customerDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      Map<String, dynamic>? userData = customerDoc.data() as Map<String, dynamic>?;
      String customerPhone = 'Numara Yok';
      if (userData != null && userData.containsKey('phone')) {
        customerPhone = userData['phone'] ?? 'Numara Yok';
      }

      double finalPrice = double.tryParse(widget.productData['price'].toString()) ?? 0.0;

      // --- LOG EKLENDİ: SATICI KİMLİĞİNİ KONTROL ET ---
      String sellerId = widget.productData['userId'] ?? widget.productData['businessId'] ?? '';
      print("🕵️‍♂️ DENETİM: Satıcı ID: '$sellerId'");
      // -----------------------------------------------

      // 1. Siparişi Kaydet
      await FirebaseFirestore.instance.collection('orders').add({
        'customerId': user.uid,
        'customerEmail': user.email,
        'customerPhone': customerPhone,
        'sellerId': sellerId,
        'businessName': widget.productData['businessName'] ?? 'Restoran',
        'productId': widget.productData['id'],
        'productName': widget.productData['name'],
        'price': finalPrice,
        'imageUrl': widget.productData['imageUrl'],
        'status': 'active',
        'orderDate': FieldValue.serverTimestamp(),
      });

      // 2. Stoktan Düş
      await FirebaseFirestore.instance.collection('products').doc(widget.productData['id']).update({
        'stock': FieldValue.increment(-1),
      });

      // --- YENİ KISIM: İŞLETMEYE BİLDİRİM GÖNDER 🔔 ---
      if (sellerId.isNotEmpty) {
        print("📨 Bildirim gönderiliyor...");
        await FirebaseFirestore.instance
            .collection('users')
            .doc(sellerId) // İşletmenin ID'si
            .collection('notifications')
            .add({
          'title': 'Yeni Sipariş! 🤑',
          'body': '${widget.productData['name']} siparişi aldınız. Hemen hazırlamaya başlayın!',
          'date': FieldValue.serverTimestamp(),
          'isRead': false,
        });
        print("✅ Bildirim başarıyla gönderildi!");
      } else {
        print("🚨 HATA: Satıcı ID boş, bildirim gönderilemedi!");
      }
      // -------------------------------------------------------

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Tebrikler! 🎉"),
          content: const Text("Yemeği kurtardın! Dükkana gidip teslim alabilirsin."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text("Tamam"),
            )
          ],
        ),
      );

    } catch (e) {
      print("🚨 HATA OLUŞTU: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.productData['name'] ?? 'Ürün';
    final String desc = widget.productData['description'] ?? 'Açıklama yok.';
    final String? imageUrl = widget.productData['imageUrl'];
    final double price = double.tryParse(widget.productData['price'].toString()) ?? 0.0;

    int stock = int.tryParse(widget.productData['stock'].toString()) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.grey,
              size: 28,
            ),
            onPressed: _toggleFavorite,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity)
                : Container(color: Colors.grey[200], child: const Icon(Icons.fastfood, size: 80)),
          ),
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                        Text("${price.toStringAsFixed(2)} ₺",
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_shopData != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("📍 Dükkan Konumu & İletişim", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Row(children: [
                              const Icon(Icons.store, size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_shopData!['businessName'] ?? 'İşletme')),
                            ]),
                            if (_shopData!['address'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_shopData!['address'] ?? '', style: const TextStyle(fontSize: 12))),
                                ]),
                              ),
                            if (_shopData!['phone'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(children: [
                                  const Icon(Icons.phone, size: 16, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(_shopData!['phone'] ?? '', style: const TextStyle(fontSize: 12)),
                                ]),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    const Text("Ürün Açıklaması", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(desc, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: (stock > 0 && !_isLoading) ? _placeOrder : null,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(stock > 0 ? "HEMEN KURTAR ♻️" : "TÜKENDİ ❌",
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}