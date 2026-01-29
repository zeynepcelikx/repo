import 'dart:io'; // Dosya işlemleri için gerekli
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Depolama için
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Galeri seçimi için
import '../auth/login_screen.dart';
import '../customer/favorites_screen.dart';
import 'support_screen.dart';
import '../business/business_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Resim Seçici Nesnesi
  final ImagePicker _picker = ImagePicker();

  String _profileImageUrl = "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";

  bool _isLoading = false;
  bool _isUploading = false; // Fotoğraf yükleniyor mu?
  String? _userRole;

  // İstatistikler ve Durumlar
  int _ordersCount = 0;
  double _savedAmount = 0.0;
  int _warningCount = 0;
  bool _isBanned = false;

  @override
  void initState() {
    super.initState();
    _checkRoleAndFetchData();
  }

  Future<void> _checkRoleAndFetchData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _userRole = data['role'];

            if (_userRole != 'business') {
              // İsim Mantığı
              String dbName = data['name'] ?? '';
              if (dbName.isEmpty) {
                dbName = user.email?.split('@')[0] ?? 'Kullanıcı';
              }
              _nameController.text = dbName;

              // Profil Resmi Mantığı
              if (data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty) {
                _profileImageUrl = data['photoUrl'];
              }

              _phoneController.text = data['phone'] ?? '';
              _emailController.text = user.email ?? '';
              _warningCount = data['warningCount'] ?? 0;
              _isBanned = data['isBanned'] ?? false;
              _calculateCustomerStats(user.uid);
            }
          });
        }
      }
    }
  }

  Future<void> _calculateCustomerStats(String uid) async {
    QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .get();

    int count = ordersSnapshot.docs.length;
    double savings = count * 45.50;

    if (mounted) {
      setState(() {
        _ordersCount = count;
        _savedAmount = savings;
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text("Profil başarıyla güncellendi ✅"), backgroundColor: aestheticGreen)
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hata oluştu."), backgroundColor: Colors.red));
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // --- GALERİDEN SEÇ VE YÜKLE ---
  Future<void> _pickAndUploadImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Galeriyi Aç
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

      if (image == null) return; // Kullanıcı vazgeçtiyse çık

      setState(() => _isUploading = true);

      // 2. Dosyayı Hazırla
      File file = File(image.path);

      // 3. Firebase Storage Referansı (Örn: profile_photos/UID.jpg)
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');

      // 4. Yükle
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      // 5. URL'yi Al
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 6. Firestore'u Güncelle
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'photoUrl': downloadUrl
      });

      // 7. Ekranı Güncelle
      if (mounted) {
        setState(() {
          _profileImageUrl = downloadUrl;
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text("Profil fotoğrafı güncellendi! 📸"), backgroundColor: aestheticGreen)
        );
      }

    } catch (e) {
      debugPrint("Yükleme Hatası: $e");
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Fotoğraf yüklenemedi."), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return Scaffold(backgroundColor: darkBg, body: Center(child: CircularProgressIndicator(color: aestheticGreen)));
    }

    if (_userRole == 'business') {
      return const BusinessSettingsScreen();
    }

    // --- BANLI KULLANICI EKRANI ---
    if (_isBanned) {
      return Scaffold(
        backgroundColor: darkBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 80, color: Colors.red.shade400),
                const SizedBox(height: 24),
                const Text("Hesabınız Askıya Alındı", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                  "Çok fazla uyarı (3/3) aldığınız için hesabınız güvenlik nedeniyle kapatılmıştır. Lütfen destek ekibiyle iletişime geçin.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _signOut,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                  child: const Text("Çıkış Yap", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ),
      );
    }

    // --- NORMAL PROFİL EKRANI ---
    return Scaffold(
        backgroundColor: darkBg,
        body: SafeArea(
        child: Column(
        children: [
        // Header
        Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    const SizedBox(width: 40),
    const Text("Profilim", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
    IconButton(
    onPressed: _signOut,
    icon: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
    child: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
    ),
    ),
    ],
    ),
    ),

    Expanded(
    child: SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
    children: [
    const SizedBox(height: 20),

    // --- PROFİL FOTOĞRAFI ALANI ---
    Stack(
    children: [
    // Gölge
    Container(
    width: 120, height: 120,
    decoration: BoxDecoration(
    shape: BoxShape.circle,
    boxShadow: [BoxShadow(color: aestheticGreen.withOpacity(0.3), blurRadius: 40, spreadRadius: 10)],
    ),
    ),
    // Resim
    Container(
    width: 120, height: 120,
    decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: aestheticGreen.withOpacity(0.5), width: 2),
    image: DecorationImage(
    image: NetworkImage(_profileImageUrl),
    fit: BoxFit.cover
    ),
    ),
    // Yüklenirken Loading Göster
    child: _isUploading
    ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : null,
    ),
    // Kalem İkonu (GALERİ AÇAR)
    Positioned(
    bottom: 0, right: 0,
    child: GestureDetector(
    onTap: _isUploading ? null : _pickAndUploadImage, // Galeri fonksiyonu
    child: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: const Color(0xFF1E1E1E), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.1))),
    child: Icon(Icons.edit, color: aestheticGreen, size: 16),
    ),
    ),
    ),
    ],
    ),

    const SizedBox(height: 20),

    // --- İSİM ALANI ---
    Text(
    _nameController.text.isNotEmpty ? _nameController.text : "Yükleniyor...",
    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
    ),
    const SizedBox(height: 4),
    Text(_emailController.text, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),

    const SizedBox(height: 30),

    // İstatistikler
    Container(
    padding: const EdgeInsets.symmetric(vertical: 24),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.05))),
    child: Row(
    children: [
    Expanded(
    child: Column(
    children: [
    Text("$_ordersCount", style: TextStyle(color: aestheticGreen, fontSize: 32, fontWeight: FontWeight.bold, shadows: [Shadow(color: aestheticGreen.withOpacity(0.4), blurRadius: 15)])),
    const SizedBox(height: 4),
    Text("YEMEK KURTARDIN", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
    ],
    ),
    ),
    Container(width: 1, height: 50, color: Colors.white.withOpacity(0.1)),
    Expanded(
    child: Column(
    children: [
    Text("${_savedAmount.toStringAsFixed(0)}₺", style: TextStyle(color: aestheticGreen, fontSize: 32, fontWeight: FontWeight.bold, shadows: [Shadow(color: aestheticGreen.withOpacity(0.4), blurRadius: 15)])),
    const SizedBox(height: 4),
    Text("TASARRUF ETTİN", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
    ],
    ),
    ),
    ],
    ),
    ),
    const SizedBox(height: 24),

    // Uyarı Kartı
    if (_warningCount > 0)
    Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 24),
    decoration: BoxDecoration(
    color: Colors.red.withOpacity(0.1),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.red.withOpacity(0.3))
    ),
    child: Row(
    children: [
    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 30),
    const SizedBox(width: 16),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text("Dikkat! ($_warningCount/3 Uyarı)", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
    const SizedBox(height: 4),
    const Text("Siparişlerinizi teslim almadığınız tespit edildi. 3. uyarıda hesabınız kapanacaktır.", style: TextStyle(color: Colors.white70, fontSize: 12)),
    ],
    ),
    )
    ],
    ),
    ),

    // Menü Butonları
    _buildMenuButton(
    icon: Icons.favorite,
    title: "Favorilerim",
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
    ),
    const SizedBox(height: 12),
    _buildMenuButton(
    icon: Icons.support_agent,
    title: "Yardım & Destek",
    onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
    },
    ),

    const SizedBox(height: 30),

    // Güncelleme Formu
    Align(alignment: Alignment.centerLeft, child: Text("BİLGİLERİNİ GÜNCELLE", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2))),
    const SizedBox(height: 16),
    _buildGlassTextField(icon: Icons.person_outline, controller: _nameController, hint: "Ad Soyad"),
    const SizedBox(height: 12),
    _buildGlassTextField(icon: Icons.phone_outlined, controller: _phoneController, hint: "Telefon Numarası", isNumber: true),
    const SizedBox(height: 24),

    SizedBox(
    width: double.infinity, height: 56,
    child: ElevatedButton(
    onPressed: _isLoading ? null : _updateProfile,
    style: ElevatedButton.styleFrom(backgroundColor: aestheticGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), shadowColor: aestheticGreen.withOpacity(0.4), elevation: 10),
    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Değişiklikleri Kaydet", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    ),
    ),
    const SizedBox(height: 40),
    ],
    ),
    ),
    ),
    ],
    ),
        ),
    );
  }

  Widget _buildMenuButton({required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle), child: Icon(icon, color: aestheticGreen, size: 20)), const SizedBox(width: 16), Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15))), Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.3), size: 16)]),
      ),
    );
  }

  Widget _buildGlassTextField({required IconData icon, required TextEditingController controller, required String hint, bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: TextField(controller: controller, keyboardType: isNumber ? TextInputType.phone : TextInputType.text, style: const TextStyle(color: Colors.white), decoration: InputDecoration(prefixIcon: Icon(icon, color: Colors.grey), hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16))),
    );
  }
}