import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:indirkazan/screens/business/scan_qr_screen.dart';


class BusinessOrdersScreen extends StatefulWidget {
  const BusinessOrdersScreen({super.key});

  @override
  State<BusinessOrdersScreen> createState() => _BusinessOrdersScreenState();
}

class _BusinessOrdersScreenState extends State<BusinessOrdersScreen> {
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);
  final Color surfaceColor = const Color(0xFF1E1E1E);
  final Color warningColor = const Color(0xFFFFB74D);
  final Color errorColor = const Color(0xFFCF6679);

  // --- FİLTRELEME DURUMU ---
  String _filterStatus = 'all'; // 'all', 'active', 'ready', 'completed', 'issue'

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "";
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return "";
    }
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  // --- FİLTRE PENCERESİ AÇ ---
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                  const Text("Siparişleri Filtrele 🌪️", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white54))
                ],
              ),
              const SizedBox(height: 16),
              _buildFilterOption(ctx, "Tümü", 'all', Icons.list),
              _buildFilterOption(ctx, "Hazırlanıyor", 'active', Icons.soup_kitchen),
              _buildFilterOption(ctx, "Müşteri Bekleniyor", 'ready', Icons.hourglass_bottom),
              _buildFilterOption(ctx, "Teslim Edilenler", 'completed', Icons.check_circle),
              _buildFilterOption(ctx, "Sorunlu / Gelmedi", 'issue', Icons.warning),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(BuildContext ctx, String label, String value, IconData icon) {
    bool isSelected = _filterStatus == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? aestheticGreen : Colors.white54),
      title: Text(label, style: TextStyle(color: isSelected ? aestheticGreen : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check, color: aestheticGreen) : null,
      onTap: () {
        setState(() => _filterStatus = value);
        Navigator.pop(ctx);
      },
    );
  }

  // --- DİĞER FONKSİYONLAR (NO-SHOW, REDDET VB.) ---
  Future<void> _handleNoShow(String orderId, String customerId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        title: const Text("Müşteri Gelmedi mi?", style: TextStyle(color: Colors.white)),
        content: const Text("Bu işlem müşteriye uyarı puanı ekleyecek, BİLDİRİM GÖNDERECEK ve siparişi 'Gelmedi' olarak işaretleyecektir.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Vazgeç", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Evet, İşaretle", style: TextStyle(color: warningColor, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(customerId);
        DocumentReference orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot userSnapshot = await transaction.get(userRef);
          if (userSnapshot.exists) {
            Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
            int currentWarnings = userData['warningCount'] ?? 0;
            int newWarnings = currentWarnings + 1;
            bool isBanned = newWarnings >= 3;

            transaction.update(userRef, {'warningCount': newWarnings, 'isBanned': isBanned});
            DocumentReference newNotifRef = userRef.collection('notifications').doc();
            transaction.set(newNotifRef, {
              'title': isBanned ? 'HESABINIZ KAPATILDI 🛑' : 'Sipariş Teslim Alınmadı ⚠️',
              'body': isBanned ? '3. uyarı kotanızı doldurduğunuz için hesabınız kapatılmıştır.' : 'Siparişinizi teslim almadığınız için uyarı aldınız. ($newWarnings/3)',
              'isRead': false,
              'type': 'warning',
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
          transaction.update(orderRef, {'status': 'issue'});
        });
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Müşteriye uyarı verildi."), backgroundColor: warningColor));
      } catch (e) {
        debugPrint("Hata: $e");
      }
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        title: const Text("Siparişi Reddet", style: TextStyle(color: Colors.white)),
        content: const Text("Siparişi reddetmek istediğinize emin misiniz?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Vazgeç", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Reddet", style: TextStyle(color: errorColor, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm == true) await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': 'declined'});
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Gelen Siparişler 🔔", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 0.5)),

                      // --- FİLTRE İKONU (ARTIK İŞLEVSEL) ---
                      GestureDetector(
                        onTap: _showFilterDialog, // Menüyü açar
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _filterStatus == 'all' ? Colors.white.withOpacity(0.05) : aestheticGreen.withOpacity(0.2), // Filtre varsa yeşil yanar
                            shape: BoxShape.circle,
                            border: _filterStatus != 'all' ? Border.all(color: aestheticGreen) : null,
                          ),
                          child: Icon(Icons.filter_list, color: _filterStatus == 'all' ? Colors.white54 : aestheticGreen, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('sellerId', isEqualTo: user?.uid)
                        .where('status', whereIn: ['active', 'ready'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      int count = 0;
                      if (snapshot.hasData) count = snapshot.data!.docs.length;
                      return Text("Bugün $count aktif siparişiniz var", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w500));
                    },
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
                    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long, size: 80, color: Colors.white.withOpacity(0.1)), const SizedBox(height: 16), Text("Henüz sipariş yok.", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16))]));
                  }

                  // VERİLERİ AL VE FİLTRELE (Client-Side Filtering)
                  var docs = snapshot.data!.docs;

                  if (_filterStatus != 'all') {
                    docs = docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return data['status'] == _filterStatus;
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return Center(child: Text("Bu kriterde sipariş yok.", style: TextStyle(color: Colors.white.withOpacity(0.5))));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var doc = docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      data['id'] = doc.id;
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

  // --- SİPARİŞ KARTI ---
  Widget _buildOrderCard(Map<String, dynamic> data) {
    String status = data['status'] ?? 'active';
    String productName = data['productName'] ?? 'Ürün';
    double price = double.tryParse(data['price'].toString()) ?? 0.0;
    String imageUrl = data['imageUrl'] ?? 'https://cdn-icons-png.flaticon.com/512/2921/2921822.png';
    String customerId = data['customerId'] ?? '';
    String orderId = data['id'];
    String timeText = _formatTime(data['orderDate']);

    Color statusColor = Colors.grey;
    String statusText = "BİLİNMİYOR";
    IconData statusIcon = Icons.help;

    if (status == 'active') { statusColor = Colors.blue; statusText = "HAZIRLANIYOR"; statusIcon = Icons.soup_kitchen; }
    else if (status == 'ready') { statusColor = const Color(0xFF00E5FF); statusText = "MÜŞTERİ BEKLENİYOR"; statusIcon = Icons.hourglass_bottom; }
    else if (status == 'completed') { statusColor = aestheticGreen; statusText = "TESLİM EDİLDİ"; statusIcon = Icons.check_circle; }
    else if (status == 'issue') { statusColor = warningColor; statusText = "GELMEDİ (UYARI VERİLDİ)"; statusIcon = Icons.warning; }
    else if (status == 'declined') { statusColor = errorColor; statusText = "REDDEDİLDİ"; statusIcon = Icons.cancel; }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(customerId).get(),
      builder: (context, snapshot) {
        String customerInfo = "Yükleniyor...";
        int warningCount = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          customerInfo = userData['email'] ?? userData['name'] ?? 'Müşteri';
          warningCount = userData['warningCount'] ?? 0;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: surfaceColor.withOpacity(0.6), borderRadius: BorderRadius.circular(24), border: Border.all(color: status == 'completed' ? aestheticGreen.withOpacity(0.3) : status == 'issue' ? warningColor.withOpacity(0.3) : Colors.white.withOpacity(0.08), width: 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]),
          child: Column(
            children: [
              Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 80, height: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white.withOpacity(0.05), image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(productName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)), if (warningCount > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: warningColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: warningColor.withOpacity(0.5))), child: Text("$warningCount Uyarı!", style: TextStyle(color: warningColor, fontSize: 10, fontWeight: FontWeight.bold)))]), const SizedBox(height: 6), Row(children: [Icon(Icons.person, size: 14, color: Colors.white.withOpacity(0.4)), const SizedBox(width: 4), Expanded(child: Text(customerInfo, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis))]), const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("${price.toStringAsFixed(2)}₺", style: TextStyle(color: aestheticGreen, fontSize: 18, fontWeight: FontWeight.bold)), Text(timeText, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontWeight: FontWeight.w600))])]))])),
              Container(height: 1, width: double.infinity, color: Colors.white.withOpacity(0.05)),
              if (status == 'active') Padding(padding: const EdgeInsets.all(8.0), child: Row(children: [Expanded(flex: 2, child: TextButton(onPressed: () => _rejectOrder(orderId), child: Text("REDDET", style: TextStyle(color: errorColor, fontWeight: FontWeight.bold)))), Expanded(flex: 3, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.withOpacity(0.2), side: const BorderSide(color: Colors.blue), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => _updateStatus(orderId, 'ready'), child: const Text("HAZIRLANDI", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))))]))
              else if (status == 'ready') Padding(padding: const EdgeInsets.all(8.0), child: Row(children: [Expanded(flex: 2, child: TextButton(onPressed: () => _handleNoShow(orderId, customerId), child: Text("GELMEDİ", style: TextStyle(color: warningColor, fontWeight: FontWeight.bold)))), Expanded(flex: 3, child: ElevatedButton.icon(icon: Icon(Icons.qr_code_scanner, color: aestheticGreen), label: Text("TESLİM ET (QR)", style: TextStyle(color: aestheticGreen, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: aestheticGreen.withOpacity(0.1), side: BorderSide(color: aestheticGreen), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanQrScreen())); }))]))
              else Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(statusIcon, color: statusColor, size: 16), const SizedBox(width: 8), Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1))]))
            ],
          ),
        );
      },
    );
  }
}