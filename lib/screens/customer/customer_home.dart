import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'product_detail_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  // Seçilen Kategori ('Hepsi' varsayılan)
  String _selectedCategory = 'Hepsi';
  String _searchQuery = ""; // Arama metnini tutacak değişken
  final TextEditingController _searchController = TextEditingController();

  // Kategori Listesi
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
    // SORGUSU: Sadece kategoriye göre veriyi çekiyoruz
    Query query = FirebaseFirestore.instance.collection('products');
    if (_selectedCategory != 'Hepsi') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lezzetleri Keşfet 🍔"),
        automaticallyImplyLeading: false,
        // actions: [...] KISMI TAMAMEN KALDIRILDI ❌
        // Artık sağ üstte zil ikonu yok, bildirimler alt menüde.
      ),
      body: Column(
        children: [
          // --- 1. ARAMA ÇUBUĞU --- 🔍
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Canın ne çekiyor? (Örn: Pizza)",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = "";
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),

          // --- 2. KATEGORİ FİLTRE ÇUBUĞU ---
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // --- 3. ÜRÜN LİSTESİ ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 60, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text("$_selectedCategory kategorisinde ürün yok."),
                      ],
                    ),
                  );
                }

                // --- ARAMA FİLTRESİ ---
                final allProducts = snapshot.data!.docs;
                final filteredProducts = allProducts.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(child: Text("Aradığınız ürün bulunamadı. 🔍"));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.70,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
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
                      child: Card(
                        elevation: 3,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                      image: DecorationImage(
                                        image: NetworkImage(imageUrl),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  // Stok Etiketi
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "$stock Adet",
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  // İndirim Etiketi
                                  if (discountRate > 0)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (discountRate > 0)
                                        Text("${originalPrice.toStringAsFixed(2)}₺",
                                            style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12)),
                                      const SizedBox(width: 5),
                                      Text("${price.toStringAsFixed(2)}₺",
                                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                ],
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
    );
  }
}