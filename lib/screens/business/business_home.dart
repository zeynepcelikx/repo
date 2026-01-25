import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'add_product_screen.dart';
import 'business_orders_screen.dart'; // <-- Sipariş ekranını import ettik
import '../common/profile_screen.dart';
import '../common/notifications_screen.dart';

class BusinessHomeScreen extends StatefulWidget {
  const BusinessHomeScreen({super.key});

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen> {
  int _selectedIndex = 0; // 0: Ürünler, 1: Siparişler, 2: Bildirimler
  final User? user = FirebaseAuth.instance.currentUser;

  // --- SAYFALAR LİSTESİ ---
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildProductList(),           // 0. Sekme: Ürün Listesi
      const BusinessOrdersScreen(),  // 1. Sekme: Siparişler (Nav Bar'a taşındı)
      const NotificationsScreen(),   // 2. Sekme: Bildirimler
    ];
  }

  // --- ÜRÜN LİSTESİ WIDGET'I ---
  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('userId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Henüz ürün eklemediniz."));
        }

        final products = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: products.length,
          itemBuilder: (context, index) {
            var data = products[index].data() as Map<String, dynamic>;
            double price = double.tryParse(data['discountedPrice']?.toString() ?? data['price']?.toString() ?? '0') ?? 0.0;

            return Card(
              child: ListTile(
                leading: Image.network(
                  data['imageUrl'] ?? 'https://via.placeholder.com/50',
                  width: 50, height: 50, fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => const Icon(Icons.fastfood),
                ),
                title: Text(data['name'] ?? 'Ürün'),
                subtitle: Text("${price.toStringAsFixed(2)} ₺ - Stok: ${data['stock'] ?? 0}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // Ürün Silme
                    FirebaseFirestore.instance.collection('products').doc(products[index].id).delete();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- SEKME DEĞİŞTİRME ---
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sadece 'Ürünlerim' (Index 0) sayfasındayken Ana AppBar'ı göster.
      // Diğer sayfalarda (Siparişler/Bildirimler) o sayfaların kendi AppBar'ı görünecek.
      appBar: _selectedIndex == 0
          ? AppBar(
        title: const Text("Restoran Paneli"),
        actions: [
          // Ayarlar Butonu
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            tooltip: "Dükkan Ayarları",
          ),
          // Çıkış Butonu
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      )
          : null, // Index 0 değilse AppBar'ı gizle (Diğer sayfalar kendi AppBar'ını kullanır)

      // --- ORTA ALAN ---
      body: _pages[_selectedIndex],

      // --- ALT MENÜ (NAV BAR) ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        type: BottomNavigationBarType.fixed, // 3 ikon olduğu için sabit tip daha iyi durur
        items: [
          // 1. Sekme: Ürünler
          const BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Ürünlerim',
          ),

          // 2. Sekme: Siparişler (YENİ)
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long), // Fiş ikonu
            label: 'Siparişler',
          ),

          // 3. Sekme: Bildirimler (ROZETLİ) 🔴
          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot>(
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
                return Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                  ],
                );
              },
            ),
            label: 'Bildirimler',
          ),
        ],
      ),

      // FAB (Sadece Ürünler sayfasındayken görünsün)
      // Mavi "Sipariş Tara" butonu kaldırıldı ❌
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        heroTag: "addBtn",
        backgroundColor: Colors.green,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())),
        label: const Text("Ürün Ekle", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }
}