import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../auth/login_screen.dart'; // Çıkış yapınca Login'e dönmek için gerekli

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  // Tasarım Renkleri
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);

  final _formKey = GlobalKey<FormState>();

  // Controllerlar
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _closingTimeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Konum Verisi
  GeoPoint? _selectedLocation;
  bool _isLoading = false;
  bool _isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBusinessData();
  }

  // --- LOGIC: VERİLERİ ÇEK ---
  Future<void> _fetchBusinessData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _nameController.text = data['businessName'] ?? '';
            _addressController.text = data['address'] ?? '';
            _closingTimeController.text = data['closingTime'] ?? '';
            _phoneController.text = data['phone'] ?? '';

            if (data['location'] != null) {
              _selectedLocation = data['location'] as GeoPoint;
            }
          });
        }
      }
    }
  }

  // --- LOGIC: KONUM AL ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isLocationLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konum izni verilmedi."), backgroundColor: Colors.red));
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _selectedLocation = GeoPoint(position.latitude, position.longitude);
      });

      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Konum başarıyla alındı! 📍"), backgroundColor: aestheticGreen));

    } catch (e) {
      debugPrint("Konum hatası: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konum alınamadı."), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLocationLoading = false);
    }
  }

  // --- LOGIC: KAYDET ---
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;

    try {
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'businessName': _nameController.text.trim(),
          'address': _addressController.text.trim(),
          'closingTime': _closingTimeController.text.trim(),
          'phone': _phoneController.text.trim(),
          'location': _selectedLocation,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text("Ayarlar güncellendi! ✅"), backgroundColor: aestheticGreen),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: ÇIKIŞ YAP ---
  Future<void> _signOut() async {
    // Emin misin diye soralım
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Çıkış Yap", style: TextStyle(color: Colors.white)),
        content: const Text("Hesabınızdan çıkış yapmak istediğinize emin misiniz?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Vazgeç", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Çıkış Yap", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Login ekranına yönlendir ve geri dönüşü engelle
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                const Row(
                  children: [
                    Text(
                      "Dükkan Ayarları ⚙️",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Müşteriler sizi bu bilgilerle bulacak.",
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                ),
                const SizedBox(height: 30),

                // --- INPUTLAR ---
                _buildLabel("Restoran / Dükkan Adı"),
                _buildGlassTextField(_nameController, "Örn: Lezzet Durağı", Icons.store),

                const SizedBox(height: 20),

                _buildLabel("Açık Adres"),
                _buildGlassTextField(_addressController, "Mahalle, Cadde, No...", Icons.map, maxLines: 3),

                const SizedBox(height: 20),

                // --- KONUM SEÇİCİ (GLASS CARD) ---
                _buildLabel("Dükkan Konumu"),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedLocation != null
                        ? aestheticGreen.withOpacity(0.1)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedLocation != null
                          ? aestheticGreen.withOpacity(0.5)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_selectedLocation != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: aestheticGreen, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Konum Seçildi: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}",
                              style: TextStyle(color: aestheticGreen, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          onPressed: _isLocationLoading ? null : _getCurrentLocation,
                          icon: _isLocationLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.my_location, color: Colors.white),
                          label: Text(_isLocationLoading ? "Konum Alınıyor..." : "Şu Anki Konumumu Al", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent.withOpacity(0.8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Dükkanda olduğunuzdan emin olun!", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _buildLabel("Kapanış Saati"),
                _buildGlassTextField(_closingTimeController, "Örn: 22:30", Icons.access_time),

                const SizedBox(height: 20),

                _buildLabel("İşletme Telefonu"),
                _buildGlassTextField(_phoneController, "0555...", Icons.phone, isNumber: true),

                const SizedBox(height: 40),

                // --- KAYDET BUTONU ---
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: aestheticGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      shadowColor: aestheticGreen.withOpacity(0.4),
                      elevation: 10,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                      "KAYDET VE GÜNCELLE",
                      style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- ÇIKIŞ YAP BUTONU (YENİ EKLENDİ) ---
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _signOut,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.5)), // Kırmızı çerçeve
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Colors.redAccent.withOpacity(0.05), // Hafif kırmızı zemin
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Text(
                          "HESAPTAN ÇIK",
                          style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40), // Alt boşluk
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER: LABEL ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- HELPER: GLASS TEXT FIELD ---
  Widget _buildGlassTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), // Glass efekt
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white), // Yazı rengi beyaz
        validator: (value) => value!.isEmpty ? "Bu alan zorunludur" : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: aestheticGreen.withOpacity(0.8), size: 20), // İkon Yeşil
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)), // Hint silik
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}