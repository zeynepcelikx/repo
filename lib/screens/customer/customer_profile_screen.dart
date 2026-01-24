import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Profilim 👤")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // PROFİL FOTOĞRAFI VE MAİL
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(user?.email ?? "Kullanıcı",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            // İSTATİSTİK KARTI (GAMIFICATION)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('customerId', isEqualTo: user!.uid)
                  .where('status', isEqualTo: 'completed') // Sadece teslim alınanlar
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                double totalSaved = 0;
                int totalOrders = snapshot.data!.docs.length;

                // Tasarrufu Hesapla: (Normal Fiyat - Bizim Fiyatımız)
                // Not: Gerçek senaryoda veritabanında 'originalPrice'ı da siparişe kaydetmeliyiz.
                // Şimdilik basitçe her siparişten ortalama 50 TL tasarruf edilmiş varsayalım
                // veya sipariş modeline 'savedAmount' ekleyebiliriz.
                // MVP için: Her sipariş = 50 TL tasarruf (Simülasyon)
                totalSaved = totalOrders * 50.0;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text("$totalOrders",
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                          const Text("Yemek Kurtardın"),
                        ],
                      ),
                      Container(height: 40, width: 1, color: Colors.grey),
                      Column(
                        children: [
                          Text("${totalSaved.toStringAsFixed(0)}₺",
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                          const Text("Tasarruf Ettin"),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // MENÜ LİSTESİ
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Ayarlar"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text("Yardım & Destek"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Çıkış Yap", style: TextStyle(color: Colors.red)),
              onTap: () async {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}