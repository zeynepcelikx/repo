import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/common/splash_screen.dart'; // Artık sadece Splash'i çağırmamız yeterli

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- FIREBASE BAŞLATMA ---
  // (Manuel yapılandırma sayesinde dosya yolu hatalarından etkilenmez)
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAIj0CCV0CuWIQxGke7wr18LEqo12HYsIg",
        appId: "1:883878657226:ios:e14aefe7d99ef60484c833",
        messagingSenderId: "883878657226",
        projectId: "indirkazan-d1c8c",
      ),
    );
    print("Firebase Başarıyla Bağlandı! 🚀");
  } catch (e) {
    print("Firebase Bağlantı Hatası: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İndirKazan', // Uygulama adı
      debugShowCheckedModeBanner: false, // Sağ üstteki "Debug" bandını kaldırır
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), // Ana renk yeşil
        useMaterial3: true,
        // Yazı tipleri veya genel stiller buraya eklenebilir
      ),
      // Uygulama açılınca direkt Akıllı Splash Ekranına gider
      home: const SplashScreen(),
    );
  }
}