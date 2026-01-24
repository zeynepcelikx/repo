import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BusinessOrdersScreen extends StatefulWidget {
  const BusinessOrdersScreen({super.key});

  @override
  State<BusinessOrdersScreen> createState() => _BusinessOrdersScreenState();
}

class _BusinessOrdersScreenState extends State<BusinessOrdersScreen> {

  // Siparişi "Tamamlandı" olarak işaretleme fonksiyonu
  void _completeOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'completed', // Durumu değiştiriyoruz
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sipariş teslim edildi olarak işaretlendi! ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Center(child: Text("Giriş yapmalısınız."));

    return Scaffold(
      appBar: AppBar(title: const Text("Gelen Siparişler 🛎️")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('sellerId', isEqualTo: user.uid) // Sadece BENİM dükkanıma gelenler
        // .orderBy('orderDate', descending: true) // Hata verirse burayı kapat (Index sorunu olmasın diye)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Henüz gelen bir sipariş yok."),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              final bool isActive = order['status'] == 'active';

              // Tarih Formatı (Basit)
              String dateStr = "";
              if (order['orderDate'] != null) {
                Timestamp ts = order['orderDate'];
                DateTime date = ts.toDate();
                dateStr = "${date.hour}:${date.minute} - ${date.day}/${date.month}";
              }

              return Card(
                elevation: isActive ? 4 : 1, // Aktifler daha belirgin
                color: isActive ? Colors.white : Colors.grey.shade100,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Ürün Resmi (Küçük)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              order['imageUrl'] ?? '',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (c, o, s) => const Icon(Icons.fastfood),
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Bilgiler
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order['productName'] ?? 'Ürün',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  "Müşteri: ${order['customerEmail'] ?? 'Bilinmiyor'}",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "${order['price']} ₺  •  $dateStr",
                                  style: TextStyle(
                                      color: isActive ? Colors.green : Colors.black54,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      // BUTONLAR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isActive) ...[
                            const Text("Durum: Hazırlanıyor ⏳ ", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _completeOrder(orderId),
                              icon: const Icon(Icons.check),
                              label: const Text("TESLİM ET"),
                            ),
                          ] else ...[
                            const Text("Durum: Teslim Edildi ✅", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ]
                        ],
                      )
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