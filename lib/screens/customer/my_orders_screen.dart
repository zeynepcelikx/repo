import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'add_review_dialog.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  void _showQRCode(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Sipariş Onay Kodu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: orderId,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 20),
            const Text("Kasada bu kodu gösterin.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat"))
        ],
      ),
    );
  }

  void _showRateDialog(BuildContext context, Map<String, dynamic> order, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(
        orderId: orderId,
        productId: order['productId'],
        sellerId: order['sellerId'],
      ),
    );
  }

  void _cancelOrder(BuildContext context, String orderId, String productId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Siparişi İptal Et"),
        content: const Text("Siparişini iptal etmek istediğine emin misin?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hayır")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Evet, İptal Et", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Müşteri iptali
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'canceled',
      });

      // Stok İadesi
      await FirebaseFirestore.instance.collection('products').doc(productId).update({
        'stock': FieldValue.increment(1),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sipariş iptal edildi.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Giriş yapmalısınız."));

    return Scaffold(
      appBar: AppBar(title: const Text("Siparişlerim 🧾")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('customerId', isEqualTo: user.uid)
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz hiç yemek kurtarmadın!"));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;

              String status = order['status'] ?? 'preparing';
              if (status == 'active') status = 'preparing';

              bool isReviewed = order['isReviewed'] == true;
              bool causedWarning = order['causedWarning'] == true; // Bu sipariş uyarı sebebi mi?

              String statusText = "";
              Color statusColor = Colors.grey;
              IconData statusIcon = Icons.help;
              bool canCancel = false;

              switch (status) {
                case 'preparing':
                  statusText = "Hazırlanıyor 👨‍🍳";
                  statusColor = Colors.deepOrange;
                  statusIcon = Icons.soup_kitchen;
                  canCancel = true;
                  break;
                case 'ready':
                  statusText = "Paket Hazır! 🛍️";
                  statusColor = Colors.blue;
                  statusIcon = Icons.shopping_bag;
                  canCancel = false;
                  break;
                case 'completed':
                  statusText = "Teslim Edildi ✅";
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  break;
                case 'canceled':
                  statusText = "İptal Edildi ❌";
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                  break;
                case 'rejected':
                  statusText = "İşletme İptal Etti 🚫";
                  statusColor = Colors.redAccent;
                  statusIcon = Icons.store_mall_directory;
                  break;
                case 'no_show':
                  statusText = "Teslim Alınmadı! ⚠️";
                  statusColor = Colors.black;
                  statusIcon = Icons.warning;
                  break;
              }

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(statusIcon, color: statusColor, size: 30),
                        title: Text(order['productName'] ?? 'Ürün', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text("${order['price']} ₺", style: const TextStyle(color: Colors.black)),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                // --- UYARI İKONU (Eğer bu sipariş yüzünden uyarı aldıysa) ---
                                if (causedWarning)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Tooltip(
                                      message: "Bu siparişi teslim almadığınız için uyarı puanı aldınız.",
                                      child: Icon(Icons.error, color: Colors.red, size: 20),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canCancel)
                              IconButton(
                                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                tooltip: "Siparişi İptal Et",
                                onPressed: () => _cancelOrder(context, orderId, order['productId']),
                              ),

                            if (status == 'preparing' || status == 'ready')
                              IconButton(
                                icon: const Icon(Icons.qr_code_2, size: 32, color: Colors.black87),
                                tooltip: "QR Kodu Göster",
                                onPressed: () => _showQRCode(context, orderId),
                              ),

                            if (status == 'completed' && !isReviewed)
                              TextButton.icon(
                                onPressed: () => _showRateDialog(context, order, orderId),
                                icon: const Icon(Icons.star_rate_rounded, color: Colors.orange),
                                label: const Text("Puanla", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.orange.shade50,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                ),
                              ),

                            if (status == 'completed' && isReviewed)
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Icon(Icons.verified, color: Colors.orange, size: 28),
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