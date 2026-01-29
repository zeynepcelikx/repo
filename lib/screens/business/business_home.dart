import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Diğer sayfaları import ediyoruz
import 'add_product_screen.dart';
import 'business_orders_screen.dart';
import 'business_settings_screen.dart';
import '../common/notifications_screen.dart';

class BusinessHomeScreen extends StatefulWidget {
  const BusinessHomeScreen({super.key});

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen> {
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);

  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildProductsTab(),        // 0: Ürün Yönetimi
      const BusinessOrdersScreen(), // 1: Siparişler
      const NotificationsScreen(),  // 2: Bildirimler
      const BusinessSettingsScreen(), // 3: Dükkan Ayarları
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- LOGIC: ÜRÜN SİLME ---
  Future<void> _deleteProduct(String productId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Ürünü Sil", style: TextStyle(color: Colors.white)),
        content: const Text("Bu ürünü silmek istediğinize emin misiniz?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Vazgeç", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sil", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('products').doc(productId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ürün silindi."), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- LOGIC: İSTATİSTİKLERİ GÖSTER (SAĞ İKON FONKSİYONU) ---
  Future<void> _showAnalytics() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Yükleniyor göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(child: CircularProgressIndicator(color: aestheticGreen)),
    );

    try {
      // Verileri çek
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: user.uid)
          .get();

      Navigator.pop(context); // Loading kapat

      // Hesaplamalar
      int totalProducts = snapshot.docs.length;
      int totalStock = 0;
      double potentialRevenue = 0.0;

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        int stock = int.tryParse(data['stock'].toString()) ?? 0;
        double price = double.tryParse(data['price'].toString()) ?? 0.0;

        totalStock += stock;
        potentialRevenue += (stock * price);
      }

      // Alt Pencereyi Aç
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E1E),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Dükkan Özeti 📊", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white54))
                  ],
                ),
                const SizedBox(height: 24),

                // İstatistik Kartları
                _buildStatRow("Toplam Ürün Çeşidi", "$totalProducts Adet", Icons.inventory_2),
                const Divider(color: Colors.white10, height: 30),
                _buildStatRow("Toplam Stok", "$totalStock Adet", Icons.layers),
                const Divider(color: Colors.white10, height: 30),
                _buildStatRow("Tahmini Kazanç", "${potentialRevenue.toStringAsFixed(2)}₺", Icons.account_balance_wallet, isGreen: true),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );

    } catch (e) {
      Navigator.pop(context); // Loading kapat
      debugPrint("Hata: $e");
    }
  }

  Widget _buildStatRow(String label, String value, IconData icon, {bool isGreen = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isGreen ? aestheticGreen.withOpacity(0.1) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isGreen ? aestheticGreen : Colors.white70, size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: isGreen ? aestheticGreen : Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0C0C0C),
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: aestheticGreen,
          unselectedItemColor: Colors.grey.shade600,
          showUnselectedLabels: true,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Ürünlerim'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Siparişler'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Bildirimler'),
            BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'Dükkan'),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
        },
        backgroundColor: aestheticGreen,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("Ürün Ekle", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      )
          : null,
    );
  }

  // --- WIDGET: ÜRÜNLER SEKMESİ (Tab 0) ---
  Widget _buildProductsTab() {
    User? user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Ürünlerim 📦", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Satıştaki ürünlerini yönet", style: TextStyle(color: Colors.white54, fontSize: 14)),
                  ],
                ),
                // --- ARTIK BU İKON İŞLEVSEL ---
                GestureDetector(
                  onTap: _showAnalytics, // Fonksiyonu buraya bağladık
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bar_chart, color: aestheticGreen, size: 24),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Liste
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('sellerId', isEqualTo: user?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text("Index Hatası! Terminaldeki linke tıkla.\n${snapshot.error}", style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: aestheticGreen));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, size: 80, color: Colors.white.withOpacity(0.1)), const SizedBox(height: 16), const Text("Henüz hiç ürün eklemedin.", style: TextStyle(color: Colors.white54, fontSize: 16))]));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    String productId = doc.id;
                    return _buildProductCard(data, productId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: ÜRÜN KARTI ---
  Widget _buildProductCard(Map<String, dynamic> data, String productId) {
    String name = data['name'] ?? 'Ürün Adı';
    double price = double.tryParse(data['price'].toString()) ?? 0.0;
    double originalPrice = 0.0;
    if (data['originalPrice'] != null) {
      originalPrice = double.tryParse(data['originalPrice'].toString()) ?? 0.0;
    }
    int stock = int.tryParse(data['stock'].toString()) ?? 0;
    String imageUrl = data['imageUrl'] ?? 'https://cdn-icons-png.flaticon.com/512/2921/2921822.png';
    bool hasDiscount = originalPrice > price;
    int discountPercent = hasDiscount ? (((originalPrice - price) / originalPrice) * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.08))),
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: aestheticGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: aestheticGreen.withOpacity(0.2))), child: Text("Stok: $stock", style: TextStyle(color: aestheticGreen, fontSize: 10, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    if (hasDiscount) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.red.withOpacity(0.3))), child: Text("%$discountPercent", style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${price.toStringAsFixed(2)}₺", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    if (hasDiscount) Padding(padding: const EdgeInsets.only(bottom: 2), child: Text("${originalPrice.toStringAsFixed(2)}₺", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13, decoration: TextDecoration.lineThrough, decorationColor: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w500))),
                  ],
                ),
              ],
            ),
          ),
          IconButton(onPressed: () => _deleteProduct(productId), icon: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.7))),
        ],
      ),
    );
  }
}