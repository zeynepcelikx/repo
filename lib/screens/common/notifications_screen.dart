import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);

  // --- LOGIC: TÜMÜNÜ OKUNDU İŞARETLE ---
  Future<void> _markAllAsRead() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var batch = FirebaseFirestore.instance.batch();
    var snapshots = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text("Tüm bildirimler okundu olarak işaretlendi."),
        backgroundColor: aestheticGreen,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // --- TARİH FORMATLAYICI ---
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "";

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return "";
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0 && now.day == date.day) {
      return "BUGÜN ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } else if (difference.inDays <= 1 && (now.day - date.day == 1 || now.day - date.day == -30)) {
      return "DÜN ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } else {
      return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text("Bildirimler", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      SizedBox(width: 8),
                      Text("🔔", style: TextStyle(fontSize: 24)),
                    ],
                  ),
                  GestureDetector(
                    onTap: _markAllAsRead,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.1))),
                      child: const Icon(Icons.done_all, color: Colors.white70, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Liste
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .collection('notifications')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: aestheticGreen));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.white.withOpacity(0.1)),
                          const SizedBox(height: 16),
                          Text("Henüz bir bildiriminiz yok.", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  // Client-side Sıralama (En yeni en üstte)
                  var docs = snapshot.data!.docs;
                  docs.sort((a, b) {
                    var dataA = a.data() as Map<String, dynamic>;
                    var dataB = b.data() as Map<String, dynamic>;

                    DateTime timeA = DateTime(1970);
                    DateTime timeB = DateTime(1970);

                    if (dataA['timestamp'] is Timestamp) timeA = (dataA['timestamp'] as Timestamp).toDate();
                    else if (dataA['timestamp'] is DateTime) timeA = dataA['timestamp'];

                    if (dataB['timestamp'] is Timestamp) timeB = (dataB['timestamp'] as Timestamp).toDate();
                    else if (dataB['timestamp'] is DateTime) timeB = dataB['timestamp'];

                    return timeB.compareTo(timeA);
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var doc = docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      String id = doc.id;
                      return _buildNotificationCard(data, id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- RESTORAN TARZI YEŞİL KART ---
  Widget _buildNotificationCard(Map<String, dynamic> data, String id) {
    bool isRead = data['isRead'] ?? false;
    String title = data['title'] ?? 'Bildirim';
    String body = data['body'] ?? '';
    dynamic timestamp = data['timestamp'];
    String timeText = _formatDate(timestamp);

    IconData iconData = Icons.notifications;
    String lowerTitle = title.toLowerCase();

    // İkon Seçimi
    if (lowerTitle.contains('sipariş') || lowerTitle.contains('hazır') || lowerTitle.contains('alındı')) {
      iconData = Icons.shopping_bag;
    } else if (lowerTitle.contains('indirim') || lowerTitle.contains('fırsat')) {
      iconData = Icons.local_fire_department;
    } else if (lowerTitle.contains('teslim') || lowerTitle.contains('paket')) {
      iconData = Icons.check_circle;
    } else if (lowerTitle.contains('puan') || lowerTitle.contains('tebrik')) {
      iconData = Icons.star;
    } else if (lowerTitle.contains('kurtar') || lowerTitle.contains('dünya')) {
      iconData = Icons.eco;
    }

    return GestureDetector(
      onTap: () {
        if (!isRead) _markAsRead(id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Koyu Zemin
          borderRadius: BorderRadius.circular(16),
          // ÇERÇEVE AYARI:
          // Okunmamışsa: Kalın Parlak Yeşil
          // Okunmuşsa: İnce Mat Yeşil (Böylece hep yeşil tema korunur)
          border: Border.all(
            color: isRead ? aestheticGreen.withOpacity(0.3) : aestheticGreen,
            width: isRead ? 1 : 1.5,
          ),
          // Okunmamışsa arkaya hafif yeşil ışık (Glow)
          boxShadow: isRead ? [] : [
            BoxShadow(
              color: aestheticGreen.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İkon Kutusu
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: aestheticGreen.withOpacity(0.15), // Hep Yeşilimsi Zemin
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // İkon Rengi: Okunmamışsa Parlak Yeşil, Okunmuşsa Mat Yeşil
                  child: Icon(
                      iconData,
                      color: isRead ? aestheticGreen.withOpacity(0.7) : aestheticGreen,
                      size: 24
                  ),
                ),

                const SizedBox(width: 16),

                // Metinler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: TextStyle(
                          color: isRead ? Colors.white54 : Colors.grey.shade300,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: aestheticGreen.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Text(
                            timeText,
                            style: TextStyle(
                              color: aestheticGreen.withOpacity(0.6), // Tarih de yeşilimsi
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // YEŞİL NOKTA (Sadece Okunmamışsa Sağ Üstte Yanar)
            if (!isRead)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: aestheticGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: aestheticGreen.withOpacity(0.8),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}