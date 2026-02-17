import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  bool _isTorchOn = false; // Flaş durumunu yerel olarak takip ediyoruz

  final Color aestheticGreen = const Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Teslimat QR Kodu Tara", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 🛠️ DÜZELTİLEN KISIM: Flaş Butonu
          IconButton(
            color: Colors.white,
            icon: Icon(
                _isTorchOn ? Icons.flash_on : Icons.flash_off,
                color: _isTorchOn ? Colors.yellow : Colors.grey
            ),
            onPressed: () async {
              await cameraController.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (_isProcessing) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processQRCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Tarama Çerçevesi
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                  border: Border.all(color: aestheticGreen, width: 3),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: aestheticGreen.withOpacity(0.3), blurRadius: 20)
                  ]
              ),
            ),
          ),

          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(30)
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 10),
                Text(
                  "QR Kodu karenin içine hizalayın",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _processQRCode(String orderId) async {
    setState(() => _isProcessing = true);

    try {
      DocumentSnapshot orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        _showError("Geçersiz QR Kod: Sipariş bulunamadı.");
        return;
      }

      var data = orderDoc.data() as Map<String, dynamic>;

      // Sipariş Zaten Tamamlanmış mı?
      if (data['status'] == 'completed') {
        _showError("Bu sipariş zaten teslim edilmiş.");
        return;
      }

      // Siparişi Tamamla
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'completed'
      });

      if (!mounted) return;

      // Başarılı Mesajı
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text("Teslimat Başarıyla Tamamlandı! ✅"),
              ],
            ),
            backgroundColor: aestheticGreen,
            behavior: SnackBarBehavior.floating,
          )
      );

      Navigator.pop(context); // Geri dön

    } catch (e) {
      _showError("Bir hata oluştu: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        )
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isProcessing = false);
    });
  }
}