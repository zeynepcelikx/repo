import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _isScanned = false; // Çift okumayı engellemek için kilit

  void _verifyOrder(String orderId) async {
    if (_isScanned) return; // Zaten okunduysa dur
    setState(() => _isScanned = true);

    try {
      // 1. Siparişi Bul
      DocumentSnapshot orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        _showError("Geçersiz QR Kod! Bu sipariş bulunamadı.");
        return;
      }

      String status = orderDoc['status'];

      // 2. Kontrol Et
      if (status == 'completed') {
        _showError("Bu sipariş zaten teslim edilmiş! ⚠️");
        return;
      }

      // 3. Teslim Et (Güncelle)
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'completed',
      });

      if (!mounted) return;

      // Başarılı Mesajı ve Kapanış
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Başarılı! 🎉"),
          content: const Text("Sipariş doğrulandı ve teslim edildi."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Dialog kapa
                Navigator.pop(context); // Tarayıcı ekranını kapa
              },
              child: const Text("TAMAM"),
            )
          ],
        ),
      );

    } catch (e) {
      _showError("Hata oluştu: $e");
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hata ❌"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isScanned = false); // Tekrar taramaya izin ver
            },
            child: const Text("Tekrar Dene"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Kodu Tara 📸")),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              _verifyOrder(barcode.rawValue!); // Okunan kodu gönder
              break;
            }
          }
        },
      ),
    );
  }
}