import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatı için (paket yoksa sadece toString yapabiliriz)

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Giriş yapmalısınız.")));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bildirimler 🔔"),
        actions: [
          // Tümünü Okundu İşaretle Butonu
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: "Tümünü Okundu Say",
            onPressed: () {
              // Basit bir batch update yapılabilir
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .get()
                  .then((snapshot) {
                for (DocumentSnapshot ds in snapshot.docs) {
                  ds.reference.update({'isRead': true});
                }
              });
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users') // Her kullanıcının kendi bildirim kutusu var
            .doc(user.uid)
            .collection('notifications')
            .orderBy('date', descending: true) // En yeni en üstte
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text("Henüz bildirim yok.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final bool isRead = notification['isRead'] ?? false;

              // Tarih Gösterimi
              String dateStr = "";
              if (notification['date'] != null) {
                Timestamp ts = notification['date'];
                DateTime dt = ts.toDate();
                dateStr = "${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
              }

              return Container(
                color: isRead ? Colors.transparent : Colors.blue.shade50, // Okunmamışsa mavi arka plan
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Icon(
                      Icons.notifications,
                      color: isRead ? Colors.grey : Colors.blue,
                    ),
                  ),
                  title: Text(
                    notification['title'] ?? 'Bildirim',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification['body'] ?? ''),
                      const SizedBox(height: 4),
                      Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  onTap: () {
                    // Tıklanınca okundu olarak işaretle
                    notifications[index].reference.update({'isRead': true});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}