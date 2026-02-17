import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'customer_order_detail_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);

  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER & İSTATİSTİK BUTONU
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Siparişlerim 🧾",
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  GestureDetector(
                    onTap: () => _showOrderStatistics(user?.uid),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.1))),
                      child: const Icon(Icons.bar_chart, color: Colors.white70, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // TAB MENÜSÜ
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
              child: Row(
                children: [
                  _buildTabButton("Aktif Siparişler", 0),
                  _buildTabButton("Geçmiş", 1),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // LİSTE
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
    String status = data['status'] ?? 'active';
    String productName = data['productName'] ?? 'Ürün';
    double price = double.tryParse(data['price'].toString()) ?? 0.0;
    String imageUrl = data['imageUrl'] ?? 'https://cdn-icons-png.flaticon.com/512/2921/2921822.png';
    String orderId = data['id'];
    String productId = data['productId'] ?? '';
    String sellerId = data['sellerId'] ?? '';

    // Puan Verisi
    double? myRating = data['rating'] != null ? double.tryParse(data['rating'].toString()) : null;
    String? myReview = data['review'];

    Timestamp? timestamp = data['orderDate'] as Timestamp?;
    String dateStr = "Tarih Yok";
    if (timestamp != null) {
      DateTime d = timestamp.toDate();
      dateStr = "${d.day}.${d.month}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
    }

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

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerOrderDetailScreen(orderData: data)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(productName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withOpacity(0.3))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(statusIcon, color: statusColor, size: 12), const SizedBox(width: 4), Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold))]),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [Icon(Icons.access_time, size: 12, color: Colors.white.withOpacity(0.5)), const SizedBox(width: 4), Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12))]),
                  const SizedBox(height: 4),
                  Text("${price.toStringAsFixed(2)}₺", style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Column(
              children: [
                if (status == 'active' || status == 'preparing' || status == 'ready') ...[
                  // ÇARPI (İPTAL) BUTONU
                  GestureDetector(
                    onTap: () => _cancelOrder(orderId, productId, sellerId, productName),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.3))),
                      child: const Icon(Icons.close, color: Colors.red, size: 20),
                    ),
                  ),
                ]
                else if (status == 'completed') ...[
                  // PUANLAMA BUTONU
                  GestureDetector(
                    onTap: () => _showRatingDialog(orderId, sellerId, currentRating: myRating, currentReview: myReview),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB74D).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(myRating != null ? Icons.star : Icons.star_border, color: const Color(0xFFFFB74D), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            myRating != null ? "$myRating" : "Puanla",
                            style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- İSTATİSTİK PENCERESİ ---
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
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('orders').where('customerId', isEqualTo: uid).where('status', isEqualTo: 'completed').get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: aestheticGreen));
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: aestheticGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: aestheticGreen.withOpacity(0.3))),
                        child: Row(children: [
                          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: aestheticGreen.withOpacity(0.2), shape: BoxShape.circle), child: Icon(Icons.account_balance_wallet, color: aestheticGreen, size: 24)),
                          const SizedBox(width: 16),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Toplam Harcama", style: TextStyle(color: Colors.white70, fontSize: 14)), Text("${totalSpent.toStringAsFixed(2)}₺", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))])
                        ]),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blueAccent.withOpacity(0.3))),
                        child: Row(children: [
                          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.receipt_long, color: Colors.blueAccent, size: 24)),
                          const SizedBox(width: 16),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Tamamlanan Sipariş", style: TextStyle(color: Colors.white70, fontSize: 14)), Text("$totalCount Adet", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))])
                        ]),
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

  // --- SİPARİŞ İPTAL (NEDEN SORAN) ---
  void _cancelOrder(String orderId, String productId, String sellerId, String productName) async {
    TextEditingController reasonController = TextEditingController();

    // Dialog ile onay ve neden al
    bool? confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => Container(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 40),
                  ),
                  const SizedBox(height: 24),
                  const Text("Siparişi İptal Et", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Bu siparişi iptal etmek istediğinize emin misiniz? Lütfen bir neden belirtin.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.5)),
                  const SizedBox(height: 20),

                  // --- İPTAL NEDENİ TEXTFIELD ---
                  TextField(
                    controller: reasonController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "İptal nedeni (örn: Geç kaldı, Yanlış sipariş)",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  // -------------------------------

                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: const Text("Vazgeç", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                          child: const Text("Evet, İptal Et", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirm == true) {
      String cancelReason = reasonController.text.trim();
      if (cancelReason.isEmpty) cancelReason = "Neden belirtilmedi";

      try {
        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': 'cancelled'});
        if (productId.isNotEmpty) await FirebaseFirestore.instance.collection('products').doc(productId).update({'stock': FieldValue.increment(1)});

        // --- BİLDİRİM GÖNDERME (NEDEN EKLENDİ) ---
        if (sellerId.isNotEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(sellerId).collection('notifications').add({
            'title': 'Sipariş İptali 🚫',
            'body': '$productName siparişi iptal edildi. Sebep: $cancelReason', // Sebep buraya eklendi
            'isRead': false,
            'type': 'cancel',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
        // ------------------------------------------

        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Sipariş iptal edildi."), backgroundColor: Colors.redAccent.withOpacity(0.8)));
      } catch (e) {
        debugPrint("İptal hatası: $e");
      }
    }
  }

  // --- PUANLAMA & YORUM ---
  void _showRatingDialog(String orderId, String sellerId, {double? currentRating, String? currentReview}) {
    double rating = currentRating ?? 5.0;
    TextEditingController reviewController = TextEditingController(text: currentReview ?? "");

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text("Değerlendirme", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Deneyiminiz nasıldı?", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(index < rating ? Icons.star : Icons.star_border, color: Colors.orange, size: 36),
                          onPressed: () { setState(() => rating = index + 1.0); },
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: reviewController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Dükkan hakkında yorumunuz...",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        filled: true, fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Vazgeç", style: TextStyle(color: Colors.white54))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: aestheticGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _submitRating(orderId, sellerId, rating, reviewController.text.trim(), oldRating: currentRating);
                  },
                  child: const Text("Kaydet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- PUAN KAYDETME ---
  Future<void> _submitRating(String orderId, String sellerId, double newRating, String review, {double? oldRating}) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({ 'rating': newRating, 'review': review });
      DocumentReference shopRef = FirebaseFirestore.instance.collection('users').doc(sellerId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot shopSnapshot = await transaction.get(shopRef);
        if (!shopSnapshot.exists) return;
        Map<String, dynamic> data = shopSnapshot.data() as Map<String, dynamic>;
        double currentTotalScore = double.tryParse(data['totalScore'].toString()) ?? 0.0;
        int currentReviewCount = int.tryParse(data['reviewCount'].toString()) ?? 0;
        double updatedTotalScore;
        int updatedReviewCount;
        if (oldRating == null) {
          updatedTotalScore = currentTotalScore + newRating;
          updatedReviewCount = currentReviewCount + 1;
        } else {
          updatedTotalScore = currentTotalScore - oldRating + newRating;
          updatedReviewCount = currentReviewCount;
        }
        transaction.update(shopRef, { 'totalScore': updatedTotalScore, 'reviewCount': updatedReviewCount });
      });

      // --- DÜKKAN SAHİBİNE BİLDİRİM GÖNDER ---
      String notificationBody = review.isNotEmpty
          ? 'Bir müşteri yeni bir yorum yaptı: "$review"'
          : 'Bir müşteri siparişine $newRating puan verdi.';

      await FirebaseFirestore.instance.collection('users').doc(sellerId).collection('notifications').add({
        'title': 'Yeni Değerlendirme! ⭐',
        'body': notificationBody,
        'isRead': false,
        'type': 'rating',
        'timestamp': FieldValue.serverTimestamp(),
      });
      // ----------------------------------------

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Değerlendirmeniz kaydedildi! ✅")));
    } catch (e) {
      debugPrint("Hata: $e");
    }
  }

  Widget _buildTabButton(String text, int index) {
    bool isSelected = _selectedTab == index;
    return Expanded(child: GestureDetector(onTap: () => setState(() => _selectedTab = index), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isSelected ? aestheticGreen : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: isSelected ? [BoxShadow(color: aestheticGreen.withOpacity(0.3), blurRadius: 10)] : []), child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.black : Colors.white60, fontWeight: FontWeight.bold, fontSize: 14)))));
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long_outlined, size: 80, color: Colors.white.withOpacity(0.1)), const SizedBox(height: 16), Text(_selectedTab == 0 ? "Aktif siparişiniz yok." : "Geçmiş siparişiniz yok.", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16))]));
  }
}