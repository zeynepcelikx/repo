import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CustomerOrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const CustomerOrderDetailScreen({super.key, required this.orderData});

  @override
  State<CustomerOrderDetailScreen> createState() => _CustomerOrderDetailScreenState();
}

class _CustomerOrderDetailScreenState extends State<CustomerOrderDetailScreen> {
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);
  final Color cardBg = const Color(0xFF1E1E1E);

  Map<String, dynamic>? _shopData;
  late Map<String, dynamic> _currentOrderData; // Güncel veriyi tutmak için
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentOrderData = Map<String, dynamic>.from(widget.orderData); // Başlangıç verisini kopyala
    _fetchShopDetails();
    _listenToOrderChanges(); // Siparişi anlık dinle
  }

  // Siparişteki değişiklikleri anlık dinle (Biz güncellediğimizde ekran anında değişsin)
  void _listenToOrderChanges() {
    String orderId = _currentOrderData['id'] ?? '';
    if (orderId.isNotEmpty) {
      FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots().listen((snapshot) {
        if (snapshot.exists && mounted) {
          setState(() {
            var data = snapshot.data() as Map<String, dynamic>;
            data['id'] = snapshot.id;
            _currentOrderData = data;
          });
        }
      });
    }
  }

  // Dükkan Bilgilerini Çek
  Future<void> _fetchShopDetails() async {
    String? sellerId = _currentOrderData['sellerId'];
    if (sellerId != null) {
      try {
        DocumentSnapshot shopDoc = await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
        if (shopDoc.exists) {
          if (mounted) {
            setState(() {
              _shopData = shopDoc.data() as Map<String, dynamic>;
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        debugPrint("Dükkan bilgisi çekilemedi: $e");
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- YENİ EKLENEN: BİLGİ DÜZENLEME DİYALOĞU ---
  Future<void> _showEditInfoDialog() async {
    TextEditingController nameController = TextEditingController(text: _currentOrderData['customerName'] ?? '');
    TextEditingController surnameController = TextEditingController(text: _currentOrderData['customerSurname'] ?? '');
    TextEditingController phoneController = TextEditingController(text: _currentOrderData['customerPhone'] ?? '');
    TextEditingController noteController = TextEditingController(text: _currentOrderData['orderNote'] ?? '');

    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    // RENK GÜNCELLENDİ: Mavi yerine aestheticGreen
                    decoration: BoxDecoration(color: aestheticGreen.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.edit_document, color: aestheticGreen, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text("Bilgileri Güncelle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 16),

                  _buildDialogTextField(nameController, "Adınız", Icons.person_rounded),
                  const SizedBox(height: 12),
                  _buildDialogTextField(surnameController, "Soyadınız", Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  _buildDialogTextField(phoneController, "Telefon (5XX...)", Icons.phone_iphone_rounded, isNumber: true),
                  const SizedBox(height: 12),
                  _buildDialogTextField(noteController, "Sipariş Notu (İsteğe Bağlı)", Icons.note_alt_outlined),

                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: Colors.white.withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: const Text("Vazgeç", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          // RENK GÜNCELLENDİ: Mavi yerine aestheticGreen ve text rengi siyah
                          style: ElevatedButton.styleFrom(backgroundColor: aestheticGreen, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 8, shadowColor: aestheticGreen.withOpacity(0.4)),
                          onPressed: () {
                            if (nameController.text.trim().isEmpty || surnameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Row(children: [Icon(Icons.error_outline, color: Colors.white), SizedBox(width: 8), Text("İsim, Soyisim ve Telefon zorunludur!")]), backgroundColor: Colors.redAccent.withOpacity(0.8), behavior: SnackBarBehavior.floating));
                              return;
                            }
                            Navigator.pop(ctx, true);
                          },
                          child: const Text("Kaydet", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirm == true) {
      _updateOrderInfo(
        nameController.text.trim(),
        surnameController.text.trim(),
        phoneController.text.trim(),
        noteController.text.trim(),
      );
    }
  }

  Widget _buildDialogTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.08)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 2))]),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)] : [],
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          // RENK GÜNCELLENDİ: Mavi yerine aestheticGreen
          prefixIcon: Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: aestheticGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: aestheticGreen, size: 20)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // Bilgileri Veritabanına Kaydet ve Bildirim Gönder
  Future<void> _updateOrderInfo(String newName, String newSurname, String newPhone, String newNote) async {
    setState(() => _isLoading = true);
    try {
      String orderId = _currentOrderData['id'];
      String sellerId = _currentOrderData['sellerId'];
      String productName = _currentOrderData['productName'] ?? 'Ürün';
      User? user = FirebaseAuth.instance.currentUser;

      // 1. Siparişi Güncelle
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'customerName': newName,
        'customerSurname': newSurname,
        'customerPhone': newPhone,
        'orderNote': newNote,
      });

      // 2. Müşteriye Bildirim
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notifications').add({
          'title': 'Bilgiler Güncellendi ✏️',
          'body': '$productName siparişinizin teslimat bilgileri başarıyla güncellendi.',
          'isRead': false,
          'type': 'update',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // 3. Restorana Bildirim
      if (sellerId.isNotEmpty) {
        String displayOrderId = orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();
        await FirebaseFirestore.instance.collection('users').doc(sellerId).collection('notifications').add({
          'title': 'Sipariş Bilgisi Değişti! 🔄',
          'body': '#$displayOrderId numaralı siparişin müşteri bilgileri/notu güncellendi. Lütfen kontrol edin.',
          'isRead': false,
          'type': 'update',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Bilgileriniz güncellendi!"), backgroundColor: aestheticGreen));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Verileri Hazırla (Artık _currentOrderData'dan okuyoruz)
    final data = _currentOrderData;
    String productName = data['productName'] ?? 'Ürün';
    double price = double.tryParse(data['price'].toString()) ?? 0.0;
    String status = data['status'] ?? 'active';
    String note = data['orderNote'] ?? '';
    String imageUrl = data['imageUrl'] ?? 'https://cdn-icons-png.flaticon.com/512/2921/2921822.png';
    String orderId = data['id'] ?? '';

    String customerName = data['customerName'] ?? '';
    String customerSurname = data['customerSurname'] ?? '';
    String customerPhone = data['customerPhone'] ?? '';

    // Tarih
    Timestamp? timestamp = data['orderDate'] as Timestamp?;
    String dateStr = "Tarih Yok";
    if (timestamp != null) {
      DateTime d = timestamp.toDate();
      dateStr = "${d.day}.${d.month}.${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
    }

    // Dükkan Bilgileri
    String shopName = _shopData?['businessName'] ?? _shopData?['name'] ?? 'Restoran';
    String shopAddress = _shopData?['address'] ?? 'Adres bilgisi yükleniyor...';
    String shopPhone = _shopData?['phone'] ?? 'Telefon Yok';

    // Sipariş henüz hazırlanmadıysa düzenleme butonunu göster
    bool canEdit = (status == 'active' || status == 'preparing');

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        title: const Text("Sipariş Detayı", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: aestheticGreen))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. ÜRÜN KARTI ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(productName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text("${price.toStringAsFixed(2)}₺", style: TextStyle(color: aestheticGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        _buildStatusBadge(status),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 2. QR KOD ---
            if (status == 'active' || status == 'preparing' || status == 'ready') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: aestheticGreen.withOpacity(0.3)), // Yeşil çerçeve vurgusu
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    const Text("Teslimat Kodu", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: orderId,
                        version: QrVersions.auto,
                        size: 160.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Siparişi teslim alırken bu kodu gösterin.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // --- 3. SİPARİŞ BİLGİLERİ (VE DÜZENLEME BUTONU) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Sipariş Bilgileri 🧾", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                if (canEdit)
                  GestureDetector(
                    onTap: _showEditInfoDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      // RENK GÜNCELLENDİ: Mavi yerine aestheticGreen
                      decoration: BoxDecoration(color: aestheticGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: aestheticGreen.withOpacity(0.5))),
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: aestheticGreen, size: 14),
                          const SizedBox(width: 4),
                          Text("Düzenle", style: TextStyle(color: aestheticGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.calendar_today, "Sipariş Tarihi", dateStr),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white.withOpacity(0.05))),
                  _buildInfoRow(Icons.receipt, "Sipariş No", "#${orderId.substring(0, 8).toUpperCase()}"),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white.withOpacity(0.05))),
                  _buildInfoRow(Icons.person, "Teslim Alacak", "$customerName $customerSurname"),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white.withOpacity(0.05))),
                  _buildInfoRow(Icons.phone, "İletişim", customerPhone),

                  if (note.isNotEmpty) ...[
                    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white.withOpacity(0.05))),
                    _buildInfoRow(Icons.note, "Notunuz", note),
                  ]
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 4. DÜKKAN İLETİŞİM & KONUM ---
            const Text("Dükkan Bilgileri 📍", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.store, "Restoran", shopName),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white.withOpacity(0.05))),
                  _buildInfoRow(Icons.map, "Adres", shopAddress),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white.withOpacity(0.05))),
                  _buildInfoRow(Icons.phone, "Telefon", shopPhone),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: aestheticGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'active':
      case 'preparing':
        color = const Color(0xFFFF9800);
        text = "Hazırlanıyor";
        icon = Icons.soup_kitchen;
        break;
      case 'ready':
        color = aestheticGreen;
        text = "Teslim Alınabilir";
        icon = Icons.shopping_bag;
        break;
      case 'completed':
        color = Colors.blue;
        text = "Teslim Edildi";
        icon = Icons.check_circle;
        break;
      case 'cancelled':
      case 'declined':
        color = Colors.red;
        text = "İptal Edildi";
        icon = Icons.cancel;
        break;
      case 'issue':
        color = Colors.redAccent;
        text = "Sorunlu";
        icon = Icons.warning;
        break;
      default:
        color = Colors.grey;
        text = "Bilinmiyor";
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}