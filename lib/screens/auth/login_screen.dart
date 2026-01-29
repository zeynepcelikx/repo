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

  // YENİ ÖZELLİK 1: Şifre Görünürlüğü Kontrolü
  bool _isPasswordVisible = false;

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
          // 1. ARKA PLAN RESMİ
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

                  // --- ŞİFRE ALANI (Göz İkonlu) ---
                  _buildGlassTextField(
                    controller: _passwordController,
                    hint: "Şifre",
                    icon: Icons.lock_outline,
                    isPassword: !_isPasswordVisible, // Ters mantık: Visible ise password değil
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),

                  // --- YENİ ÖZELLİK 2: ŞİFREMİ UNUTTUM ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Yeni sayfaya yönlendir
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                      },
                      child: Text(
                        "Şifremi Unuttum?",
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

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

  // Helper Widget (Göz İkonu desteği eklendi)
  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    Widget? suffixIcon, // Yeni parametre
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
          suffixIcon: suffixIcon, // Sağ tarafa ikon ekleme
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}

// --- YENİ SAYFA: ŞİFREMİ UNUTTUM EKRANI ---
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final Color aestheticGreen = const Color(0xFF4CAF50);
  bool _isLoading = false;

  void _resetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen e-posta adresinizi girin."), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      if (!mounted) return;

      // Başarılı
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("E-Posta Gönderildi 📧", style: TextStyle(color: Colors.white)),
          content: const Text("Şifre sıfırlama bağlantısı e-posta adresinize gönderildi. Lütfen gelen kutunuzu (ve spam klasörünü) kontrol edin.", style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Dialogu kapat
                  Navigator.pop(context); // Login ekranına dön
                },
                child: Text("Tamam", style: TextStyle(color: aestheticGreen))
            )
          ],
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: ${e.toString()}"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Aynı Arka Plan
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.5), Colors.black],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const SizedBox(height: 30),
                  const Text("Şifreni mi Unuttun?", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("Sorun değil! Hesabına kayıtlı e-posta adresini gir, sana sıfırlama bağlantısı gönderelim.", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),

                  const SizedBox(height: 40),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                        hintText: "E-Posta Adresiniz",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: aestheticGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 10,
                        shadowColor: aestheticGreen.withOpacity(0.4),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Sıfırlama Bağlantısı Gönder", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
}