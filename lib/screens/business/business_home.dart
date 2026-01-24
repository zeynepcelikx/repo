import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'add_product_screen.dart';
import 'business_orders_screen.dart';
import 'scan_qr_screen.dart'; // <-- YENİ: QR Ekranını import ettik

class BusinessHomeScreen extends StatelessWidget {
  const BusinessHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Restoran Paneli"),
        actions: [
          // Siparişler Butonu (Sağ Üst)
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.green),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BusinessOrdersScreen()),
              );
            },
            tooltip: "Gelen Siparişler",
          ),
          // Çıkış Butonu
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),

      // SAĞ ALTTAKİ BUTONLAR (QR TARA + ÜRÜN EKLE)
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 1. QR TARA BUTONU (Mavi)
          FloatingActionButton.extended(
            heroTag: "scanBtn", // Hata almamak için özel etiket
            backgroundColor: Colors.blueAccent,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanQrScreen()));
            },
            label: const Text("Sipariş Tara 📸", style: TextStyle(color: Colors.white)),
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
          ),
          const SizedBox(height: 10), // İki buton arası boşluk

          // 2. ÜRÜN EKLE BUTONU (Yeşil - Eski Butonun)
          FloatingActionButton.extended(
            heroTag: "addBtn", // Hata almamak için özel etiket
            backgroundColor: Colors.green,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
            },
            label: const Text("Ürün Ekle", style: TextStyle(color: Colors.white)),
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('userId', isEqualTo: user?.uid) // Sadece bu işletmenin ürünleri
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

              // Fiyat Gösterimi (Hata önleyici)
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
                      FirebaseFirestore.instance.collection('products').doc(products[index].id).delete();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}