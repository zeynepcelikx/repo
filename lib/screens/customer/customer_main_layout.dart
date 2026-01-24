import 'package:flutter/material.dart';
import 'customer_home.dart';
import 'my_orders_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_map_screen.dart'; // <-- YENİ IMPORT

class CustomerMainLayout extends StatefulWidget {
  const CustomerMainLayout({super.key});

  @override
  State<CustomerMainLayout> createState() => _CustomerMainLayoutState();
}

class _CustomerMainLayoutState extends State<CustomerMainLayout> {
  int _currentIndex = 0;

  // Sayfalar Listesi (Artık 4 Sayfa Var)
  final List<Widget> _pages = [
    const CustomerHomeScreen(),     // 0: Keşfet
    const CustomerMapScreen(),      // 1: HARİTA (YENİ)
    const MyOrdersScreen(),         // 2: Siparişlerim
    const CustomerProfileScreen(),  // 3: Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Keşfet',
          ),
          // YENİ HARİTA BUTONU
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Harita',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Siparişler',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}