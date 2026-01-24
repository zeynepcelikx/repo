import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mevcut kullanıcıyı al
  User? get currentUser => _auth.currentUser;

  // Giriş Yapma Fonksiyonu
  Future<UserModel?> signIn(String email, String password) async {
    try {
      // 1. Firebase Auth ile giriş yap
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // 2. Firestore'dan kullanıcının rolünü ve bilgilerini çek
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, result.user!.uid);
      }
      return null;
    } catch (e) {
      print("Giriş Hatası: $e");
      rethrow; // Hatayı UI'a fırlat ki ekranda gösterelim
    }
  }

  // Kayıt Olma Fonksiyonu
  Future<UserModel?> signUp(String email, String password, String role) async {
    try {
      // 1. Auth'a kaydet
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // 2. Modeli oluştur
      UserModel newUser = UserModel(
        uid: result.user!.uid,
        email: email,
        role: role,
        balance: role == 'business' ? 50 : 0, // İşletmelere 50 kredi hediye
      );

      // 3. Firestore'a kaydet
      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(newUser.toMap());

      return newUser;
    } catch (e) {
      print("Kayıt Hatası: $e");
      rethrow;
    }
  }

  // Çıkış Yap
  Future<void> signOut() async {
    await _auth.signOut();
  }
}