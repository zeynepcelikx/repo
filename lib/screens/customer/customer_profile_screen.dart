import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'favorites_screen.dart';
import '../common/support_screen.dart'; // Eğer yoksa oluşturulmalı veya yorum satırı yapılmalı

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  // Tasarım Renkleri
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);

  // Controllerlar
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;

  // İstatistikler
  int _ordersCount = 0;
  double _savedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _calculateStats();
  }

  // --- LOGIC: KULLANICI VERİLERİNİ ÇEK ---
  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = user.email ?? '';
        });
      }
    }
  }

  // --- LOGIC: İSTATİSTİKLERİ HESAPLA (GERÇEK VERİ) ---
  Future<void> _calculateStats() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'completed') // Sadece tamamlananlar
        .get();

    int count = ordersSnapshot.docs.length;
    double savings = 0.0;

    // Her siparişin orijinal fiyatını bulup tasarrufu hesaplayalım
    // Not: Siparişlerde 'originalPrice' tutulmuyorsa, bu kısım yaklaşık veya sadece 'indirim' alanı varsa oradan hesaplanabilir.
    // Şimdilik sipariş sayısını doğru alıyoruz, tasarruf için varsayılan bir mantık veya sipariş modeline göre güncelleme gerekebilir.
    // Basitlik adına: Her siparişte ortalama 50TL tasarruf varsayalım veya sipariş verisine 'saving' alanı eklenirse oradan çekilir.
    // Burayı şimdilik statik bir çarpanla simüle ediyorum, backend geliştikçe 'saving' alanını toplayabilirsin.
    savings = count * 45.50;

    if (mounted) {
      setState(() {
        _ordersCount = count;
        _savedAmount = savings;
      });
    }
  }

  // --- LOGIC: BİLGİLERİ GÜNCELLE ---
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

  // --- LOGIC: ÇIKIŞ YAP ---
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), // Ortalama için boşluk
                  const Text(
                    "Profilim",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    onPressed: _signOut,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
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

                    // --- PROFİL FOTOĞRAFI ---
                    Stack(
                      children: [
                        // Glow Efekti
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: aestheticGreen.withOpacity(0.3),
                                blurRadius: 40,
                                spreadRadius: 10,
                              )
                            ],
                          ),
                        ),
                        // Resim
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: aestheticGreen.withOpacity(0.5), width: 2),
                            image: const DecorationImage(
                              // Varsayılan profil resmi
                              image: NetworkImage("https://cdn-icons-png.flaticon.com/512/3135/3135715.png"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Düzenle İkonu
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Icon(Icons.edit, color: aestheticGreen, size: 16),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // İsim ve Mail
                    Text(
                      _nameController.text.isEmpty ? "Kullanıcı" : _nameController.text,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _emailController.text,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                    ),

                    const SizedBox(height: 30),

                    // --- İSTATİSTİK KARTI ---
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          // Yemek Kurtardın
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  "$_ordersCount",
                                  style: TextStyle(
                                      color: aestheticGreen,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      shadows: [Shadow(color: aestheticGreen.withOpacity(0.4), blurRadius: 15)]
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "YEMEK KURTARDIN",
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          // Çizgi
                          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.1)),
                          // Tasarruf Ettin
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  "${_savedAmount.toStringAsFixed(0)}₺",
                                  style: TextStyle(
                                      color: aestheticGreen,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      shadows: [Shadow(color: aestheticGreen.withOpacity(0.4), blurRadius: 15)]
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "TASARRUF ETTİN",
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- GÜVENİLİR HESAP ROZETİ ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        // border: Border.all(color: Colors.white.withOpacity(0.05)), // Tasarımda border yok gibi, temiz kalsın
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: aestheticGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: aestheticGreen.withOpacity(0.2)),
                            ),
                            child: Icon(Icons.verified_user, color: aestheticGreen, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Güvenilir Hesap", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(
                                  "Topluluğumuza katkılarınla onaylı üyesin. Harikasın!",
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- MENÜ BUTONLARI (Favoriler & Destek) ---
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

                    // --- GÜNCELLEME FORMU ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "BİLGİLERİNİ GÜNCELLE",
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildGlassTextField(icon: Icons.person_outline, controller: _nameController, hint: "Ad Soyad"),
                    const SizedBox(height: 12),
                    _buildGlassTextField(icon: Icons.phone_outlined, controller: _phoneController, hint: "Telefon Numarası", isNumber: true),

                    const SizedBox(height: 24),

                    // Kaydet Butonu
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: aestheticGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          shadowColor: aestheticGreen.withOpacity(0.4),
                          elevation: 10,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Değişiklikleri Kaydet", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  // --- YARDIMCI WIDGETLAR ---

  Widget _buildMenuButton({required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: aestheticGreen, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15))),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.3), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassTextField({required IconData icon, required TextEditingController controller, required String hint, bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}