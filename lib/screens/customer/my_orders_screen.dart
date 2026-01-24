import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // <-- QR PAKETİ

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  // QR Gösterme Penceresi
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
                data: orderId, // Sipariş ID'si QR Koda dönüşüyor
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

              String status = order['status'] ?? 'active';
              bool isActive = status == 'active'; // Sadece aktifse QR göster

              String statusText = "Bilinmiyor";
              Color statusColor = Colors.grey;

              if (status == 'active') {
                statusText = "Hazırlanıyor ⏳";
                statusColor = Colors.deepOrange;
              } else if (status == 'completed') {
                statusText = "Teslim Edildi ✅";
                statusColor = Colors.green;
              }

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const Icon(Icons.fastfood, color: Colors.green),
                  title: Text(order['productName'] ?? 'Ürün'),
                  subtitle: Text("${order['price']} ₺ • $statusText", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),

                  // QR BUTONU (Sadece Aktif Siparişte Görünür)
                  trailing: isActive
                      ? IconButton(
                    icon: const Icon(Icons.qr_code_2, size: 32, color: Colors.black87),
                    onPressed: () => _showQRCode(context, orderId),
                  )
                      : const Icon(Icons.check_circle, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
}