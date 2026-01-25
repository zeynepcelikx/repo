import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../business/business_home.dart';
import '../customer/customer_main_layout.dart';
import 'onboarding_screen.dart';
import '../auth/login_screen.dart';

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

  void _checkUserAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _navigateBasedOnRole(user.uid);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  void _navigateBasedOnRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        // 1. BAN KONTROLÜ (GÜVENLİK SİSTEMİ 🚫)
        bool isBanned = userDoc.get('isBanned') ?? false;

        if (isBanned) {
          if (!mounted) return;
          // Oturumu kapat ve uyarı ver
          await FirebaseAuth.instance.signOut();

          showDialog(
            context: context,
            barrierDismissible: false, // Çarpıya basıp kapatamasın
            builder: (ctx) => AlertDialog(
              title: const Text("Hesabınız Askıya Alındı 🚫", style: TextStyle(color: Colors.red)),
              content: const Text("Siparişleri 3 kez teslim almadığınız için hesabınız güvenlik gerekçesiyle kapatılmıştır. Destek için iletişime geçin."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  child: const Text("Tamam"),
                )
              ],
            ),
          );
          return; // İşlemi durdur
        }

        // 2. NORMAL YÖNLENDİRME
        String role = userDoc['role'];
        if (!mounted) return;

        if (role == 'business') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BusinessHomeScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CustomerMainLayout()));
        }
      } else {
        _goToOnboarding();
      }
    } catch (e) {
      _goToOnboarding();
    }
  }

  void _goToOnboarding() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                  ]
              ),
              child: const Icon(Icons.restaurant_menu, size: 60, color: Colors.green),
            ),
            const SizedBox(height: 25),
            const Text(
              "İndirKazan",
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
            ),
            const SizedBox(height: 10),
            Text(
              "Yemeği Kurtar, Dünyayı Koru",
              style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9), fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 60),
            const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}