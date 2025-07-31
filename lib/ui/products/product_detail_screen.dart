import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductDetailScreen extends StatefulWidget {
  final DocumentSnapshot product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int selectedImageIndex = 0;
  String? selectedColor;
  String? selectedSize;
  late final PageController _pageController;
  late String productId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    productId = widget.product.id;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> addToCart({
    required String email,
    required String productId,
    required String selectedColor,
    required String selectedSize,
  }) async {
    final cartItemId = '${productId}_${selectedColor}_$selectedSize';

    final docRef = FirebaseFirestore.instance
        .collection('cart')
        .doc(email)
        .collection('items')
        .doc(cartItemId);

    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.update({'quantity': FieldValue.increment(1)});
    } else {
      await docRef.set({
        'product_id': productId,
        'color': selectedColor,
        'size': selectedSize,
        'quantity': 1,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product.data() as Map<String, dynamic>;

    final List<String> images = List<String>.from(
      p['image_urls'] ?? [p['image_url']],
    );
    final List<String> colors = List<String>.from(p['colors'] ?? []);
    final List<String> sizes = List<String>.from(p['sizes'] ?? []);
    final price = NumberFormat("#,###").format(p['price']);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(p['name'], style: const TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed:
              (selectedColor != null && selectedSize != null)
                  ? () async {
                    try {
                      final email =
                          FirebaseAuth.instance.currentUser?.email ?? '';
                      if (email.isEmpty) {
                        throw Exception('User not logged in');
                      }

                      await addToCart(
                        email: email,
                        productId: productId,
                        selectedColor: selectedColor ?? '',
                        selectedSize: selectedSize ?? '',
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Product has been added to your cart!',
                            ),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }

                      setState(() {
                        selectedColor = null;
                        selectedSize = null;
                      });
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to add to cart!: ${e.toString()}',
                            ),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  }
                  : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: Colors.black,
            disabledBackgroundColor: Colors.grey,
          ),
          child: const Text(
            "Add to Cart",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Swiper ảnh
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => selectedImageIndex = index);
              },
              itemBuilder: (_, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 60),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Thumbnail indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                images.asMap().entries.map((entry) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedImageIndex = entry.key);
                      _pageController.jumpToPage(entry.key);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              selectedImageIndex == entry.key
                                  ? Colors.black
                                  : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Image.network(
                        entry.value,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 16),

          // Thông tin
          Text("Type: ${p['type']}"),
          Text("Target: ${p['target']}"),
          Text(
            "Price: $price đ",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // Color selector
          const Text(
            "Select Color",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 8,
            children:
                colors.map((color) {
                  final isSelected = selectedColor == color;
                  return ChoiceChip(
                    label: Text(color),
                    selected: isSelected,
                    showCheckmark: false,
                    backgroundColor: Colors.white,
                    onSelected: (_) {
                      setState(() => selectedColor = color);
                    },
                    selectedColor: Colors.black,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 16),

          // Size selector
          const Text(
            "Select Size",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 8,
            children:
                sizes.map((size) {
                  final isSelected = selectedSize == size;
                  return ChoiceChip(
                    label: Text(size.toString()),
                    selected: isSelected,
                    showCheckmark: false,
                    backgroundColor: Colors.white,
                    onSelected: (_) {
                      setState(() => selectedSize = size);
                    },
                    selectedColor: Colors.black,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 16),
          Text(
            "Description",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(p['description'] ?? 'No description available.', style: TextStyle(fontSize: 16)),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
