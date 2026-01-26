import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../business/business_home.dart';
import '../customer/customer_main_layout.dart';
import 'register_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Tasarım Rengi (Estetik Yeşil)
  final Color aestheticGreen = const Color(0xFF4CAF50);

  // --- LOGIC: GİRİŞ YAPMA İŞLEVİ ---
  void _login() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        // 🛠️ HATA DÜZELTİLDİ: GÜVENLİ VERİ OKUMA
        // 'isBanned' alanı yoksa uygulama çökmesin, varsayılan olarak 'false' kabul etsin.
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        bool isBanned = userData != null && userData.containsKey('isBanned')
            ? userData['isBanned']
            : false;

        // Ban Kontrolü
        if (isBanned) {
          await FirebaseAuth.instance.signOut();
          _showError("Hesabınız askıya alınmıştır.");
          setState(() => _isLoading = false);
          return;
        }

        String role = userDoc['role'];
        if (!mounted) return;

        if (role == 'business') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BusinessHomeScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CustomerMainLayout()));
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = "Bir hata oluştu.";
      if (e.code == 'user-not-found') message = "Kullanıcı bulunamadı.";
      else if (e.code == 'wrong-password') message = "Şifre yanlış.";
      else if (e.code == 'invalid-credential') message = "E-posta veya şifre hatalı.";
      _showError(message);
    } catch (e) {
      // Diğer hatalar (Firestore hatası vb.)
      _showError("Hata: ${e.toString()}");
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
          // 1. ARKA PLAN RESMİ (YEREL DOSYA) 🍔
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 2. KARARTMA KATMANI
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          // 3. İÇERİK
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- LOGO KUTUSU ---
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: aestheticGreen.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.restaurant, size: 50, color: Colors.white),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Icon(Icons.eco, color: aestheticGreen, size: 18),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- BAŞLIK ---
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: "Lezzet",
                          style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: "Kurtar",
                          style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold, color: aestheticGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "İsraf etme, lezzeti keşfet!",
                    style: TextStyle(color: Colors.white.withOpacity(0.6), letterSpacing: 1.2),
                  ),

                  const SizedBox(height: 50),

                  // --- FORM ALANLARI ---
                  _buildGlassTextField(
                    controller: _emailController,
                    hint: "E-Posta",
                    icon: Icons.mail_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildGlassTextField(
                    controller: _passwordController,
                    hint: "Şifre",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),

                  const SizedBox(height: 30),

                  // --- GİRİŞ BUTONU ---
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: aestheticGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 10,
                        shadowColor: aestheticGreen.withOpacity(0.4),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Giriş Yap", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- KAYIT OL LİNKİ ---
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Hesabın yok mu? ",
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        children: [
                          TextSpan(
                            text: "Kayıt Ol",
                            style: TextStyle(color: aestheticGreen, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white70),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}