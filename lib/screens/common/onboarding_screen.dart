import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  List<Map<String, String>> onBoardingData = [
    {
      "title": "Lezzetleri Kurtar 🍔",
      "text": "Restoranların gün sonu kalan taze yemeklerini %50'ye varan indirimlerle satın al.",
      "image": "https://cdn-icons-png.flaticon.com/512/2921/2921822.png" // Örnek ikon
    },
    {
      "title": "Cebini Koru 💰",
      "text": "Kaliteli yemekleri çok daha uygun fiyata yiyerek bütçene katkı sağla.",
      "image": "https://cdn-icons-png.flaticon.com/512/2845/2845668.png"
    },
    {
      "title": "Doğayı Sev 🌍",
      "text": "İsrafı önleyerek karbon ayak izini azalt ve gezegenimize iyilik yap.",
      "image": "https://cdn-icons-png.flaticon.com/512/3209/3209990.png"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (value) => setState(() => _currentPage = value),
                itemCount: onBoardingData.length,
                itemBuilder: (context, index) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(onBoardingData[index]["image"]!, height: 250),
                    const SizedBox(height: 20),
                    Text(
                      onBoardingData[index]["title"]!,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        onBoardingData[index]["text"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  // Sayfa Noktaları (Indicators)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onBoardingData.length,
                          (index) => Container(
                        margin: const EdgeInsets.only(right: 5),
                        height: 6,
                        width: _currentPage == index ? 20 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? Colors.green : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Buton
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () {
                          if (_currentPage == onBoardingData.length - 1) {
                            // Son sayfadaysa Giriş Ekranına git
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                          } else {
                            // Değilse sonraki sayfaya kaydır
                            _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                          }
                        },
                        child: Text(
                          _currentPage == onBoardingData.length - 1 ? "BAŞLA 🚀" : "İLERİ",
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}