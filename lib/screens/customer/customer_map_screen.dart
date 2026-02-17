import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'shop_products_screen.dart'; // Ürünlerin olduğu sayfa

class CustomerMapScreen extends StatefulWidget {
  const CustomerMapScreen({super.key});

  @override
  State<CustomerMapScreen> createState() => _CustomerMapScreenState();
}

class _CustomerMapScreenState extends State<CustomerMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  // Tasarım Renkleri
  final Color darkBg = const Color(0xFF1E1E1E);
  final Color aestheticGreen = const Color(0xFF4CAF50);

  // Harita Ayarları
  MapType _currentMapType = MapType.normal;
  bool _trafficEnabled = false;

  Set<Marker> _markers = {};
  StreamSubscription? _businessSubscription;

  // ARAMA İÇİN EKLENEN LİSTE (Veritabanından gelen dükkanları tutar)
  List<Map<String, dynamic>> _businessList = [];

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(41.0082, 28.9784),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _startListeningToBusinesses();
  }

  @override
  void dispose() {
    _businessSubscription?.cancel();
    super.dispose();
  }

  void _startListeningToBusinesses() {
    _businessSubscription = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'business') // veya 'seller' veritabanına göre
        .snapshots()
        .listen((snapshot) {

      Set<Marker> newMarkers = {};
      List<Map<String, dynamic>> tempList = []; // Arama listesi için geçici liste

      for (var doc in snapshot.docs) {
        var data = doc.data();
        data['id'] = doc.id; // Dükkan ID'sini arama ve yönlendirme için kaydediyoruz
        tempList.add(data); // Dükkanı arama listesine ekliyoruz

        if (data.containsKey('location') && data['location'] != null) {
          try {
            GeoPoint pos = data['location'] as GeoPoint;

            newMarkers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(pos.latitude, pos.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                onTap: () {
                  // doc.id (sellerId) bilgisini fonksiyona gönderiyoruz
                  _showCustomShopDetail(data, doc.id);
                },
              ),
            );
          } catch (e) {
            debugPrint("Marker hatası: $e");
          }
        }
      }

      if (mounted) {
        setState(() {
          _markers = newMarkers;
          _businessList = tempList; // Listeyi güncelliyoruz
        });
      }
    });
  }

  // --- ARAMA FONKSİYONU ---
  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    String lowerQuery = query.toLowerCase().trim();
    Map<String, dynamic>? matchedBusiness;

    // 1. Önce dükkan isminde (businessName) arama yap
    for (var b in _businessList) {
      String name = (b['businessName'] ?? '').toLowerCase();
      if (name.contains(lowerQuery)) {
        matchedBusiness = b;
        break;
      }
    }

    // 2. Eğer isminde bulamadıysa, adresinde (il, ilçe) arama yap
    if (matchedBusiness == null) {
      for (var b in _businessList) {
        String address = (b['address'] ?? '').toLowerCase();
        if (address.contains(lowerQuery)) {
          matchedBusiness = b;
          break;
        }
      }
    }

    // Eşleşen dükkan bulunduysa kamerayı oraya kaydır
    if (matchedBusiness != null && matchedBusiness['location'] != null) {
      GeoPoint pos = matchedBusiness['location'] as GeoPoint;
      final GoogleMapController controller = await _controller.future;

      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(pos.latitude, pos.longitude),
          zoom: 16, // Yakından göster
        ),
      ));

      // Opsiyonel ama şık: Bulunan dükkanın detay penceresini otomatik açar
      _showCustomShopDetail(matchedBusiness, matchedBusiness['id']);

    } else {
      // Bulunamadıysa kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Bu aramayla eşleşen dükkan veya bölge bulunamadı."),
            backgroundColor: Colors.redAccent.withOpacity(0.8),
          ),
        );
      }
    }
  }

  // --- CANLI PUAN GÖSTERİMİ VE DETAY ---
  void _showCustomShopDetail(Map<String, dynamic> initialData, String sellerId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (ctx) {
        // StreamBuilder ile anlık veriyi dinliyoruz
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(sellerId).snapshots(),
          builder: (context, snapshot) {
            // Veri gelene kadar veya hata varsa başlangıç verilerini kullan
            var data = snapshot.hasData && snapshot.data!.exists
                ? snapshot.data!.data() as Map<String, dynamic>
                : initialData;

            // --- PUAN HESAPLAMA MANTIĞI ---
            double totalScore = double.tryParse(data['totalScore'].toString()) ?? 0.0;
            int reviewCount = int.tryParse(data['reviewCount'].toString()) ?? 0;
            double averageRating = reviewCount > 0 ? (totalScore / reviewCount) : 0.0;

            // Puan Metni (Örn: "4.5 (12 Değerlendirme)" veya "Yeni")
            String ratingText = reviewCount > 0
                ? "${averageRating.toStringAsFixed(1)} ($reviewCount Değerlendirme)"
                : "Yeni";

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0C0C).withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(top: BorderSide(color: aestheticGreen.withOpacity(0.5), width: 2)),
                boxShadow: [
                  BoxShadow(
                    color: aestheticGreen.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: aestheticGreen.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: aestheticGreen.withOpacity(0.5)),
                        ),
                        child: Icon(Icons.store, color: aestheticGreen, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['businessName'] ?? 'Restoran Adı Yok',
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            // --- PUAN GÖSTERİMİ ---
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  ratingText,
                                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Colors.white54, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data['address'] ?? 'Adres belirtilmemiş.',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.4),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white54, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        "Kapanış: ${data['closingTime'] ?? '--:--'}",
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- YÖNLENDİRME BUTONU ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Önce kartı kapat

                        // Yeni sayfaya git ve SellerID'yi taşı
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShopProductsScreen(
                              sellerId: sellerId,
                              shopName: data['businessName'] ?? 'Dükkan',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: aestheticGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 10,
                        shadowColor: aestheticGreen.withOpacity(0.4),
                      ),
                      icon: const Icon(Icons.arrow_forward, color: Colors.black),
                      label: const Text(
                        "ÜRÜNLERİ GÖR",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- GÜNCELLENEN: KULLANICI KONUMUNA GİTME FONKSİYONU ---
  Future<void> _goToMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen cihazınızın konum servisini açın.")));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konum izni reddedildi.")));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konum izni kalıcı olarak reddedildi. Ayarlardan açmalısınız.")));
      return;
    }

    // Yüksek doğrulukla (LocationAccuracy.high) kullanıcının mevcut konumunu alıyoruz
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final GoogleMapController controller = await _controller.future;

    // Kamerayı kullanıcının konumuna yönlendir ve etrafı görebilmesi için zoom seviyesini 16 yap
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 16.0,
      ),
    ));
  }
  // --------------------------------------------------------

  void _openMapSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: darkBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Harita Ayarları 🌍", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  const Text("Görünüm Modu", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMapTypeOption(MapType.normal, "Normal", Icons.map, setModalState),
                      _buildMapTypeOption(MapType.satellite, "Uydu", Icons.satellite_alt, setModalState),
                      _buildMapTypeOption(MapType.hybrid, "Hibrit", Icons.layers, setModalState),
                    ],
                  ),

                  const Divider(color: Colors.white10, height: 30),

                  SwitchListTile(
                    title: const Text("Trafik Durumu", style: TextStyle(color: Colors.white)),
                    secondary: Icon(Icons.traffic, color: _trafficEnabled ? aestheticGreen : Colors.grey),
                    value: _trafficEnabled,
                    activeColor: aestheticGreen,
                    onChanged: (val) {
                      setModalState(() => _trafficEnabled = val);
                      setState(() => _trafficEnabled = val);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMapTypeOption(MapType type, String label, IconData icon, StateSetter setModalState) {
    bool isSelected = _currentMapType == type;
    return GestureDetector(
      onTap: () {
        setModalState(() => _currentMapType = type);
        setState(() => _currentMapType = type);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? aestheticGreen.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? aestheticGreen : Colors.transparent, width: 2),
            ),
            child: Icon(icon, color: isSelected ? aestheticGreen : Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isSelected ? aestheticGreen : Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: _currentMapType,
            trafficEnabled: _trafficEnabled,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
            },
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onTap: (_) {},
          ),

          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white54),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) {
                        _performSearch(value);
                      },
                      decoration: const InputDecoration(
                        hintText: "İlçe veya dükkan adı ara...",
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 20,
            child: FloatingActionButton(
              heroTag: "btn1",
              onPressed: _goToMyLocation,
              backgroundColor: Colors.black,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),

          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              heroTag: "btn2",
              onPressed: _openMapSettings,
              backgroundColor: Colors.black,
              child: Icon(Icons.settings, color: aestheticGreen),
            ),
          ),
        ],
      ),
    );
  }
}