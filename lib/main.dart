import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/common/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DOSYA OKUMAK YERİNE BİLGİLERİ ELDEN VERİYORUZ
  // Xcode dosyayı bulamasa bile bu yöntem %100 çalışır.
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAIj0CCV0CuWIQxGke7wr18LEqo12HYsIg", // Plist içindeki API_KEY
        appId: "1:883878657226:ios:e14aefe7d99ef60484c833", // Plist içindeki GOOGLE_APP_ID
        messagingSenderId: "883878657226", // Plist içindeki GCM_SENDER_ID
        projectId: "indirkazan-d1c8c", // Plist içindeki PROJECT_ID

        // iOS için zorunlu değil ama varsa iyi olur (Yoksa bu satırı silebilirsin)
        // storageBucket: "PROJE_ID.appspot.com",
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
      title: 'LezzetKurtar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}