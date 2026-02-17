import 'dart:io'; // Dosya işlemleri için gerekli
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Depolama için
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Galeri için

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  // Tasarım Renkleri
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);

  // Controller'lar
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedCategory = 'Ana Yemek';
  final List<String> _categories = ['Ana Yemek', 'Fast Food', 'Tatlı', 'Unlu Mamül', 'İçecek', 'Market', 'Diğer'];

  bool _isLoading = false;
  File? _selectedImage; // Seçilen fotoğrafı tutacak değişken

  // --- 1. FOTOĞRAF SEÇME FONKSİYONU (GÜNCELLENDİ: RAM KORUMASI) ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // iPhone 16 gibi yüksek çözünürlüklü cihazlarda uygulamanın çökmemesi için
    // fotoğrafı optimize ediyoruz (resize + compress).
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,  // Genişlik sınırı
      maxHeight: 800, // Yükseklik sınırı
      imageQuality: 80, // %80 kalite (Boyut tasarrufu)
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // --- 2. FOTOĞRAFI STORAGE'A YÜKLEME (GÜNCELLENDİ: MANUEL BUCKET ADRESİ) ---
  Future<String> _uploadImage(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString(); // Benzersiz isim

    // HATA ÇÖZÜMÜ: FirebaseStorage.instance yerine instanceFor(bucket: ...) kullanıldı.
    // Bu sayede "No default bucket found" hatası engellendi.
    Reference storageRef = FirebaseStorage.instanceFor(bucket: "gs://indirkazan-d1c8c.firebasestorage.app")
        .ref()
        .child('product_images/$fileName.jpg');

    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL(); // Yüklenen resmin linkini al
  }

  // --- 3. ÜRÜNÜ KAYDETME ---
  void _saveProduct() async {
    // 1. Metin Alanlarını Kontrol Et
    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _originalPriceController.text.trim().isEmpty ||
        _stockController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Lütfen tüm zorunlu alanları doldurun!"),
              backgroundColor: Colors.red
          )
      );
      return;
    }

    // 2. Fotoğraf Seçilmiş mi Kontrol Et
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Lütfen bir ürün fotoğrafı seçin!"),
              backgroundColor: Colors.red
          )
      );
      return;
    }

    setState(() => _isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Fotoğrafı Yükle
        String imageUrl = await _uploadImage(_selectedImage!);

        // Veritabanına Kaydet
        await FirebaseFirestore.instance.collection('products').add({
          'sellerId': user.uid,
          'name': _nameController.text.trim(),
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'originalPrice': double.tryParse(_originalPriceController.text) ?? 0.0,
          'stock': int.tryParse(_stockController.text) ?? 0,
          'category': _selectedCategory,
          'description': _descController.text.trim(),
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Ürün başarıyla yayınlandı! 🚀"), backgroundColor: aestheticGreen));
          Navigator.pop(context); // Sayfayı kapat
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        title: const Text("Yeni Ürün Ekle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Ürün Adı"),
            _buildTextField(controller: _nameController, hint: "Örn: Karışık Pide", icon: Icons.fastfood),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Satış Fiyatı (₺)"),
                      _buildTextField(controller: _priceController, hint: "30.00", icon: Icons.attach_money, isNumber: true),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Orijinal Fiyat (₺)"),
                      _buildTextField(controller: _originalPriceController, hint: "100.00", icon: Icons.money_off, isNumber: true),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Stok Adedi"),
                      _buildTextField(controller: _stockController, hint: "5", icon: Icons.inventory, isNumber: true),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Kategori"),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            dropdownColor: const Color(0xFF1E1E1E),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white),
                            items: _categories.map((String value) {
                              return DropdownMenuItem<String>(value: value, child: Text(value));
                            }).toList(),
                            onChanged: (newValue) => setState(() => _selectedCategory = newValue!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildLabel("Açıklama"),
            Container(
              height: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _descController,
                maxLines: null,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "İçindekiler, porsiyon bilgisi...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  border: InputBorder.none,
                  icon: const Icon(Icons.description, color: Colors.white54),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- FOTOĞRAF SEÇME ALANI ---
            _buildLabel("Ürün Görseli"),
            GestureDetector(
              onTap: _pickImage, // Tıklayınca galeri açılır
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _selectedImage == null ? aestheticGreen.withOpacity(0.3) : aestheticGreen,
                      style: BorderStyle.solid
                  ),
                  image: _selectedImage != null
                      ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                      : null,
                ),
                child: _selectedImage == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 40, color: aestheticGreen),
                    const SizedBox(height: 8),
                    Text("Fotoğraf Seçmek İçin Dokun", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  ],
                )
                    : Stack(
                  children: [
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: aestheticGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 10,
                  shadowColor: aestheticGreen.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("ÜRÜNÜ YAYINLA", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- HELPER METODLAR ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
          children: const [
            TextSpan(
              text: " *",
              style: TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white54, size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}