import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../auth/login_screen.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  // Tasarım Renkleri
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);
  final Color cardBg = const Color(0xFF1E1E1E);

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
  void _showLogoutDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => Container(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 40),
                  ),
                  const SizedBox(height: 24),
                  const Text("Çıkış Yap", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Hesabınızdan çıkış yapmak istediğinize emin misiniz?", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.5)),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("Vazgeç", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await FirebaseAuth.instance.signOut();
                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                    (Route<dynamic> route) => false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text("Çıkış Yap", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- DESTEK SAYFASINA GİT ---
  void _openSupportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BusinessSupportScreen()),
    );
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
                // --- 1. PROFİL HEADER ---
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: aestheticGreen, width: 2)),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: cardBg,
                          child: Icon(Icons.store, size: 40, color: aestheticGreen),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Dükkan Profilim",
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Bilgilerinizi buradan güncelleyebilirsiniz",
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // --- 2. İŞLETME BİLGİLERİ ---
                _buildSectionTitle("İşletme Bilgileri"),
                _buildGlassTextField(_nameController, "Restoran Adı", Icons.store),
                const SizedBox(height: 12),
                _buildGlassTextField(_addressController, "Açık Adres", Icons.map, maxLines: 2),
                const SizedBox(height: 12),
                _buildGlassTextField(_phoneController, "Telefon", Icons.phone, isNumber: true),
                const SizedBox(height: 12),
                _buildTimePickerField(),

                const SizedBox(height: 30),

                // --- 3. KONUM YÖNETİMİ ---
                _buildSectionTitle("Konum Yönetimi"),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _selectedLocation != null ? Icons.check_circle : Icons.warning_amber_rounded,
                            color: _selectedLocation != null ? aestheticGreen : Colors.orange,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedLocation != null
                                  ? "Konum Kayıtlı: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}"
                                  : "Konum Henüz Belirlenmedi",
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // --- 4. DESTEK & DİĞER (TEK MENÜ HALİNE GETİRİLDİ) ---
                _buildSectionTitle("Destek & Diğer"),
                _buildSettingsTile(
                  title: "Destek, Yardım & S.S.S", // İsim güncellendi
                  icon: Icons.help_outline, // İkon yeşil olacak (helper içinde rengi ayarlanırsa)
                  onTap: _openSupportScreen,
                ),

                const SizedBox(height: 40),

                // --- 5. AKSİYONLAR ---
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: aestheticGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 10,
                      shadowColor: aestheticGreen.withOpacity(0.4),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text("DEĞİŞİKLİKLERİ KAYDET", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _showLogoutDialog,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Colors.redAccent.withOpacity(0.05),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Text("HESAPTAN ÇIK", style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---

  // Saat Seçici Widget
  Widget _buildTimePickerField() {
    return GestureDetector(
      onTap: () => _selectTime(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.white54, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _closingTimeController.text.isEmpty
                    ? "Kapanış Saati Seçin"
                    : _closingTimeController.text,
                style: TextStyle(
                  color: _closingTimeController.text.isEmpty
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: aestheticGreen, size: 24),
          ],
        ),
      ),
    );
  }

  // Saat Seçici Dialog
  Future<void> _selectTime() async {
    // Mevcut saati parse et veya varsayılan 22:00 kullan
    TimeOfDay initialTime = const TimeOfDay(hour: 22, minute: 0);

    if (_closingTimeController.text.isNotEmpty) {
      try {
        final parts = _closingTimeController.text.split(':');
        if (parts.length == 2) {
          initialTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (_) {}
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: aestheticGreen,
              onPrimary: Colors.black,
              surface: cardBg,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E1E1E),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color(0xFF1E1E1E),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              dayPeriodColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? aestheticGreen
                      : cardBg),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? Colors.black
                      : Colors.white),
              hourMinuteColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? aestheticGreen
                      : cardBg),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? Colors.black
                      : Colors.white),
              dialHandColor: aestheticGreen,
              dialBackgroundColor: cardBg,
              dialTextColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? Colors.black
                      : Colors.white),
              entryModeIconColor: aestheticGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Saat formatını HH:mm olarak kaydet
        final hour = picked.hour.toString().padLeft(2, '0');
        final minute = picked.minute.toString().padLeft(2, '0');
        _closingTimeController.text = '$hour:$minute';
      });
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildGlassTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        validator: (value) => value!.isEmpty ? "Bu alan zorunludur" : null,
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

  Widget _buildSettingsTile({required String title, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // Biraz genişletildi
      tileColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.05))),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: aestheticGreen, size: 20), // İKON RENGİ YEŞİL YAPILDI
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.3), size: 16),
    );
  }
}

// ============================================================================
// YENİ: YARDIM, DESTEK VE S.S.S SAYFASI
// ============================================================================
class BusinessSupportScreen extends StatelessWidget {
  const BusinessSupportScreen({super.key});

  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);
  final Color cardBg = const Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        title: const Text("Yardım ve Destek", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.support_agent, color: aestheticGreen),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BİZE ULAŞIN ---
            Text("BİZE ULAŞIN", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: aestheticGreen.withOpacity(0.2)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: aestheticGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.email_outlined, color: aestheticGreen),
                ),
                title: const Text("E-Posta Desteği", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text("destek@uygulama.com", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.3), size: 16),
              ),
            ),

            const SizedBox(height: 32),

            // --- SIKÇA SORULAN SORULAR ---
            Text("SIKÇA SORULAN SORULAR", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),

            _buildFaqItem("Siparişimi ne zaman teslim alabilirim?", "Sipariş hazırlandıktan sonra, müşteri gelene kadar bekletmeli ve QR kod ile teslim etmelisiniz."),
            _buildFaqItem("Teslim almaya gitmezsem ne olur?", "Eğer müşteri belirtilen sürede gelmezse, sipariş detayından 'Müşteri Gelmedi' butonuna basarak stok durumunu düzeltebilirsiniz."),
            _buildFaqItem("Siparişi iptal edebilir miyim?", "Henüz hazırlanmaya başlanmamış siparişleri panelden iptal edebilirsiniz."),
            _buildFaqItem("Ödemeyi nasıl yapıyorum?", "Ödemeler uygulama üzerinden kredi kartı veya cüzdan bakiyesi ile yapılır."),
            _buildFaqItem("Yemekler taze mi?", "İşletmelerimiz, gün sonunda kalan taze ve tüketime uygun ürünleri listelemektedir."),

            const SizedBox(height: 40),
            Center(
              child: Text(
                "v1.2.0 (Güvenlik Paketi)",
                style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent), // Çizgiyi kaldırır
        child: ExpansionTile(
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white54,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: aestheticGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.question_mark, color: aestheticGreen, size: 18),
          ),
          title: Text(question, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(answer, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}