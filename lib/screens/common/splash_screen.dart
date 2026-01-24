import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../business/business_home.dart';
import '../customer/customer_main_layout.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserAndNavigate();
  }

  // Kullanıcıyı Kontrol Et ve Yönlendir
  void _checkUserAndNavigate() async {
    // 2 Saniye logo görünsün diye bekleme (Animasyon hissi için)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Kullanıcı zaten giriş yapmış, rolünü öğrenip yönlendirelim
      _navigateBasedOnRole(user.uid);
    } else {
      // Giriş yapmamış, Login ekranına git
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _navigateBasedOnRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        String role = userDoc['role'];
        if (!mounted) return;

        if (role == 'business') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BusinessHomeScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CustomerMainLayout()));
        }
      } else {
        // Hata durumunda Login'e at
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } catch (e) {
      // İnternet yoksa veya hata varsa Login'e at
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Arka plan rengi
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO KISMI
            // Eğer elinde resim varsa: Image.asset('assets/logo.png') kullanabilirsin.
            // Şimdilik şık bir ikon kullanıyoruz:
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.recycling, // Geri dönüşüm / Kurtarma ikonu
                size: 80,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),

            // UYGULAMA ADI
            const Text(
              "Lezzet Kurtar",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "İsrafı Önle, Lezzeti Yakala!",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 50),
            // YÜKLENİYOR ÇARK
            const CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}