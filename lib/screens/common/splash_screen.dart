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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Hafif nefes alma efekti
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _checkUserAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- LOGIC KISMI ---
  void _checkUserAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));

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
        bool isBanned = userDoc.get('isBanned') ?? false;

        if (isBanned) {
          if (!mounted) return;
          await FirebaseAuth.instance.signOut();

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text("Hesabınız Askıya Alındı 🚫", style: TextStyle(color: Colors.red)),
              content: const Text("Siparişleri 3 kez teslim almadığınız için hesabınız güvenlik gerekçesiyle kapatılmıştır."),
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
          return;
        }

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

  // --- UI KISMI (Düzeltilmiş Hizalama) 🎨 ---
  @override
  Widget build(BuildContext context) {
    const Color aestheticGreen = Color(0xFF4CAF50);
    const Color darkBg = Color(0xFF121212);
    const Color cardBg = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: darkBg,
      body: SizedBox( // Tüm ekranı kapla
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 3),

            // --- KİLİTLİ YAPI: LOGO VE IŞIK BİRLİKTE ---
            // Stack kullanarak ışığı ve logoyu aynı merkeze kilitledik.
            Stack(
              alignment: Alignment.center,
              children: [
                // 1. KATMAN: Arka Plandaki Işık (Glow)
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: aestheticGreen.withOpacity(0.08),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: aestheticGreen.withOpacity(0.05),
                        blurRadius: 100,
                        spreadRadius: 50,
                      )
                    ],
                  ),
                ),

                // 2. KATMAN: Logo Kutusu (Önde)
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(45),
                        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: aestheticGreen.withOpacity(0.2),
                            blurRadius: _glowAnimation.value + 15,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.restaurant, size: 65, color: Colors.white),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: aestheticGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.eco, color: Colors.white, size: 20),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 50),

            // --- BAŞLIK ---
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: "Lezzet",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                    ),
                  ),
                  TextSpan(
                    text: "Kurtar",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: aestheticGreen,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // --- SLOGAN ---
            Text(
              "YEMEĞİ KURTAR, DÜNYAYI KORU",
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
                letterSpacing: 4.0,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),

            const Spacer(flex: 3),

            // --- YÜKLENİYOR ---
            SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  backgroundColor: Color(0xFF2C2C2C),
                  color: aestheticGreen,
                  minHeight: 4,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "YÜKLENİYOR",
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
                letterSpacing: 3.0,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}