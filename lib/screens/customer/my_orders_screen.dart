import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  // Tasarım Renkleri
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);

  // Tab Kontrolü (0: Aktif, 1: Geçmiş)
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Siparişlerim 🧾",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  // --- GÜNCELLENEN KISIM: İSTATİSTİK BUTONU ---
                  GestureDetector(
                    onTap: () => _showOrderStatistics(user?.uid), // Fonksiyonu bağladık
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Icon(Icons.bar_chart, color: Colors.white70, size: 20), // İkonu grafik yaptık
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 2. TAB MENÜSÜ ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  _buildTabButton("Aktif Siparişler", 0),
                  _buildTabButton("Geçmiş", 1),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 3. SİPARİŞ LİSTESİ ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('customerId', isEqualTo: user?.uid)
                    .orderBy('orderDate', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: aestheticGreen));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Verileri Filtrele
                  var allOrders = snapshot.data!.docs;
                  var filteredOrders = allOrders.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String status = data['status'] ?? 'active';

                    if (_selectedTab == 0) {
                      return ['active', 'preparing', 'ready'].contains(status);
                    } else {
                      return ['completed', 'cancelled', 'declined', 'issue'].contains(status);
                    }
                  }).toList();

                  if (filteredOrders.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      var orderDoc = filteredOrders[index];
                      var data = orderDoc.data() as Map<String, dynamic>;
                      data['id'] = orderDoc.id;

                      return _buildOrderCard(data);
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

  // --- YENİ ÖZELLİK: İSTATİSTİK GÖSTERME ---
  void _showOrderStatistics(String? uid) {
    if (uid == null) return;

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
                  const Text("Hesap Özeti 📊", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white54))
                ],
              ),
              const SizedBox(height: 20),

              // Verileri Çek ve Göster
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('orders')
                    .where('customerId', isEqualTo: uid)
                    .where('status', isEqualTo: 'completed') // Sadece tamamlananlar
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: aestheticGreen));
                  }

                  int totalCount = 0;
                  double totalSpent = 0.0;

                  if (snapshot.hasData) {
                    totalCount = snapshot.data!.docs.length;
                    for (var doc in snapshot.data!.docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      totalSpent += double.tryParse(data['price'].toString()) ?? 0.0;
                    }
                  }

                  return Column(
                    children: [
                      // Toplam Harcama Kartı
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: aestheticGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: aestheticGreen.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: aestheticGreen.withOpacity(0.2), shape: BoxShape.circle),
                              child: Icon(Icons.account_balance_wallet, color: aestheticGreen, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Toplam Harcama", style: TextStyle(color: Colors.white70, fontSize: 14)),
                                Text("${totalSpent.toStringAsFixed(2)}₺", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Toplam Sipariş Kartı
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.receipt_long, color: Colors.blueAccent, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Tamamlanan Sipariş", style: TextStyle(color: Colors.white70, fontSize: 14)),
                                Text("$totalCount Adet", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // --- LOGIC: SİPARİŞ İPTAL ETME ---
  void _cancelOrder(String orderId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Siparişi İptal Et", style: TextStyle(color: Colors.white)),
        content: const Text("Siparişinizi iptal etmek istediğinize emin misiniz?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Vazgeç", style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Evet, İptal Et", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'cancelled'
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sipariş iptal edildi.")));
    }
  }

  // --- LOGIC: PUANLAMA ---
  void _showRatingDialog(String orderId, String productId) {
    showDialog(
      context: context,
      builder: (ctx) {
        int rating = 5;
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("Siparişi Puanla", style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Deneyiminiz nasıldı?", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              StatefulBuilder(builder: (context, setState) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.orange,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() => rating = index + 1);
                      },
                    );
                  }),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Vazgeç", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: aestheticGreen),
              onPressed: () async {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Puanınız kaydedildi! Teşekkürler.")));
              },
              child: const Text("Gönder", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }

  // --- WIDGET: SİPARİŞ KARTI ---
  Widget _buildOrderCard(Map<String, dynamic> data) {
    String status = data['status'] ?? 'active';
    String productName = data['productName'] ?? 'Ürün';
    double price = double.tryParse(data['price'].toString()) ?? 0.0;
    String imageUrl = data['imageUrl'] ?? 'https://cdn-icons-png.flaticon.com/512/2921/2921822.png';
    String orderId = data['id'];
    String productId = data['productId'] ?? '';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'active':
      case 'preparing':
        statusColor = const Color(0xFFFF9800);
        statusText = "Hazırlanıyor";
        statusIcon = Icons.soup_kitchen;
        break;
      case 'ready':
        statusColor = aestheticGreen;
        statusText = "Teslim Alınabilir";
        statusIcon = Icons.shopping_bag;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = "Teslim Edildi";
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
      case 'declined':
        statusColor = Colors.red;
        statusText = "İptal Edildi";
        statusIcon = Icons.cancel;
        break;
      case 'issue':
        statusColor = Colors.redAccent;
        statusText = "Sorunlu";
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = Colors.grey;
        statusText = "Bilinmiyor";
        statusIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          // Resim
          Container(
            width: 70,
            height: 70,
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
                Text(
                  productName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text("${price.toStringAsFixed(2)}₺", style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),

          // --- 3. AKSİYON BUTONLARI (SAĞ TARAF) ---
          Column(
            children: [
              // AKTİF SİPARİŞLER İÇİN: QR ve İPTAL
              if (status == 'active' || status == 'preparing' || status == 'ready') ...[
                // QR Kod Butonu
                GestureDetector(
                  onTap: () => _showQRCode(orderId),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: aestheticGreen.withOpacity(0.4), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.qr_code, color: Colors.black, size: 24),
                  ),
                ),
                // İptal Butonu
                GestureDetector(
                  onTap: () => _cancelOrder(orderId),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.close, color: Colors.red, size: 18),
                  ),
                ),
              ]
              // TAMAMLANMIŞ SİPARİŞLER İÇİN: PUANLA
              else if (status == 'completed') ...[
                GestureDetector(
                  onTap: () => _showRatingDialog(orderId, productId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB74D).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star, color: Color(0xFFFFB74D), size: 16),
                        SizedBox(width: 4),
                        Text("Puanla", style: TextStyle(color: Color(0xFFFFB74D), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ]
              else
                Icon(Icons.error_outline, color: Colors.white.withOpacity(0.3), size: 28),
            ],
          ),
        ],
      ),
    );
  }

  // Tab Butonu Yardımcısı
  Widget _buildTabButton(String text, int index) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? aestheticGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: aestheticGreen.withOpacity(0.3), blurRadius: 10)] : [],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: isSelected ? Colors.black : Colors.white60, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }

  // QR Kod Gösterici
  void _showQRCode(String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Teslimat Kodu", style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: QrImageView(data: orderId, version: QrVersions.auto, size: 200.0, backgroundColor: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text("Bu kodu kasadaki görevliye gösterin.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Kapat", style: TextStyle(color: aestheticGreen))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(_selectedTab == 0 ? "Aktif siparişiniz yok." : "Geçmiş siparişiniz yok.", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
        ],
      ),
    );
  }
}