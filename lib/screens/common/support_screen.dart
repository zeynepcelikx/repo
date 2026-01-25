import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sıkça Sorulan Sorular Verisi
    final List<Map<String, String>> faqs = [
      {
        "question": "Siparişimi ne zaman teslim alabilirim?",
        "answer": "Sipariş verdikten hemen sonra dükkana giderek, kapanış saatine kadar siparişini teslim alabilirsin."
      },
      {
        "question": "Teslim almaya gitmezsem ne olur? (ÖNEMLİ ⚠️)",
        "answer": "Hazırlanan siparişi teslim almaya gitmezseniz dükkan 'Gelmedi' olarak işaretler. Bu durumda 1 uyarı puanı alırsınız. Toplam 3 uyarı puanına ulaşırsanız hesabınız süresiz olarak kapatılır."
      },
      {
        "question": "Siparişi iptal edebilir miyim?",
        "answer": "Sipariş 'Hazırlanıyor' aşamasındayken iptal edebilirsiniz. 'Paket Hazır' aşamasına geçtikten sonra iptal edilemez."
      },
      {
        "question": "Ödemeyi nasıl yapıyorum?",
        "answer": "Şu an için uygulama üzerinden 'Simüle Edilmiş Kredi Kartı' ile veya kapıda ödeme seçenekleriyle işlem yapabilirsin."
      },
      {
        "question": "Yemekler taze mi?",
        "answer": "Evet! Restoranlar gün sonunda kalan ancak hala taze ve tüketilebilir ürünleri listeler."
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Yardım ve Destek 🛟")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- İLETİŞİM KARTI ---
          const Text("Bize Ulaşın", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.mail, color: Colors.blue),
                ),
                const SizedBox(width: 15),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("E-Posta Desteği", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("destek@indirkazan.com", style: TextStyle(color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- SSS BÖLÜMÜ ---
          const Text("Sıkça Sorulan Sorular", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          ...faqs.map((faq) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: const Icon(Icons.help_outline, color: Colors.green),
              title: Text(faq["question"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Text(faq["answer"]!, style: const TextStyle(color: Colors.black87)),
                )
              ],
            ),
          )),

          const SizedBox(height: 20),
          const Center(child: Text("v1.1.0 (Güvenlik Paketi)", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}