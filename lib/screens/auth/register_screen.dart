import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../business/business_home.dart';
import '../customer/customer_main_layout.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // --- STATE YÖNETİMİ ---
  int _currentStep = 0; // 0: Rol Seçimi, 1: Form
  String _selectedRole = 'customer'; // Varsayılan: Müşteri

  // --- FORM CONTROLLERLARI ---
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // Tasarım Rengi (Estetik Yeşil)
  final Color aestheticGreen = const Color(0xFF4CAF50);

  // --- LOGIC: KAYIT OLMA İŞLEVİ (Backend Logic Korundu) ---
  void _register() async {
    // Validasyonlar
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showError("Lütfen tüm alanları doldurun.");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("Şifreler eşleşmiyor!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Auth Oluşturma
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Firestore'a Yazma (Rol ile birlikte)
      String uid = userCredential.user!.uid;

      Map<String, dynamic> userData = {
        'uid': uid,
        'email': _emailController.text.trim(),
        'role': _selectedRole, // Seçilen rol
        'createdAt': FieldValue.serverTimestamp(),
        'isBanned': false,
        'warningCount': 0,
        'phone': _phoneController.text.trim(),
      };

      if (_selectedRole == 'business') {
        userData['businessName'] = _nameController.text.trim();
        userData['address'] = '';
      } else {
        userData['name'] = _nameController.text.trim();
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);

      if (!mounted) return;

      // 3. Yönlendirme
      if (_selectedRole == 'business') {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const BusinessHomeScreen()), (route) => false);
      } else {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const CustomerMainLayout()), (route) => false);
      }

    } on FirebaseAuthException catch (e) {
      String message = "Kayıt başarısız.";
      if (e.code == 'email-already-in-use') message = "Bu e-posta zaten kullanılıyor.";
      else if (e.code == 'weak-password') message = "Şifre çok zayıf.";
      _showError(message);
    } catch (e) {
      _showError("Bir hata oluştu: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. ARKA PLAN RESMİ (HAMBURGER) 🍔
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=1899&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),

          // 2. KARARTMA
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.9),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          // 3. İÇERİK (ADIM KONTROLÜ)
          SafeArea(
            child: Column(
              children: [
                // Üst Bar (Geri Butonu ve Başlık)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () {
                          if (_currentStep == 1) {
                            setState(() => _currentStep = 0);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const Spacer(),
                      // Logo Küçük
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.restaurant, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _currentStep == 0 ? _buildRoleSelectionStep() : _buildFormStep(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ADIM 1: ROL SEÇİMİ TASARIMI ---
  Widget _buildRoleSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Text("Kayıt Ol", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text("Devam etmek için profilinizi seçin.", style: TextStyle(color: Colors.white70)),

        const SizedBox(height: 40),

        // Müşteri Kartı
        _buildRoleCard(
          role: 'customer',
          title: "Müşteri",
          desc: "İndirimli yemekleri kurtarın",
          icon: Icons.person_outline,
        ),

        const SizedBox(height: 20),

        // İşletme Kartı
        _buildRoleCard(
          role: 'business',
          title: "İşletme",
          desc: "Fazla yemekleri satışa sunun",
          icon: Icons.store_outlined,
        ),

        const SizedBox(height: 50),

        // İleri Butonu
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _currentStep = 1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: aestheticGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              shadowColor: aestheticGreen.withOpacity(0.5),
              elevation: 10,
            ),
            child: const Text("Devam Et", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({required String role, required String title, required String desc, required IconData icon}) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? aestheticGreen.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? aestheticGreen : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? aestheticGreen : Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: aestheticGreen, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  // --- ADIM 2: FORM TASARIMI ---
  Widget _buildFormStep() {
    return Column(
      children: [
        const SizedBox(height: 20),

        // Başlık
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(text: "Lezzet", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              TextSpan(text: "Kurtar", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: aestheticGreen)),
            ],
          ),
        ),
        Text(
          _selectedRole == 'customer' ? "MÜŞTERİ KAYIT FORMU" : "İŞLETME KAYIT FORMU",
          style: TextStyle(color: Colors.white.withOpacity(0.5), letterSpacing: 2, fontSize: 12),
        ),

        const SizedBox(height: 40),

        // Formlar
        _buildGlassTextField(_nameController, _selectedRole == 'business' ? "İşletme Adı" : "Ad Soyad", Icons.person_outline),
        const SizedBox(height: 16),
        _buildGlassTextField(_phoneController, "Telefon Numarası", Icons.phone_outlined, inputType: TextInputType.phone),
        const SizedBox(height: 16),
        _buildGlassTextField(_emailController, "E-Posta", Icons.mail_outline, inputType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildGlassTextField(_passwordController, "Şifre", Icons.lock_outline, isPassword: true),
        const SizedBox(height: 16),
        _buildGlassTextField(_confirmPasswordController, "Şifre Tekrar", Icons.lock_outline, isPassword: true),

        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: aestheticGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              shadowColor: aestheticGreen.withOpacity(0.5),
              elevation: 10,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("HESABIMI OLUŞTUR", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),

        const SizedBox(height: 20),
        Text("Kayıt olarak Kullanım Koşulları'nı kabul etmiş sayılırsınız.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildGlassTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false, TextInputType inputType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: inputType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: aestheticGreen),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}