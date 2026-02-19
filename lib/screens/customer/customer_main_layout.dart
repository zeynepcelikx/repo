import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'customer_home.dart';
import 'my_orders_screen.dart';
import 'customer_map_screen.dart';
import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';

class CustomerMainLayout extends StatefulWidget {
  const CustomerMainLayout({super.key});

  @override
  State<CustomerMainLayout> createState() => _CustomerMainLayoutState();
}

class _CustomerMainLayoutState extends State<CustomerMainLayout> {
  int _selectedIndex = 0; // Varsayılan: Keşfet Sayfası
  final User? user = FirebaseAuth.instance.currentUser;

  // Tasarım Renkleri
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Sayfaların sırası: Keşfet -> Harita -> Siparişler -> Bildirimler -> Profil
    _pages = [
      const CustomerHomeScreen(),    // 0
      const CustomerMapScreen(),     // 1
      const MyOrdersScreen(),        // 2
      const NotificationsScreen(),   // 3
      const ProfileScreen(),         // 4
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg, // Tüm ekranın arka planı

      // Seçili sayfayı göster
      body: _pages[_selectedIndex],

      // --- SİYAH ALT MENÜ (NAV BAR) ---
      bottomNavigationBar: Theme(
        // Nav bar için özel tema ayarı (Çizgiyi kaldırmak ve renkleri oturtmak için)
        data: Theme.of(context).copyWith(
          canvasColor: darkBg, // Menü arka plan rengi
          textTheme: Theme.of(context).textTheme.copyWith(
            bodySmall: const TextStyle(color: Colors.white54),
          ),
        ),
        child: Container(
          // Üst tarafa ince bir çizgi ekleyerek menüyü içerikten ayıralım
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,

            // Renk Ayarları
            backgroundColor: darkBg, // Siyah Arka Plan 🖤
            selectedItemColor: aestheticGreen, // Aktif İkon Yeşili 💚
            unselectedItemColor: Colors.grey.shade600, // Pasif İkon Gri

            type: BottomNavigationBarType.fixed, // 5 ikon olduğu için sabit tip
            elevation: 0, // Gölgeyi kaldırdık (Daha flat ve modern durur)

            items: [
              // 1. KEŞFET
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: 'Keşfet',
              ),

              // 2. HARİTA
              const BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                label: 'Harita',
              ),

              // 3. SİPARİŞLER
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: 'Siparişler',
              ),

              // 4. BİLDİRİMLER (KIRMIZI ROZETLİ)
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
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_outlined), // Ana Zil İkonu

                        if (unreadCount > 0)
                          Positioned(
                            right: -6,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: darkBg, width: 1.5),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
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

              // 5. PROFİL
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}