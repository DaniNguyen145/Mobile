import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CategoryProductPage extends StatelessWidget {
  const CategoryProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Categories & Products",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        tooltip: 'Add Category',
        backgroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Container(
        color: Colors.white,
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('categories').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final categories = snapshot.data!.docs;
            if (categories.isEmpty) {
              return const Center(
                child: Text(
                  "No categories found.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final categoryId = cat.id;
                final name = cat['name'];

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.all(8),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      backgroundColor: Colors.white,
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: [
                        _buildProductList(context, categoryId),
                        OverflowBar(
                          spacing: 8,
                          overflowSpacing: 4,
                          alignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed:
                                  () => _showCategoryDialog(context, doc: cat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCategory(categoryId),
                            ),
                            ElevatedButton.icon(
                              onPressed:
                                  () => _showProductDialog(context, categoryId),
                              icon: const Icon(Icons.add),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                              ),
                              label: const Text("Add Product"),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductList(BuildContext context, String categoryId) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('products')
              .where('category_id', isEqualTo: categoryId)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final products = snapshot.data!.docs;
        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("No products found."),
          );
        }
        return ListView.builder(
          itemCount: products.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final p = products[index];
            final data = p.data() as Map<String, dynamic>;
            final imageUrls = List<String>.from(p['image_urls'] ?? []);

            return ListTile(
              leading:
                  imageUrls.isNotEmpty
                      ? CircleAvatar(
                        backgroundImage: NetworkImage(imageUrls.first),
                      )
                      : const CircleAvatar(
                        child: Icon(Icons.image_not_supported),
                      ),
              title: Text(p['name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Price: ${NumberFormat("#,###").format(p['price'])}đ"),
                  Text('Type: ${p['type']}'),
                  Text('Target: ${p['target']}'),
                  Text(
                    'Colors: ${data.containsKey('colors') ? List<String>.from(p['colors']).join(", ") : "N/A"}',
                  ),
                  Text(
                    'Sizes: ${data.containsKey('sizes') ? List<String>.from(p['sizes']).join(", ") : "N/A"}',
                  ),
                ],
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed:
                        () => _showProductDialog(context, categoryId, doc: p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteProduct(p.id),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCategoryDialog(BuildContext context, {DocumentSnapshot? doc}) {
    final nameController = TextEditingController(
      text: doc != null ? doc['name'] : '',
    );
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(doc == null ? 'Add Category' : 'Edit Category'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Category Name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final ref = FirebaseFirestore.instance.collection(
                    'categories',
                  );
                  if (doc == null) {
                    await ref.add({'name': name});
                  } else {
                    await ref.doc(doc.id).update({'name': name});
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showProductDialog(
    BuildContext context,
    String categoryId, {
    DocumentSnapshot? doc,
  }) {
    final nameController = TextEditingController(
      text: doc != null ? doc['name'] : '',
    );
    final priceController = TextEditingController(
      text: doc != null ? NumberFormat("#,###").format(doc['price']) : '',
    );
    final List<TextEditingController> imageControllers = [];
    if (doc != null && doc['image_urls'] != null) {
      for (var url in List<String>.from(doc['image_urls'])) {
        imageControllers.add(TextEditingController(text: url));
      }
    } else {
      imageControllers.add(TextEditingController());
    }
    var description = '';
    try {
      description = doc != null ? doc['description'] : '';
    } catch (e) {
      description = '';
    }
    final descriptionController = TextEditingController(text: description);

    final List<TextEditingController> colorControllers = [];
    try {
      if (doc != null && doc['colors'] != null) {
        for (var color in List<String>.from(doc['colors'])) {
          colorControllers.add(TextEditingController(text: color));
        }
      } else {
        colorControllers.add(TextEditingController());
      }
    } catch (e) {
      colorControllers.add(TextEditingController());
    }

    final List<TextEditingController> sizeControllers = [];
    try {
      if (doc != null && doc['sizes'] != null) {
        for (var size in List<String>.from(doc['sizes'])) {
          sizeControllers.add(TextEditingController(text: size));
        }
      } else {
        sizeControllers.add(TextEditingController());
      }
    } catch (e) {
      sizeControllers.add(TextEditingController());
    }

    String selectedType = doc != null ? doc['type'] : 'Nike';
    String selectedTarget = doc != null ? doc['target'] : 'Men';

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                title: Text(doc == null ? 'Add Product' : 'Edit Product'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Product Description',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(labelText: 'Price'),
                        onChanged: (value) {
                          final number = int.tryParse(
                            value.replaceAll(',', ''),
                          );
                          if (number != null) {
                            final formatted = NumberFormat(
                              '#,###',
                            ).format(number);
                            priceController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                offset: formatted.length,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Image URLs:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Column(
                        children: List.generate(imageControllers.length, (
                          index,
                        ) {
                          return Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: imageControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Image URL ${index + 1}',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () => setState(
                                      () => imageControllers.removeAt(index),
                                    ),
                              ),
                            ],
                          );
                        }),
                      ),
                      TextButton.icon(
                        onPressed:
                            () => setState(
                              () =>
                                  imageControllers.add(TextEditingController()),
                            ),
                        icon: const Icon(Icons.add),
                        label: const Text("Add image"),
                      ),

                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items:
                            ['Nike', 'Jordan']
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (value) => setState(
                              () => selectedType = value ?? selectedType,
                            ),
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedTarget,
                        decoration: const InputDecoration(labelText: 'Target'),
                        items:
                            ['Men', 'Women', 'Kids']
                                .map(
                                  (target) => DropdownMenuItem(
                                    value: target,
                                    child: Text(target),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (value) => setState(
                              () => selectedTarget = value ?? selectedTarget,
                            ),
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        "Colors:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Column(
                        children: List.generate(colorControllers.length, (
                          index,
                        ) {
                          return Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: colorControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Color ${index + 1}',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () => setState(
                                      () => colorControllers.removeAt(index),
                                    ),
                              ),
                            ],
                          );
                        }),
                      ),
                      TextButton.icon(
                        onPressed:
                            () => setState(
                              () =>
                                  colorControllers.add(TextEditingController()),
                            ),
                        icon: const Icon(Icons.add),
                        label: const Text("Add color"),
                      ),

                      const Text(
                        "Sizes:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Column(
                        children: List.generate(sizeControllers.length, (
                          index,
                        ) {
                          return Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: sizeControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Size ${index + 1}',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () => setState(
                                      () => sizeControllers.removeAt(index),
                                    ),
                              ),
                            ],
                          );
                        }),
                      ),
                      TextButton.icon(
                        onPressed:
                            () => setState(
                              () =>
                                  sizeControllers.add(TextEditingController()),
                            ),
                        icon: const Icon(Icons.add),
                        label: const Text("Add size"),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final price =
                          int.tryParse(
                            priceController.text.trim().replaceAll(',', ''),
                          ) ??
                          0;
                      final imageUrls =
                          imageControllers
                              .map((e) => e.text.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                      final colors =
                          colorControllers
                              .map((e) => e.text.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                      final sizes =
                          sizeControllers
                              .map((e) => e.text.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                      if (name.isEmpty || imageUrls.isEmpty) return;

                      final ref = FirebaseFirestore.instance.collection(
                        'products',
                      );
                      if (doc == null) {
                        await ref.add({
                          'name': name,
                          'price': price,
                          'image_urls': imageUrls,
                          'category_id': categoryId,
                          'type': selectedType,
                          'target': selectedTarget,
                          'colors': colors,
                          'sizes': sizes,
                          'created_at': Timestamp.now(),
                          'description': descriptionController.text.trim(),
                          'order_count': 0,
                        });
                      } else {
                        await ref.doc(doc.id).update({
                          'name': name,
                          'price': price,
                          'image_urls': imageUrls,
                          'type': selectedType,
                          'target': selectedTarget,
                          'colors': colors,
                          'sizes': sizes,
                          'description': descriptionController.text.trim(),
                        });
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _deleteCategory(String id) async {
    await FirebaseFirestore.instance.collection('categories').doc(id).delete();
  }

  void _deleteProduct(String id) async {
    await FirebaseFirestore.instance.collection('products').doc(id).delete();
  }
}
