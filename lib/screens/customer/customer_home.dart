import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'product_detail_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lezzetleri Keşfet 🍔"),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz kurtarılacak ürün yok."));
          }

          final products = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.70, // Kart boyunu biraz uzattık (stok yazısı sığsın diye)
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              var productData = products[index].data() as Map<String, dynamic>;
              productData['id'] = products[index].id;

              String name = productData['name'] ?? 'İsimsiz';

              // STOK OKUMA (Yeni Kısım)
              int stock = 0;
              if (productData['stock'] != null) {
                stock = int.tryParse(productData['stock'].toString()) ?? 0;
              }

              // Fiyat Okuma
              double price = 0.0;
              if (productData['discountedPrice'] != null) {
                price = double.tryParse(productData['discountedPrice'].toString()) ?? 0.0;
              } else if (productData['price'] != null) {
                price = double.tryParse(productData['price'].toString()) ?? 0.0;
              }

              double originalPrice = 0.0;
              if (productData['originalPrice'] != null) {
                originalPrice = double.tryParse(productData['originalPrice'].toString()) ?? 0.0;
              }

              int discountRate = 0;
              if (originalPrice > price && price > 0) {
                discountRate = (((originalPrice - price) / originalPrice) * 100).round();
              }

              String imageUrl = productData['imageUrl'] ?? '';
              if (imageUrl.isEmpty) {
                imageUrl = 'https://cdn-icons-png.flaticon.com/512/2921/2921822.png';
              }

              productData['price'] = price;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(productData: productData),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Resim
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                image: DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // STOK ROZETİ (Resmin üzerine)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "$stock Adet Kaldı",
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bilgiler
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (discountRate > 0)
                                      Text("${originalPrice.toStringAsFixed(2)} ₺", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 10)),
                                    Text("${price.toStringAsFixed(2)} ₺", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                                if (discountRate > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(5)),
                                    child: Text("%$discountRate", style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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