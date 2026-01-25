import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BusinessOrdersScreen extends StatefulWidget {
  const BusinessOrdersScreen({super.key});

  @override
  State<BusinessOrdersScreen> createState() => _BusinessOrdersScreenState();
}

class _BusinessOrdersScreenState extends State<BusinessOrdersScreen> {

  // --- MÜŞTERİNİN RİSK DURUMUNU ÇEKME (DÜZELTİLDİ 🛠️) ---
  // Artık alan yoksa hata vermez, 0 döndürür.
  Future<int> _getCustomerWarnings(String customerId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(customerId).get();
      if (userDoc.exists) {
        // Veriyi güvenli bir harita (Map) olarak alıyoruz
        final data = userDoc.data() as Map<String, dynamic>?;

        // Eğer data boş değilse ve içinde 'warningCount' varsa onu al, yoksa 0 al.
        if (data != null && data.containsKey('warningCount')) {
          return data['warningCount'];
        }
      }
    } catch (e) {
      print("Kullanıcı risk verisi alınamadı: $e");
    }
    return 0; // Hata olursa veya alan yoksa temiz say
  }

  // --- 1. SİPARİŞİ REDDET ---
  void _rejectOrder(String orderId, String customerId, String productId, String productName) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'rejected',
      });

      await FirebaseFirestore.instance.collection('products').doc(productId).update({
        'stock': FieldValue.increment(1),
      });

      await FirebaseFirestore.instance.collection('users').doc(customerId).collection('notifications').add({
        'title': 'Siparişiniz İptal Edildi ❌',
        'body': 'Üzgünüz, işletme $productName siparişini hazırlayamadığı için iptal etti.',
        'date': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sipariş reddedildi ve stok iade edildi.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  // --- 2. SİPARİŞİ 'HAZIRLANDI' YAP ---
  void _markAsReady(String orderId, String customerId, String productName) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'ready',
      });

      await FirebaseFirestore.instance.collection('users').doc(customerId).collection('notifications').add({
        'title': 'Siparişiniz Hazır! 🛍️',
        'body': '$productName paketlendi. QR Kodunuzla teslim alabilirsiniz.',
        'date': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Müşteriye hazır bildirimi gitti!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  // --- 3. MÜŞTERİ GELMEDİ (CEZA SİSTEMİ - GÜVENLİ HALE GETİRİLDİ 🛡️) ---
  void _markAsNoShow(String orderId, String customerId, String productId, String productName) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Müşteri Gelmedi mi? ⚠️"),
        content: const Text("Bu işlem müşteriye 1 uyarı puanı verecek ve stok tekrar satışa açılacak. Onaylıyor musunuz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Vazgeç")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Evet, Gelmedi", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // A. Sipariş Durumu
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'no_show',
        'causedWarning': true,
      });

      // B. Stok İadesi
      await FirebaseFirestore.instance.collection('products').doc(productId).update({
        'stock': FieldValue.increment(1),
      });

      // C. KULLANICIYA UYARI PUANI EKLE (GÜVENLİ TRANSACTION)
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(customerId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);

        if (!snapshot.exists) return; // Kullanıcı yoksa işlem yapma

        // Veriyi güvenli oku
        final data = snapshot.data() as Map<String, dynamic>?;
        int currentWarnings = 0;

        if (data != null && data.containsKey('warningCount')) {
          currentWarnings = data['warningCount'];
        }

        int newWarnings = currentWarnings + 1;
        bool shouldBan = newWarnings >= 3;

        // Güncelle
        transaction.update(userRef, {
          'warningCount': newWarnings,
          'isBanned': shouldBan,
        });
      });

      // D. Bildirim
      await userRef.collection('notifications').add({
        'title': 'Uyarı Aldınız! ⚠️',
        'body': 'Siparişi almadığınız için 1 uyarı puanı aldınız. 3 olunca hesabınız kapanacak!',
        'date': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Müşteriye uyarı verildi ve stok açıldı.")));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  // --- 4. QR TARAMA VE TESLİM ---
  void _scanAndComplete(String orderId, String customerId, String productName) async {
    final scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VerificationScanner()),
    );

    if (scannedCode == null) return;

    if (scannedCode == orderId) {
      _completeOrder(orderId, customerId, productName);
    } else {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Hatalı QR Kod ⚠️", style: TextStyle(color: Colors.red)),
          content: const Text("Okuttuğunuz kod bu siparişe ait değil!"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tamam"))
          ],
        ),
      );
    }
  }

  void _completeOrder(String orderId, String customerId, String productName) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'completed',
      });

      await FirebaseFirestore.instance.collection('users').doc(customerId).collection('notifications').add({
        'title': 'Afiyet Olsun! 🍽️',
        'body': '$productName başarıyla teslim edildi.',
        'date': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Doğrulandı ve Teslim Edildi! ✅")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Gelen Siparişler 🛎️")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('sellerId', isEqualTo: user?.uid)
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz sipariş yok."));
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

              String customerPhone = order['customerPhone'] ?? 'Numara Yok';
              String customerId = order['customerId'];

              Color cardColor = Colors.white;
              Widget statusWidget;

              if (status == 'canceled') {
                cardColor = Colors.red.shade50;
                statusWidget = const Text("MÜŞTERİ İPTAL ETTİ ❌", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
              } else if (status == 'rejected') {
                cardColor = Colors.orange.shade50;
                statusWidget = const Text("REDDETTİNİZ 🚫", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold));
              } else if (status == 'no_show') {
                cardColor = Colors.grey.shade300;
                statusWidget = const Text("GELMEDİ (UYARI VERİLDİ) ⚠️", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold));
              } else if (status == 'completed') {
                cardColor = Colors.green.shade50;
                statusWidget = const Text("TESLİM EDİLDİ ✅", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
              } else {
                statusWidget = const SizedBox();
              }

              return Card(
                elevation: 3,
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      // ÜST KISIM
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              order['imageUrl'] ?? '',
                              width: 60, height: 60, fit: BoxFit.cover,
                              errorBuilder: (c, o, s) => const Icon(Icons.fastfood),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(order['productName'] ?? 'Ürün', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 5),

                                // MÜŞTERİ BİLGİSİ VE RİSK PUANI 🕵️‍♂️
                                FutureBuilder<int>(
                                  future: _getCustomerWarnings(customerId),
                                  builder: (context, snapshot) {
                                    int warnings = snapshot.data ?? 0;
                                    Color riskColor = warnings == 0 ? Colors.green : (warnings < 3 ? Colors.orange : Colors.red);

                                    // Sadece uyarı varsa rozet göster
                                    if (warnings == 0) {
                                      return Row(children: [
                                        const Icon(Icons.person, size: 14, color: Colors.grey),
                                        const SizedBox(width: 5),
                                        Expanded(child: Text(order['customerEmail'] ?? 'Bilinmiyor', style: const TextStyle(fontSize: 12))),
                                      ]);
                                    }

                                    return Row(
                                      children: [
                                        const Icon(Icons.person, size: 14, color: Colors.grey),
                                        const SizedBox(width: 5),
                                        Expanded(child: Text(order['customerEmail'] ?? 'Bilinmiyor', style: const TextStyle(fontSize: 12))),
                                        Container(
                                          margin: const EdgeInsets.only(left: 5),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: riskColor, borderRadius: BorderRadius.circular(8)),
                                          child: Text("$warnings Uyarı!", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        )
                                      ],
                                    );
                                  },
                                ),
                                Row(children: [
                                  const Icon(Icons.phone, size: 14, color: Colors.blue),
                                  const SizedBox(width: 5),
                                  Text(customerPhone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                                ]),
                                const SizedBox(height: 5),
                                Text("${order['price']} ₺", style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(),

                      // --- BUTONLAR ---
                      if (status == 'preparing') ...[
                        const Text("Durum: Hazırlanıyor 👨‍🍳", style: TextStyle(color: Colors.orange)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
                                onPressed: () => _rejectOrder(orderId, customerId, order['productId'], order['productName']),
                                child: const Text("REDDET", style: TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                onPressed: () => _markAsReady(orderId, customerId, order['productName']),
                                child: const Text("HAZIRLANDI 📦", style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        )
                      ] else if (status == 'ready') ...[
                        const Text("Müşteri bekleniyor... 🛍️", style: TextStyle(color: Colors.blue)),
                        const SizedBox(height: 10),
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                onPressed: () => _scanAndComplete(orderId, customerId, order['productName']),
                                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                                label: const Text("QR İLE TESLİM ET", style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextButton.icon(
                              onPressed: () => _markAsNoShow(orderId, customerId, order['productId'], order['productName']),
                              icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                              label: const Text("Müşteri Gelmedi (Stok İade Et & Uyar)", style: TextStyle(color: Colors.red, fontSize: 12)),
                            )
                          ],
                        )
                      ] else ...[
                        statusWidget
                      ]
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

class VerificationScanner extends StatelessWidget {
  const VerificationScanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Kodu Okutun 📸")),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            final String code = barcodes.first.rawValue!;
            Navigator.pop(context, code);
          }
        },
      ),
    );
  }
}