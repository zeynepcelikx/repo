import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'customer_home.dart';
import 'my_orders_screen.dart';
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

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Sayfaların sırası: Keşfet -> Siparişler -> Bildirimler -> Profil
    _pages = [
      const CustomerHomeScreen(),
      const MyOrdersScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
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
      // Seçili sayfayı göster
      body: _pages[_selectedIndex],

      // --- ALT MENÜ ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green, // Aktif ikon rengi
        unselectedItemColor: Colors.grey, // Pasif ikon rengi
        type: BottomNavigationBarType.fixed, // 4 ikon olduğu için sabit tip
        items: [
          // 1. KEŞFET
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Keşfet',
          ),

          // 2. SİPARİŞLER
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Siparişler',
          ),

          // 3. BİLDİRİMLER (KIRMIZI ROZETLİ) 🔴
          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot>(
              // Sadece 'okunmamış' (isRead: false) bildirimleri dinliyoruz
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

                // Stack kullanarak ikonun üzerine kırmızı yuvarlak koyuyoruz
                return Stack(
                  children: [
                    const Icon(Icons.notifications), // Ana Zil İkonu

                    if (unreadCount > 0) // Sadece okunmamış varsa göster
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1), // Beyaz çerçeve
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$unreadCount', // Bildirim Sayısı
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

          // 4. PROFİL
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}