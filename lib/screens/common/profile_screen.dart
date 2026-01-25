import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../customer/favorites_screen.dart';
import 'support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isBusiness = false;
  int _orderCount = 0;
  int _warningCount = 0; // YENİ: Uyarı sayısı durumu

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchOrderStats();
  }

  void _loadUserData() async {
    if (user == null) return;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _isBusiness = data['role'] == 'business';
          // Uyarı sayısını çek (Yoksa 0 kabul et)
          _warningCount = data['warningCount'] ?? 0;

          if (_isBusiness) {
            _nameController.text = data['businessName'] ?? '';
            _addressController.text = data['address'] ?? '';
          } else {
            _nameController.text = data['name'] ?? '';
          }
          _phoneController.text = data['phone'] ?? '';
        });
      }
    } catch (e) {
      print("Profil hatası: $e");
    }
  }

  void _fetchOrderStats() async {
    if (user == null) return;
    try {
      String fieldName = _isBusiness ? 'sellerId' : 'customerId';
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where(fieldName, isEqualTo: user!.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      setState(() {
        _orderCount = snapshot.docs.length;
      });
    } catch (e) {
      print("İstatistik hatası: $e");
    }
  }

  void _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> updateData = {
        'phone': _phoneController.text.trim(),
      };
      if (_isBusiness) {
        updateData['businessName'] = _nameController.text.trim();
        updateData['address'] = _addressController.text.trim();
      } else {
        updateData['name'] = _nameController.text.trim();
      }
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update(updateData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bilgiler güncellendi! ✅")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    int savedAmount = _orderCount * 50;

    // Uyarı Durumuna Göre Renk ve Metin Ayarları 🎨
    Color statusColor = _warningCount == 0 ? Colors.green : (_warningCount < 3 ? Colors.orange : Colors.red);
    String statusText = _warningCount == 0 ? "Güvenilir Hesap 🛡️" : "$_warningCount Ceza Puanı ⚠️";
    String statusSubText = _warningCount == 0 ? "Teşekkürler, harikasın!" : "3 puanda hesap kapatılır.";
    IconData statusIcon = _warningCount == 0 ? Icons.verified_user : Icons.warning_amber_rounded;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Profilim", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: Colors.red))
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // --- HEADER (AVATAR) ---
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green.shade400,
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              user?.email ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),

            // --- İSTATİSTİK KARTI ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text("$_orderCount", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                        const Text("Yemek Kurtardın", style: TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                    Container(height: 40, width: 1, color: Colors.green.shade200),
                    Column(
                      children: [
                        Text("$savedAmount₺", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                        const Text("Tasarruf Ettin", style: TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- YENİ ÖZELLİK: GÜVEN DURUMU (Sadece Müşteriler) ---
            if (!_isBusiness)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: statusColor.withOpacity(0.2)),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 24),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(statusSubText, style: TextStyle(color: statusColor.withOpacity(0.8), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // --- MENÜ BUTONLARI ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // FAVORİLERİM BUTONU ❤️ (Sadece Müşteriler)
                  if (!_isBusiness)
                    Column(
                      children: [
                        ListTile(
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          leading: const Icon(Icons.favorite, color: Colors.red),
                          title: const Text("Favorilerim"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),

                  // YARDIM & DESTEK BUTONU 🛟
                  ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    leading: const Icon(Icons.help_outline, color: Colors.blue),
                    title: const Text("Yardım & Destek"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // --- DÜZENLEME FORMU ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Bilgilerini Güncelle ✏️", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: _isBusiness ? "İşletme Adı" : "Ad Soyad",
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Telefon Numarası",
                      hintText: "05XX XXX XX XX",
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 15),

                  if (_isBusiness) ...[
                    TextField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Dükkan Açık Adresi",
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                      ),
                      onPressed: _isLoading ? null : _updateProfile,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("KAYDET ✅", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}