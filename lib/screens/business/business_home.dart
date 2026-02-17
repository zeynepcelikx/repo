import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Diğer sayfaları import ediyoruz
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
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
      _buildHomeTab(),
      const BusinessOrdersScreen(),
      const NotificationsScreen(),
      const BusinessSettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: darkBg,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
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

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .collection('notifications')
              .where('isRead', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            int unreadCount = 0;
            if (snapshot.hasData) {
              unreadCount = snapshot.data!.docs.length;
            }

            return BottomNavigationBar(
              backgroundColor: darkBg,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: aestheticGreen,
              unselectedItemColor: Colors.white54,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: [
                const BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: "Ürünlerim"),
                const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: "Siparişler"),
                BottomNavigationBarItem(
                  icon: unreadCount > 0
                      ? Badge(
                    label: Text(unreadCount > 9 ? '9+' : '$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.notifications_outlined),
                  )
                      : const Icon(Icons.notifications_outlined),
                  activeIcon: unreadCount > 0
                      ? Badge(
                    label: Text(unreadCount > 9 ? '9+' : '$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.notifications),
                  )
                      : const Icon(Icons.notifications),
                  label: "Bildirimler",
                ),
                const BottomNavigationBarItem(icon: Icon(Icons.store_outlined), activeIcon: Icon(Icons.store), label: "Dükkan"),
              ],
            );
          },
        ),
      ),
    );
  }

  // 1. SEKME: ÜRÜNLERİM
  Widget _buildHomeTab() {
    User? user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Ürünlerim", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    // DÜKKAN PUANI GÖSTERİMİ
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                      builder: (context, snapshot) {
                        double rating = 0.0;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          var data = snapshot.data!.data() as Map<String, dynamic>;
                          double totalScore = double.tryParse(data['totalScore'].toString()) ?? 0.0;
                          int count = int.tryParse(data['reviewCount'].toString()) ?? 0;
                          if (count > 0) rating = totalScore / count;
                        }
                        return Row(
                          children: [
                            Text("Satıştaki ürünlerini yönet", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                            if (rating > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                child: Row(children: [const Icon(Icons.star, color: Colors.orange, size: 12), const SizedBox(width: 4), Text(rating.toStringAsFixed(1), style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold))]),
                              )
                            ]
                          ],
                        );
                      },
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _showProductStatistics(user?.uid),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bar_chart, color: aestheticGreen),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('sellerId', isEqualTo: user?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: aestheticGreen));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 60, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        const Text("Henüz ürün eklemediniz.", style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    return _buildProductCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(String docId, Map<String, dynamic> data) {
    String name = data['name'] ?? 'İsimsiz Ürün';
    double price = double.tryParse(data['price'].toString()) ?? 0.0;
    double originalPrice = double.tryParse(data['originalPrice'].toString()) ?? 0.0;
    int stock = int.tryParse(data['stock'].toString()) ?? 0;
    String imageUrl = data['imageUrl'] ?? 'https://cdn-icons-png.flaticon.com/512/1160/1160358.png';

    int discountRate = 0;
    if (originalPrice > price && price > 0) {
      discountRate = (((originalPrice - price) / originalPrice) * 100).round();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: aestheticGreen.withOpacity(0.1),
          highlightColor: Colors.transparent,
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProductScreen(productId: docId, productData: data))
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: 80, height: 80, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(width: 80, height: 80, color: Colors.grey[800], child: const Icon(Icons.broken_image, color: Colors.white54)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildTag("Stok: $stock", stock > 0 ? aestheticGreen : Colors.red),
                          const SizedBox(width: 8),
                          if (discountRate > 0) _buildTag("%$discountRate", Colors.redAccent),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text("${price.toStringAsFixed(2)}₺", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          if (discountRate > 0) ...[
                            const SizedBox(width: 8),
                            Text("${originalPrice.toStringAsFixed(2)}₺", style: const TextStyle(color: Colors.grey, fontSize: 12, decoration: TextDecoration.lineThrough)),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
                // SİLME BUTONU
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.7)),
                  onPressed: () => _confirmDelete(docId), // Yeni fonksiyonu çağırır
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.5), width: 0.5)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  // --- İSTATİSTİKLER ---
  void _showProductStatistics(String? uid) {
    if (uid == null) return;
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
                  const Text("Envanter Özeti 📊", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white54))
                ],
              ),
              const SizedBox(height: 20),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('products').where('sellerId', isEqualTo: uid).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: aestheticGreen));
                  int totalProducts = 0; int totalStock = 0; double totalValue = 0.0; int lowStockCount = 0;
                  if (snapshot.hasData) {
                    totalProducts = snapshot.data!.docs.length;
                    for (var doc in snapshot.data!.docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      int stock = int.tryParse(data['stock'].toString()) ?? 0;
                      double price = double.tryParse(data['price'].toString()) ?? 0.0;
                      totalStock += stock;
                      totalValue += (stock * price);
                      if (stock < 5) lowStockCount++;
                    }
                  }
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: aestheticGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: aestheticGreen.withOpacity(0.3))),
                        child: Row(children: [
                          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: aestheticGreen.withOpacity(0.2), shape: BoxShape.circle), child: Icon(Icons.monetization_on, color: aestheticGreen, size: 24)),
                          const SizedBox(width: 16),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Toplam Envanter Değeri", style: TextStyle(color: Colors.white70, fontSize: 14)), Text("${totalValue.toStringAsFixed(2)}₺", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))])
                        ]),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _buildStatCard("Çeşit", "$totalProducts Adet")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard("Toplam Stok", "$totalStock Adet")),
                      ]),
                      if (lowStockCount > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.3))),
                          child: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20), const SizedBox(width: 10), Text("$lowStockCount ürünün stoğu kritik seviyede!", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))]),
                        ),
                      ]
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
    );
  }

  // --- YENİ: ŞIK SİLME EKRANI ---
  void _confirmDelete(String docId) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => Container(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 40),
                  ),
                  const SizedBox(height: 24),
                  const Text("Ürünü Sil", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Bu ürünü silmek istediğinize emin misiniz? Bu işlem geri alınamaz.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.5)),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("Vazgeç", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('products').doc(docId).delete();
                            if (mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text("Evet, Sil", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}