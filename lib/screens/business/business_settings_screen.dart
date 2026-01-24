import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Alanları
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _closingTimeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Konum Bilgisi
  double? _latitude;
  double? _longitude;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        _nameController.text = data['businessName'] ?? '';
        _addressController.text = data['address'] ?? '';
        _closingTimeController.text = data['closingTime'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';

        // Kayıtlı konum varsa çek
        if (data['latitude'] != null) {
          _latitude = data['latitude'];
          _longitude = data['longitude'];
        }
      }
    }
    setState(() => _isLoading = false);
  }

  // GPS Konumunu Al
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      // 1. İzin Kontrolü
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Konum izni verilmedi.");
        }
      }

      // 2. Konumu Al
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Değişkenlere Ata
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konum Başarıyla Alındı! Kaydetmeyi unutmayın."), backgroundColor: Colors.green),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Konum Hatası: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'businessName': _nameController.text,
        'address': _addressController.text,
        'closingTime': _closingTimeController.text,
        'phoneNumber': _phoneController.text,
        // Konum verilerini de kaydet
        'latitude': _latitude,
        'longitude': _longitude,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bilgiler Güncellendi! ✅"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dükkan Ayarları ⚙️")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("Müşteriler sizi bu bilgilerle bulacak.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Restoran / Dükkan Adı", prefixIcon: Icon(Icons.store), border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Dükkan adı giriniz" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Açık Adres", prefixIcon: Icon(Icons.map), border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Adres giriniz" : null,
              ),
              const SizedBox(height: 15),

              // --- YENİ: KONUM ALMA BUTONU ---
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _latitude != null
                                ? "Konum Seçildi: $_latitude, $_longitude"
                                : "Henüz GPS konumu seçilmedi.",
                            style: TextStyle(fontWeight: FontWeight.bold, color: _latitude != null ? Colors.green : Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text("Şu Anki Konumumu Al"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    const Text("Dükkanda olduğunuzdan emin olun!", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              // -------------------------------

              const SizedBox(height: 15),

              TextFormField(
                controller: _closingTimeController,
                decoration: const InputDecoration(labelText: "Bugün Kaçta Kapanıyor?", prefixIcon: Icon(Icons.access_time), border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Saat giriniz" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "İşletme Telefonu", prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                child: const Text("KAYDET VE GÜNCELLE"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}