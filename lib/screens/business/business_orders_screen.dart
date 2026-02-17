import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'business_order_detail_screen.dart';
import 'scan_qr_screen.dart'; // Kartın içindeki buton için gerekli

class BusinessOrdersScreen extends StatefulWidget {
  const BusinessOrdersScreen({super.key});

  @override
  State<BusinessOrdersScreen> createState() => _BusinessOrdersScreenState();
}

class _BusinessOrdersScreenState extends State<BusinessOrdersScreen> {
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);

  // Filtreleme Seçenekleri
  String _selectedFilter = 'all';

  // Durum Metinleri
  String _getStatusText(String status) {
    switch (status) {
      case 'active': return 'Yeni Sipariş 🔔';
      case 'preparing': return 'Hazırlanıyor 🍳';
      case 'ready': return 'Müşteri Bekleniyor 🚶';
      case 'completed': return 'Teslim Edildi ✅';
      case 'declined': return 'Reddedildi ❌';
      case 'issue': return 'Müşteri Gelmedi ⚠️';
      case 'cancelled': return 'Müşteri İptal Etti 🚫';
      default: return 'Bilinmiyor';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return Colors.blueAccent;
      case 'preparing': return Colors.orange;
      case 'ready': return aestheticGreen;
      case 'completed': return Colors.grey;
      case 'declined': return Colors.red;
      case 'issue': return Colors.redAccent;
      case 'cancelled': return const Color(0xFFD32F2F);
      default: return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Gelen Siparişler", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('orders')
                            .where('sellerId', isEqualTo: user?.uid)
                            .where('status', isEqualTo: 'active')
                            .snapshots(),
                        builder: (context, snapshot) {
                          int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return Text("Bugün $count yeni siparişiniz var", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14));
                        },
                      ),
                    ],
                  ),

                  // --- SADECE FİLTRE BUTONU KALDI (QR KALDIRILDI) ---
                  IconButton(
                    onPressed: _showFilterDialog,
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                      child: const Icon(Icons.filter_list, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            // --- SİPARİŞ LİSTESİ ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('sellerId', isEqualTo: user?.uid)
                    .orderBy('orderDate', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: aestheticGreen));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  // İstemci tarafında filtreleme
                  var docs = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String status = data['status'] ?? 'active';

                    if (_selectedFilter == 'all') return true;
                    if (_selectedFilter == 'preparing') return status == 'active' || status == 'preparing';
                    return status == _selectedFilter;
                  }).toList();

                  if (docs.isEmpty) return _buildEmptyState();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var doc = docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      data['id'] = doc.id;
                      return _buildOrderCard(context, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> data) {
    String productName = data['productName'] ?? 'Ürün';
    double price = double.tryParse(data['price'].toString()) ?? 0.0;
    String status = data['status'] ?? 'active';
    String note = data['orderNote'] ?? '';
    String imageUrl = data['imageUrl'] ?? 'https://cdn-icons-png.flaticon.com/512/2921/2921822.png';
    String customerId = data['customerId'] ?? '';

    Timestamp? timestamp = data['orderDate'] as Timestamp?;
    String dateStr = "";
    if (timestamp != null) {
      DateTime d = timestamp.toDate();
      dateStr = "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
    }

    Color statusColor = _getStatusColor(status);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BusinessOrderDetailScreen(orderData: data)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resim
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 16),
                // Bilgiler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(productName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      // Müşteri İsmi (Safe Read)
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(customerId).get(),
                        builder: (context, snapshot) {
                          String customerName = "Müşteri";
                          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                            var userData = snapshot.data!.data() as Map<String, dynamic>?;
                            customerName = "${userData?['name'] ?? ''} ${userData?['surname'] ?? ''}".trim();
                            if (customerName.isEmpty) customerName = "Müşteri";
                          }
                          return Row(
                            children: [
                              const Icon(Icons.person, color: Colors.white54, size: 14),
                              const SizedBox(width: 4),
                              Text(customerName, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text("${price.toStringAsFixed(2)}₺", style: TextStyle(color: aestheticGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                // Saat ve Uyarı
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                    if (status == 'issue')
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Text("2 Uyarı!", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ],
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.note, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(note, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.2)),
              ),
              child: Center(child: Text(_getStatusText(status), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14))),
            ),

            // --- AKSİYON BUTONLARI ---
            if (status == 'active' || status == 'preparing' || status == 'ready') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (status == 'active') ...[
                    Expanded(child: _buildActionButton("Reddet", Colors.red, () => _updateStatus(data['id'], 'declined'))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildActionButton("Hazırla", Colors.orange, () => _updateStatus(data['id'], 'preparing'))),
                  ] else if (status == 'preparing') ...[
                    Expanded(child: _buildActionButton("Hazır / Pakelendi", aestheticGreen, () => _updateStatus(data['id'], 'ready'))),
                  ] else if (status == 'ready') ...[
                    // QR İLE TESLİM BUTONU BURADA KALIYOR
                    Expanded(
                      child: _buildActionButton("QR ile Teslim Et", Colors.blue, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanQRScreen()));
                      }),
                    ),
                  ],
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        shadowColor: Colors.transparent,
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 60, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text("Sipariş bulunamadı.", style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Siparişleri Filtrele", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white54))
                ],
              ),
              const SizedBox(height: 16),
              _buildFilterOption("Tümü", 'all', Icons.list),
              _buildFilterOption("Hazırlanıyor", 'preparing', Icons.soup_kitchen),
              _buildFilterOption("Müşteri Bekleniyor", 'ready', Icons.hourglass_top),
              _buildFilterOption("Teslim Edilenler", 'completed', Icons.check_circle_outline),
              _buildFilterOption("Müşteri Gelmedi", 'issue', Icons.warning_amber),
              _buildFilterOption("İptal Edilenler", 'cancelled', Icons.cancel_outlined),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String text, String value, IconData icon) {
    bool isSelected = _selectedFilter == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? aestheticGreen : Colors.white54),
      title: Text(text, style: TextStyle(color: isSelected ? aestheticGreen : Colors.white70, fontWeight: FontWeight.bold)),
      trailing: isSelected ? Icon(Icons.check, color: aestheticGreen) : null,
      onTap: () {
        setState(() => _selectedFilter = value);
        Navigator.pop(context);
      },
    );
  }

  void _updateStatus(String docId, String newStatus) {
    FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': newStatus});
  }
}