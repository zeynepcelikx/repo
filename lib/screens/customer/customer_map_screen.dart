import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // <-- YENİ PAKET

class CustomerMapScreen extends StatefulWidget {
  const CustomerMapScreen({super.key});

  @override
  State<CustomerMapScreen> createState() => _CustomerMapScreenState();
}

class _CustomerMapScreenState extends State<CustomerMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // Arama Çubuğu Kontrolcüsü
  final TextEditingController _searchController = TextEditingController();

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(41.0082, 28.9784),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _fetchBusinessLocations();
    _locateUser();
  }

  // --- İSİMDEN KONUM BULMA VE GİTME (YENİ ÖZELLİK) ---
  void _searchAndNavigate() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    try {
      // 1. Yazılan ismi (Örn: "Kadıköy") koordinata çevir
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        Location target = locations.first;

        // 2. Kamerayı oraya uçur
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
              LatLng(target.latitude, target.longitude),
              14 // Biraz daha yakınlaş
          ),
        );

        // Klavye açıksa kapat
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      // Hata olursa kullanıcıya söyle
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Konum bulunamadı: $query")),
      );
    }
  }

  void _locateUser() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition();
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 14),
        );
      }
    } catch (e) {
      print("Kullanıcı konumu alınamadı: $e");
    }
  }

  // Veritabanından İşletmeleri Çek ve Pinle (DEBUG MODU)
  void _fetchBusinessLocations() async {
    print("📢 Veri çekme işlemi başladı..."); // 1. Başlangıç kontrolü

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'business') // Sadece işletmeleri getir
          .get();

      print("📢 Bulunan İşletme Sayısı: ${snapshot.docs.length}"); // 2. Kaç dükkan bulundu?

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String name = data['businessName'] ?? 'İsimsiz Dükkan';

        // Verileri konsola yazdıralım
        print("🔍 İncelenen Dükkan: $name");
        print("   -> Lat: ${data['latitude']}");
        print("   -> Lng: ${data['longitude']}");

        // Eğer işletme konum kaydettiyse
        if (data['latitude'] != null && data['longitude'] != null) {
          final double lat = (data['latitude'] as num).toDouble(); // Hata önleyici dönüşüm
          final double lng = (data['longitude'] as num).toDouble();

          final marker = Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: name,
              snippet: data['address'] ?? '',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          );

          setState(() {
            _markers.add(marker);
          });
          print("✅ PIN EKLENDİ: $name");
        } else {
          print("❌ BU DÜKKANIN KONUMU YOK: $name");
        }
      }
    } catch (e) {
      print("🚨 HATA OLUŞTU: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar'ı kaldırdık çünkü arama çubuğu daha şık duracak
      body: Stack(
        children: [
          // 1. EN ALTTA HARİTA
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Kendi butonumuzu yapacağız
            zoomControlsEnabled: false, // Google'ın butonlarını gizle, sade olsun
            onMapCreated: (controller) {
              _mapController = controller;
              _locateUser();
            },
          ),

          // 2. ÜSTTE ARAMA ÇUBUĞU (SafeArea içinde)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // ARAMA KUTUSU
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2)),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) => _searchAndNavigate(), // Klavye "Ara" tuşu
                      decoration: InputDecoration(
                        hintText: "İlçe veya bölge ara... (Örn: Beşiktaş)",
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: Colors.green),
                          onPressed: _searchAndNavigate,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. SAĞ ALTA KONUM BUTONU (Google'ınkini kapatıp kendimiz koyduk)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _locateUser,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}