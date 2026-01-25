import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Kontrolcüler
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _discountedPriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  // KATEGORİ LİSTESİ VE SEÇİMİ 📂
  final List<String> _categories = [
    'Ana Yemek',
    'Fast Food',
    'Tatlı',
    'Unlu Mamül',
    'İçecek',
    'Market',
    'Diğer'
  ];
  String? _selectedCategory; // Seçilen kategori burada tutulacak

  bool _isLoading = false;

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Kategori seçilmediyse uyarı ver
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bir kategori seçin! ⚠️")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final businessName = userDoc.data()?['businessName'] ?? 'Restoran';

      double originalPrice = double.tryParse(_originalPriceController.text) ?? 0.0;
      double discountedPrice = double.tryParse(_discountedPriceController.text) ?? 0.0;
      int stock = int.tryParse(_stockController.text) ?? 0;

      String imageUrl = _imageUrlController.text.isNotEmpty
          ? _imageUrlController.text
          : 'https://cdn-icons-png.flaticon.com/512/2921/2921822.png';

      await FirebaseFirestore.instance.collection('products').add({
        'userId': user.uid,
        'businessId': user.uid,
        'businessName': businessName,
        'name': _nameController.text,
        'originalPrice': originalPrice,
        'discountedPrice': discountedPrice,
        'stock': stock,
        'category': _selectedCategory, // <-- YENİ: Kategori kaydediliyor
        'imageUrl': imageUrl,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ürün Başarıyla Eklendi! ✅")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Ürün Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Yemek Adı (Örn: Kıymalı Pide)", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Boş bırakılamaz" : null,
              ),
              const SizedBox(height: 15),

              // --- KATEGORİ SEÇİMİ (YENİ) ---
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: "Kategori Seçiniz",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              // ------------------------------

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _originalPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Normal Fiyat", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Giriniz" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _discountedPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Satış Fiyatı", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Giriniz" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Stok Adedi", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Giriniz" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                    labelText: "Resim Linki (Opsiyonel)",
                    border: OutlineInputBorder(),
                    helperText: "Boş bırakırsanız varsayılan ikon kullanılır."
                ),
              ),
              const SizedBox(height: 25),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text("YAYINLA 🚀"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}