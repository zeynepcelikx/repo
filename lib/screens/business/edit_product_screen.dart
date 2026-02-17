import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const EditProductScreen({super.key, required this.productId, required this.productData});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedCategory = 'Ana Yemek';
  final List<String> _categories = ['Ana Yemek', 'Fast Food', 'Tatlı', 'Unlu Mamül', 'İçecek', 'Market', 'Diğer'];

  bool _isLoading = false;
  File? _selectedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    // Mevcut verileri kutucuklara doldur
    _nameController.text = widget.productData['name'] ?? '';
    _priceController.text = widget.productData['price'].toString();
    _originalPriceController.text = widget.productData['originalPrice'].toString();
    _stockController.text = widget.productData['stock'].toString();
    _descController.text = widget.productData['description'] ?? '';
    _selectedCategory = widget.productData['category'] ?? 'Ana Yemek';
    _currentImageUrl = widget.productData['imageUrl'];

    // Kategori listede yoksa varsayılanı seç (Hata önlemek için)
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = _categories.first;
    }
  }

  // --- 1. FOTOĞRAF SEÇME FONKSİYONU (GÜNCELLENDİ: RAM KORUMASI EKLENDİ) ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Çökme yaşanmaması için boyutlandırma eklendi
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // --- 2. FOTOĞRAF YÜKLEME (GÜNCELLENDİ: MANUEL BUCKET ADRESİ EKLENDİ) ---
  Future<String> _uploadImage(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    // "No default bucket found" hatasını çözmek için instanceFor kullanıldı
    Reference storageRef = FirebaseStorage.instanceFor(bucket: "gs://indirkazan-d1c8c.firebasestorage.app")
        .ref()
        .child('product_images/$fileName.jpg');

    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Güncelleme İşlemi
  void _updateProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty || _stockController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen zorunlu alanları doldurun."), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = _currentImageUrl ?? "";

      // Eğer yeni resim seçildiyse yükle ve linki güncelle
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      await FirebaseFirestore.instance.collection('products').doc(widget.productId).update({
        'name': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'originalPrice': double.tryParse(_originalPriceController.text) ?? 0.0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'category': _selectedCategory,
        'description': _descController.text.trim(),
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(), // Güncellenme tarihi
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Ürün Güncellendi! ✅"), backgroundColor: aestheticGreen));
        Navigator.pop(context); // Sayfayı kapat
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        title: const Text("Ürün Düzenle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            // Görsel Alanı
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: aestheticGreen.withOpacity(0.5)),
                    image: _selectedImage != null
                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                        : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                        ? DecorationImage(image: NetworkImage(_currentImageUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: (_selectedImage == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                      ? Icon(Icons.add_a_photo, color: aestheticGreen, size: 40)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text("Fotoğrafı değiştirmek için tıklayın", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12))),

            const SizedBox(height: 24),

            _buildLabel("Ürün Adı"),
            _buildTextField(controller: _nameController, hint: "Ürün Adı", icon: Icons.fastfood),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Satış Fiyatı (₺)"),
                      _buildTextField(controller: _priceController, hint: "0.0", icon: Icons.attach_money, isNumber: true),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Stok"),
                      _buildTextField(controller: _stockController, hint: "0", icon: Icons.inventory, isNumber: true),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

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

            const SizedBox(height: 16),

            _buildLabel("Açıklama"),
            _buildTextField(controller: _descController, hint: "Ürün açıklaması...", icon: Icons.description, maxLines: 3),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: aestheticGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  shadowColor: aestheticGreen.withOpacity(0.4),
                  elevation: 10,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("GÜNCELLE", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isNumber = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
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