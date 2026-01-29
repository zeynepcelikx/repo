import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart'; // Eğer e-posta açtırmak isterseniz bu paketi ekleyin

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  // Tasarım Renkleri
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);

  // SSS Verileri
  final List<Map<String, dynamic>> _faqs = [
    {
      "question": "Siparişimi ne zaman teslim alabilirim?",
      "answer": "Sipariş verdiğiniz restoranın belirlediği teslimat saatleri içerisinde, size verilen QR kod ile gidip teslim alabilirsiniz. Genellikle siparişten 15-30 dakika sonra hazır olur.",
      "isExpanded": false,
    },
    {
      "question": "Teslim almaya gitmezsem ne olur? (ÖNEMLİ ⚠)",
      "answer": "Sürdürülebilirlik ilkemiz gereği, hazırlanan yemeklerin israf olmaması için teslim alınmayan siparişlerde iade yapılmamaktadır. Lütfen gelmeden önce kontrol edin.",
      "isExpanded": false,
    },
    {
      "question": "Siparişi iptal edebilir miyim?",
      "answer": "Siparişiniz 'Hazırlanıyor' aşamasına geçmediği sürece, siparişlerim sayfasından iptal edebilirsiniz. Hazırlanan siparişler iptal edilemez.",
      "isExpanded": false,
    },
    {
      "question": "Ödemeyi nasıl yapıyorum?",
      "answer": "Ödemeleriniz uygulama üzerinden Kredi/Banka kartı ile güvenli bir şekilde alınır. Kapıda ödeme seçeneğimiz şu an için bulunmamaktadır.",
      "isExpanded": false,
    },
    {
      "question": "Yemekler taze mi?",
      "answer": "Kesinlikle! LezzetKurtar'daki tüm ürünler o gün üretilen, tazeliğini koruyan ancak gün sonunda satılmadığı için israf riski taşıyan kaliteli yemeklerdir.",
      "isExpanded": false,
    },
  ];

  // --- LOGIC: E-POSTA GÖNDER ---
  void _sendEmail() async {
    // E-posta gönderme mantığı (url_launcher paketi gerektirir)
    // final Uri emailLaunchUri = Uri(
    //   scheme: 'mailto',
    //   path: 'destek@lezzetkurtar.com',
    //   query: 'subject=LezzetKurtar Destek Talebi',
    // );
    // if (await canLaunchUrl(emailLaunchUri)) {
    //   await launchUrl(emailLaunchUri);
    // }

    // Şimdilik sadece görsel feedback verelim
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("E-posta uygulaması açılıyor..."),
        backgroundColor: aestheticGreen,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Yardım ve Destek 🛟",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Dengelemek için boşluk
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 2. İÇERİK ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // --- BİZE ULAŞIN ---
                    Text(
                      "BİZE ULAŞIN",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: _sendEmail,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          // Hafif yeşil gradient efektli koyu kart
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.05),
                              Colors.white.withOpacity(0.02),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: aestheticGreen.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: aestheticGreen.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            // İkon Kutusu
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: aestheticGreen.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: aestheticGreen.withOpacity(0.2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: aestheticGreen.withOpacity(0.2),
                                    blurRadius: 10,
                                  )
                                ],
                              ),
                              child: Icon(Icons.mail, color: aestheticGreen, size: 24),
                            ),
                            const SizedBox(width: 16),
                            // Yazılar
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "E-Posta Desteği",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "destek@lezzetkurtar.com",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.3), size: 16),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- SIKÇA SORULAN SORULAR ---
                    Text(
                      "SIKÇA SORULAN SORULAR",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SSS Listesi
                    ..._faqs.map((faq) => _buildFaqCard(faq)),

                    const SizedBox(height: 30),

                    // --- VERSİYON BİLGİSİ ---
                    Center(
                      child: Text(
                        "v1.1.0 (Güvenlik Paketi)",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
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

  // --- WIDGET: SSS KARTI (ACCORDION) ---
  Widget _buildFaqCard(Map<String, dynamic> faq) {
    bool isExpanded = faq['isExpanded'];

    return GestureDetector(
      onTap: () {
        setState(() {
          // Tıklananı tersine çevir
          faq['isExpanded'] = !isExpanded;
          // Diğerlerini kapatmak istersen buraya döngü ekleyebilirsin
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded ? aestheticGreen.withOpacity(0.3) : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Yeşil Soru İkonu
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: aestheticGreen.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: aestheticGreen.withOpacity(0.2), blurRadius: 6)
                    ],
                  ),
                  child: Icon(Icons.question_mark, color: aestheticGreen, size: 16),
                ),
                const SizedBox(width: 12),

                // Soru Başlığı
                Expanded(
                  child: Text(
                    faq['question'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Ok İkonu
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.white.withOpacity(0.5),
                ),
              ],
            ),

            // Cevap (Animasyonlu Açılma)
            AnimatedCrossFade(
              firstChild: Container(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12, left: 40), // İkonun hizasından başlasın
                child: Text(
                  faq['answer'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}