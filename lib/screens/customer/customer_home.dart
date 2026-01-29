import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'product_detail_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  // --- STATE DEĞİŞKENLERİ ---
  String _selectedCategory = 'Hepsi';
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // Tasarım Renkleri
  final Color aestheticGreen = const Color(0xFF4CAF50);
  final Color darkBg = const Color(0xFF0C0C0C);

  final List<String> _categories = [
    'Hepsi',
    'Ana Yemek',
    'Fast Food',
    'Tatlı',
    'Unlu Mamül',
    'İçecek',
    'Market',
    'Diğer'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('products');
    if (_selectedCategory != 'Hepsi') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. HEADER & ARAMA ---
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                children: [
                  const Text(
                    "Lezzetleri Keşfet 🍔",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Canın ne çekiyor? (Örn: Pizza)",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = "";
                            });
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. KATEGORİLER ---
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? aestheticGreen : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected ? aestheticGreen : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // --- 3. ÜRÜN LİSTESİ ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: aestheticGreen));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 60, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 10),
                          Text("Bu kategoride ürün yok.", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                        ],
                      ),
                    );
                  }

                  final allProducts = snapshot.data!.docs;
                  final filteredProducts = allProducts.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery);
                  }).toList();

                  if (filteredProducts.isEmpty) {
                    return const Center(child: Text("Aradığınız ürün bulunamadı.", style: TextStyle(color: Colors.white54)));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      var productDoc = filteredProducts[index];
                      var productData = productDoc.data() as Map<String, dynamic>;
                      productData['id'] = productDoc.id;

                      String name = productData['name'] ?? 'İsimsiz';
                      int stock = int.tryParse(productData['stock'].toString()) ?? 0;

                      double price = 0.0;
                      if (productData['discountedPrice'] != null) {
                        price = double.tryParse(productData['discountedPrice'].toString()) ?? 0.0;
                      } else if (productData['price'] != null) {
                        price = double.tryParse(productData['price'].toString()) ?? 0.0;
                      }

                      double originalPrice = 0.0;
                      if (productData['originalPrice'] != null) {
                        originalPrice = double.tryParse(productData['originalPrice'].toString()) ?? 0.0;
                      }

                      int discountRate = 0;
                      if (originalPrice > price && price > 0) {
                        discountRate = (((originalPrice - price) / originalPrice) * 100).round();
                      }

                      String imageUrl = productData['imageUrl'] ?? '';
                      if (imageUrl.isEmpty) {
                        imageUrl = 'https://cdn-icons-png.flaticon.com/512/2921/2921822.png';
                      }
                      productData['price'] = price;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(productData: productData),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            // Kart Rengi (Koyu Gri)
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(24),

                            // --- YENİ EKLENEN KISIM: YEŞİL PARILTI ---
                            boxShadow: [
                              BoxShadow(
                                color: aestheticGreen.withOpacity(0.25), // Yeşil Yansıma
                                blurRadius: 20, // Yumuşaklık
                                spreadRadius: 2, // Yayılma
                                offset: const Offset(0, 8), // Aşağı doğru
                              ),
                            ],
                            // Hafif yeşil kenarlık ile destekledik
                            border: Border.all(color: aestheticGreen.withOpacity(0.1), width: 0.01),
                            // ----------------------------------------
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Resim Alanı
                              Expanded(
                                flex: 6,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        image: DecorationImage(
                                          image: NetworkImage(imageUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),

                                    // Stok Rozeti
                                    Positioned(
                                      top: 16,
                                      left: 16,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "$stock Adet",
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),

                                    // İndirim Rozeti
                                    if (discountRate > 0)
                                      Positioned(
                                        top: 16,
                                        right: 16,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "-$discountRate%",
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Bilgiler
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (discountRate > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 6.0),
                                              child: Text(
                                                  "${originalPrice.toStringAsFixed(2)}₺",
                                                  style: TextStyle(
                                                      decoration: TextDecoration.lineThrough,
                                                      color: Colors.white.withOpacity(0.5),
                                                      fontSize: 11
                                                  )
                                              ),
                                            ),
                                          Text(
                                              "${price.toStringAsFixed(2)}₺",
                                              style: TextStyle(
                                                  color: aestheticGreen,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16
                                              )
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
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
}