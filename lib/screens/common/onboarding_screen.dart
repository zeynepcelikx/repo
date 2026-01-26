import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // --- TASARIM VERİLERİ ---
  final List<Map<String, dynamic>> _pages = [
    {
      "titleStart": "Lezzetleri",
      "titleHighlight": "Kurtar",
      "emoji": "🍔",
      "desc": "Restoranların gün sonu kalan taze yemeklerini %50'ye varan indirimlerle satın al.",
      "icon": Icons.fastfood_rounded,
    },
    {
      "titleStart": "Cebini",
      "titleHighlight": "Koru",
      "emoji": "💰",
      "desc": "Kaliteli yemekleri çok daha uygun fiyata yiyerek bütçene katkı sağla.",
      "icon": Icons.account_balance_wallet_rounded,
    },
    {
      "titleStart": "Doğayı",
      "titleHighlight": "Sev",
      "emoji": "🌍",
      "desc": "İsrafı önleyerek karbon ayak izini azalt ve gezegenimize iyilik yap.",
      "icon": Icons.eco_rounded,
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tasarım Renkleri
    const Color darkBg = Color(0xFF0D0E0C); // Dark Wood
    const Color aestheticGreen = Color(0xFF4CAF50); // Splash Screen'deki Estetik Yeşil 🌿

    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          // Arka Plan Deseni (Hafif Gradyan)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1C19), // Biraz daha açık ton
                  darkBg,
                ],
              ),
            ),
          ),

          // --- PAGE VIEW (KAYDIRILABİLİR ALAN) ---
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // --- GÖRSEL ALANI (GLOW) ---
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Arkadaki Bulanık Yeşil Işık
                        boxShadow: [
                          BoxShadow(
                            color: aestheticGreen.withOpacity(0.15),
                            blurRadius: 80,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Daire Arka Plan
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                          ),
                          // İkon
                          Icon(
                            page['icon'],
                            size: 120,
                            color: aestheticGreen,
                            shadows: [
                              BoxShadow(
                                color: aestheticGreen.withOpacity(0.6),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    // --- BAŞLIK ---
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "${page['titleStart']} ",
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          TextSpan(
                            text: "${page['titleHighlight']} ",
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: aestheticGreen, // YENİ RENK
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(color: aestheticGreen.withOpacity(0.4), blurRadius: 10)
                              ],
                            ),
                          ),
                          TextSpan(
                            text: page['emoji'],
                            style: const TextStyle(fontSize: 32),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- AÇIKLAMA ---
                    Text(
                      page['desc'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              );
            },
          ),

          // --- ALT KONTROL PANELİ ---
          Positioned(
            bottom: 50,
            left: 32,
            right: 32,
            child: Column(
              children: [
                // Sayfa İşaretçileri (Dots)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    bool isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      height: 6,
                      width: isActive ? 32 : 6,
                      decoration: BoxDecoration(
                        color: isActive ? aestheticGreen : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isActive
                            ? [BoxShadow(color: aestheticGreen.withOpacity(0.5), blurRadius: 8)]
                            : [],
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 40),

                // --- ANA BUTON ---
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: aestheticGreen, // YENİ RENK
                      foregroundColor: Colors.white, // Yazı rengi beyaz olsun ki kontrast artsın
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      shadowColor: aestheticGreen.withOpacity(0.4),
                    ).copyWith(
                      elevation: MaterialStateProperty.all(10),
                    ),
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage == _pages.length - 1 ? "BAŞLA 🚀" : "İLERİ",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- TANITIMI ATLA ---
                if (_currentPage != _pages.length - 1)
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(
                      "TANITIMI ATLA",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}