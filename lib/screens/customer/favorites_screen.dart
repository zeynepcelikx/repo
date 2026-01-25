import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Giriş yapmalısınız.")));

    return Scaffold(
      appBar: AppBar(title: const Text("Favorilerim ❤️")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text("Henüz favori ürünün yok.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final favs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: favs.length,
            itemBuilder: (context, index) {
              final fav = favs[index].data() as Map<String, dynamic>;
              final docId = favs[index].id;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fav['imageUrl'] ?? '',
                      width: 50, height: 50, fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => const Icon(Icons.fastfood),
                    ),
                  ),
                  title: Text(fav['name'] ?? 'Ürün', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${fav['price']} ₺"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      // Favorilerden Kaldır
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('favorites')
                          .doc(docId)
                          .delete();

                      // DÜZELTİLEN KISIM BURASI:
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Favorilerden çıkarıldı 💔"), // Parantez kapandı
                          duration: Duration(seconds: 1), // Duration buraya alındı
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(productData: fav),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}