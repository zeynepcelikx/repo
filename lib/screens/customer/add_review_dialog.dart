import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddReviewDialog extends StatefulWidget {
  final String orderId;
  final String productId;
  final String sellerId;

  const AddReviewDialog({
    super.key,
    required this.orderId,
    required this.productId,
    required this.sellerId
  });

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  int _rating = 5; // Varsayılan 5 yıldız
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  void _submitReview() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Yorumu 'reviews' koleksiyonuna ekle
      await FirebaseFirestore.instance.collection('reviews').add({
        'orderId': widget.orderId,
        'productId': widget.productId,
        'sellerId': widget.sellerId,
        'customerId': user.uid,
        'customerEmail': user.email,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'date': FieldValue.serverTimestamp(),
      });

      // 2. Siparişi "Değerlendirildi" olarak işaretle (Tekrar yorum yapılmasın diye)
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'isReviewed': true,
      });

      if (!mounted) return;
      Navigator.pop(context); // Pencereyi kapat
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yorumunuz için teşekkürler! ⭐")),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Siparişi Değerlendir", textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Hizmet nasıldı?", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),

          // YILDIZLAR (1'den 5'e kadar)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.orange,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          // YORUM KUTUSU
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: "Düşüncelerini yaz...",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("İptal", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitReview,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("GÖNDER", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}