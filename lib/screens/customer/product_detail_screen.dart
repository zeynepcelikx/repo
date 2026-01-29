import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'customer_main_layout.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDetailScreen({super.key, required this.productData});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // Tasarım Renkleri
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);

  bool _isLoading = false;
  Map<String, dynamic>? _sellerData;

  // --- YENİ EKLENEN DEĞİŞKENLER ---
  bool _isFavorite = false; // Favori durumu
  final TextEditingController _noteController = TextEditingController(); // Not alanı

  @override
  void initState() {
    super.initState();
    _fetchSellerInfo();
    _checkIfFavorite(); // Sayfa açılınca favori mi diye kontrol et
  }

  @override
  void dispose() {
    _noteController.dispose(); // Bellek sızıntısını önle
    super.dispose();
  }

  // --- LOGIC: SATICI BİLGİLERİNİ ÇEKME ---
  Future<void> _fetchSellerInfo() async {
    String? sellerId = widget.productData['sellerId'];
    if (sellerId != null) {
      try {
        DocumentSnapshot sellerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(sellerId)
            .get();

        if (sellerDoc.exists) {
          if (mounted) {
            setState(() {
              _sellerData = sellerDoc.data() as Map<String, dynamic>;
            });
          }
        }
      } catch (e) {
        debugPrint("Satıcı bilgisi çekilemedi: $e");
      }
    }
  }

  // --- YENİ LOGIC: FAVORİ KONTROL VE DEĞİŞTİRME ---
  Future<void> _checkIfFavorite() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.productData['id'])
          .get();

      if (mounted) {
        setState(() {
          _isFavorite = doc.exists;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String productId = widget.productData['id'];
    CollectionReference favoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites');

    if (_isFavorite) {
      // Favoriden Çıkar
      await favoritesRef.doc(productId).delete();
      if (mounted) setState(() => _isFavorite = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Favorilerden çıkarıldı 💔")));
    } else {
      // Favoriye Ekle
      await favoritesRef.doc(productId).set(widget.productData);
      if (mounted) setState(() => _isFavorite = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Favorilere eklendi ❤️"), backgroundColor: aestheticGreen));
    }
  }

  // --- LOGIC: SİPARİŞ OLUŞTURMA ---
  Future<void> _createOrder() async {
    setState(() => _isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Satıcı Kimliği Kontrolü
      String? sellerId = widget.productData['sellerId'];

      if (sellerId == null || sellerId.isEmpty) {
        _showError("Hata: Bu ürünün satıcı bilgisi eksik, sipariş verilemiyor.");
        setState(() => _isLoading = false);
        return;
      }

      // 2. Stok Kontrolü
      DocumentReference productRef = FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productData['id']);

      DocumentSnapshot productSnapshot = await productRef.get();
      int currentStock = 0;
      if (productSnapshot.exists && productSnapshot.data() != null) {
        var data = productSnapshot.data() as Map<String, dynamic>;
        currentStock = int.tryParse(data['stock'].toString()) ?? 0;
      }

      if (currentStock <= 0) {
        _showError("Üzgünüz, bu ürünün stoğu tükendi.");
        setState(() => _isLoading = false);
        return;
      }

      // 3. Siparişi Kaydet (YENİ: Sipariş Notu Eklendi)
      await FirebaseFirestore.instance.collection('orders').add({
        'customerId': user.uid,
        'sellerId': sellerId,
        'productId': widget.productData['id'],
        'productName': widget.productData['name'] ?? 'Ürün',
        'price': widget.productData['price'] ?? 0.0,
        'status': 'active',
        'orderDate': DateTime.now(),
        'imageUrl': widget.productData['imageUrl'] ?? '',
        'orderNote': _noteController.text.trim(), // NOT BURADA KAYDEDİLİYOR
      });

      // 4. Müşteriye Bildirim
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': 'Siparişiniz Alındı! 🛍️',
        'body': '${widget.productData['name'] ?? 'Ürün'} siparişiniz oluşturuldu.',
        'isRead': false,
        'type': 'order',
        'timestamp': DateTime.now(),
      });

      // 5. Satıcıya Bildirim
      await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .collection('notifications')
          .add({
        'title': 'Yeni Sipariş! 🤑',
        'body': '${widget.productData['name'] ?? 'Bir ürün'} siparişi aldınız.',
        'isRead': false,
        'type': 'order',
        'timestamp': DateTime.now(),
      });

      // 6. Stoğu Düşür
      await productRef.update({'stock': currentStock - 1});

      if (!mounted) return;

      _showSuccessDialog();

    } catch (e) {
      _showError("Sipariş hatası: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
            child: Icon(Icons.check_circle, color: aestheticGreen, size: 60)),
        content: const Text(
          "Siparişiniz başarıyla alındı! 🎉\nRestorana giderek teslim alabilirsiniz.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const CustomerMainLayout()),
                    (route) => false,
              );
            },
            child: Text("Tamam", style: TextStyle(color: aestheticGreen, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Verileri Hazırla
    final data = widget.productData;
    final String name = data['name'] ?? 'İsimsiz Ürün';
    final double price = double.tryParse(data['price'].toString()) ?? 0.0;
    final double originalPrice = double.tryParse(data['originalPrice'].toString()) ?? 0.0;
    final String description = data['description'] ?? 'Açıklama bulunmuyor.';
    final int stock = int.tryParse(data['stock'].toString()) ?? 0;
    String imageUrl = data['imageUrl'] ?? '';
    if (imageUrl.isEmpty) imageUrl = 'https://cdn-icons-png.flaticon.com/512/2921/2921822.png';

    int discountRate = 0;
    if (originalPrice > price && price > 0) {
      discountRate = (((originalPrice - price) / originalPrice) * 100).round();
    }

    String sellerName = _sellerData?['businessName'] ?? _sellerData?['name'] ?? 'Restoran';
    String address = _sellerData?['address'] ?? 'Adres bilgisi yükleniyor...';
    String phone = _sellerData?['phone'] ?? 'Telefon eklenmemiş';

    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          // Header Görseli
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(imageUrl, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, darkBg.withOpacity(0.2), darkBg],
                      stops: const [0.6, 0.8, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Üst Butonlar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.1))),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                ),

                // --- GÜNCELLENEN FAVORİ BUTONU ---
                GestureDetector(
                  onTap: _toggleFavorite, // Butona basınca çalışacak
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.1))),
                    // Duruma göre ikon değişiyor: Dolu veya Boş
                    child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.redAccent : Colors.white,
                        size: 22
                    ),
                  ),
                ),
              ],
            ),
          ),

          // İçerik
          Positioned.fill(
            top: MediaQuery.of(context).size.height * 0.38,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120), // Alt boşluğu arttırdık (Input için)
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ürün Kartı
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.1)),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("${price.toStringAsFixed(2)}₺", style: TextStyle(color: aestheticGreen, fontSize: 24, fontWeight: FontWeight.bold)),
                                if (discountRate > 0)
                                  Text("${originalPrice.toStringAsFixed(2)}₺", style: const TextStyle(color: Colors.grey, fontSize: 14, decoration: TextDecoration.lineThrough)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _buildBadge(text: "$stock Adet Kaldı", textColor: aestheticGreen, borderColor: aestheticGreen, bgColor: aestheticGreen.withOpacity(0.1)),
                            const SizedBox(width: 12),
                            if (discountRate > 0)
                              _buildBadge(text: "%$discountRate İndirim", textColor: const Color(0xFFFF5252), borderColor: const Color(0xFFFF5252), bgColor: const Color(0xFFFF5252).withOpacity(0.1)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Dükkan Kartı
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF161616), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [Icon(Icons.circle, size: 8, color: aestheticGreen), const SizedBox(width: 8), Text("DÜKKAN KONUMU & İLETİŞİM", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold))]),
                        const SizedBox(height: 16),

                        Row(children: [
                          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.2))), child: const Icon(Icons.store, color: Colors.white, size: 20)),
                          const SizedBox(width: 16),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(sellerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("Restoran & Cafe", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                          ])
                        ]),

                        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white.withOpacity(0.05))),

                        Row(children: [
                          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.2))), child: Icon(Icons.location_on_outlined, color: aestheticGreen, size: 20)),
                          const SizedBox(width: 16),
                          Expanded(child: Text(address, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4))),
                        ]),

                        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white.withOpacity(0.05))),

                        Row(children: [
                          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.2))), child: Icon(Icons.phone_outlined, color: aestheticGreen, size: 20)),
                          const SizedBox(width: 16),
                          Expanded(child: Text(phone, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13))),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text("Ürün Açıklaması", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.6)),

                  const SizedBox(height: 24),

                  // --- YENİ: SİPARİŞ NOTU ALANI ---
                  const Text("Sipariş Notu (İsteğe Bağlı)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: TextField(
                      controller: _noteController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "Örn: Soğan olmasın, zile basma...",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Alt Buton
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black, Colors.black.withOpacity(0.9), Colors.transparent])),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createOrder,
                  style: ElevatedButton.styleFrom(backgroundColor: aestheticGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 10, shadowColor: aestheticGreen.withOpacity(0.4)),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text("HEMEN KURTAR", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    SizedBox(width: 8),
                    Icon(Icons.recycling, color: Colors.black, size: 20),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({required String text, required Color textColor, required Color borderColor, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor.withOpacity(0.3))),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}