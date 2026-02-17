import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'scan_qr_screen.dart';

class BusinessOrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const BusinessOrderDetailScreen({super.key, required this.orderData});

  @override
  State<BusinessOrderDetailScreen> createState() => _BusinessOrderDetailScreenState();
}

class _BusinessOrderDetailScreenState extends State<BusinessOrderDetailScreen> {
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);
  final Color cardBg = const Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    String orderId = widget.orderData['id'] ?? '';
    // Müşteri ekranındaki kodla aynı olması için ID'nin ilk 8 hanesi büyük harfle alınır
    String displayOrderId = orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();

    String productName = widget.orderData['productName'] ?? 'Ürün';
    String imageUrl = widget.orderData['imageUrl'] ?? 'https://cdn-icons-png.flaticon.com/512/2921/2921822.png';
    double price = double.tryParse(widget.orderData['price'].toString()) ?? 0.0;
    String status = widget.orderData['status'] ?? 'active';
    String note = widget.orderData['orderNote'] ?? 'Sipariş notu yok.';

    // Müşteri Bilgileri
    String customerId = widget.orderData['customerId'] ?? '';
    String customerName = widget.orderData['customerName'] ?? 'İsim Girilmemiş';
    String customerSurname = widget.orderData['customerSurname'] ?? '';
    String customerPhone = widget.orderData['customerPhone'] ?? 'Telefon Yok';

    // Yorum ve Puan (Varsa)
    double? rating = widget.orderData['rating'] != null ? double.tryParse(widget.orderData['rating'].toString()) : null;
    String? review = widget.orderData['review'];

    Timestamp? timestamp = widget.orderData['orderDate'] as Timestamp?;
    String dateStr = timestamp != null ? "${timestamp.toDate().day}.${timestamp.toDate().month}.${timestamp.toDate().year} - ${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}" : "Tarih Yok";

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        title: const Text("Sipariş Detayı", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Müşteri Güvenilirlik (Korundu)
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('orders').where('customerId', isEqualTo: customerId).where('status', isEqualTo: 'issue').get(),
              builder: (context, snapshot) {
                int issueCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                bool isRisk = issueCount > 0;
                return Container(
                  width: double.infinity, padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: isRisk ? Colors.red.withOpacity(0.1) : aestheticGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: isRisk ? Colors.red : aestheticGreen)),
                  child: Row(children: [Icon(isRisk ? Icons.warning_amber_rounded : Icons.verified_user, color: isRisk ? Colors.red : aestheticGreen, size: 30), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isRisk ? "DİKKAT: RİSKLİ MÜŞTERİ" : "GÜVENİLİR MÜŞTERİ", style: TextStyle(color: isRisk ? Colors.red : aestheticGreen, fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text(isRisk ? "Bu müşteri daha önce $issueCount siparişini teslim almaya gelmedi!" : "Bu müşterinin geçmişinde sorunlu işlem bulunmuyor.", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13))]))]),
                );
              },
            ),

            // Ürün Kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))),
              child: Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(imageUrl, width: 90, height: 90, fit: BoxFit.cover)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(productName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text("${price.toStringAsFixed(2)}₺", style: TextStyle(color: aestheticGreen, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), _buildStatusBadge(status)]))
              ]),
            ),
            const SizedBox(height: 24),

            // Müşteri Değerlendirmesi (ANONİM)
            if (rating != null) ...[
              const Text("Müşteri Değerlendirmesi ⭐", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.withOpacity(0.3))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text("$rating/5.0", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        Text("Anonim Yorum", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ),
                    if (review != null && review.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(review, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Müşteri Bilgileri
            const Text("Müşteri Bilgileri 👤", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
              child: Column(children: [
                _buildInfoRow(Icons.person, "Ad Soyad", "$customerName $customerSurname"),
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white.withOpacity(0.05))),
                _buildInfoRow(Icons.phone, "Telefon", customerPhone),
              ]),
            ),
            const SizedBox(height: 24),

            // --- GÜNCELLENEN: SİPARİŞ BİLGİLERİ (SİPARİŞ NO EKLENDİ) ---
            const Text("Sipariş Bilgileri 📝", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
              child: Column(children: [
                _buildInfoRow(Icons.calendar_today, "Sipariş Tarihi", dateStr),
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white.withOpacity(0.05))),
                _buildInfoRow(Icons.receipt_long, "Sipariş No", "#$displayOrderId"), // Müşterideki numara ile aynı
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white.withOpacity(0.05))),
                _buildInfoRow(Icons.note, "Müşteri Notu", note),
              ]),
            ),
            // -------------------------------------------------------------

            const SizedBox(height: 40),

            // Aksiyon Butonları
            if (status == 'active') ...[
              SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(onPressed: () => _updateStatus(orderId, 'declined'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), icon: const Icon(Icons.close, color: Colors.white), label: const Text("RİSKLİ / İPTAL ET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(onPressed: () => _updateStatus(orderId, 'preparing'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), icon: const Icon(Icons.soup_kitchen, color: Colors.white), label: const Text("HAZIRLAMAYA BAŞLA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
            ] else if (status == 'preparing') ...[
              SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(onPressed: () => _updateStatus(orderId, 'ready'), style: ElevatedButton.styleFrom(backgroundColor: aestheticGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), icon: const Icon(Icons.check, color: Colors.black), label: const Text("HAZIR / PAKETLENDİ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)))),
            ] else if (status == 'ready') ...[
              Row(children: [
                Expanded(child: SizedBox(height: 56, child: ElevatedButton(onPressed: () => _updateStatus(orderId, 'issue'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), side: const BorderSide(color: Colors.red)), child: const Text("MÜŞTERİ GELMEDİ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13))))),
                const SizedBox(width: 16),
                Expanded(child: SizedBox(height: 56, child: ElevatedButton(onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanQRScreen())); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text("QR İLE TESLİM ET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))))),
              ]),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white70, size: 20)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500))]))]);
  }

  Widget _buildStatusBadge(String status) {
    Color color; String text;
    switch (status) { case 'active': color = Colors.blueAccent; text = "Yeni Sipariş"; break; case 'preparing': color = Colors.orange; text = "Hazırlanıyor"; break; case 'ready': color = aestheticGreen; text = "Teslimat Bekliyor"; break; case 'completed': color = Colors.grey; text = "Tamamlandı"; break; case 'cancelled': color = Colors.red; text = "İptal Edildi"; break; case 'issue': color = Colors.redAccent; text = "Müşteri Gelmedi"; break; default: color = Colors.white; text = status; }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.5))), child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)));
  }

  void _updateStatus(String docId, String newStatus) {
    FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': newStatus});
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sipariş durumu güncellendi.")));
  }
}