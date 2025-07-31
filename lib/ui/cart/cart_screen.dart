import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nike/ui/order/confirm_order_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, required this.email});

  final String email;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late CollectionReference cartRef;

  @override
  void initState() {
    super.initState();
    cartRef = FirebaseFirestore.instance
        .collection('cart')
        .doc(widget.email)
        .collection('items');
  }

  Future<void> increaseQuantity(DocumentSnapshot itemDoc) async {
    await cartRef.doc(itemDoc.id).update({'quantity': FieldValue.increment(1)});
  }

  Future<void> decreaseQuantity(DocumentSnapshot itemDoc) async {
    final currentQty = itemDoc['quantity'] ?? 1;
    if (currentQty > 1) {
      await cartRef.doc(itemDoc.id).update({
        'quantity': FieldValue.increment(-1),
      });
    } else {
      await deleteItem(itemDoc.id);
    }
  }

  Future<void> deleteItem(String id) async {
    await cartRef.doc(id).delete();
  }

  Future<DocumentSnapshot?> getProductById(String productId) async {
    try {
      return await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
    } catch (e) {
      return null;
    }
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
        ),
        padding: EdgeInsets.all(8),
        child: Icon(icon, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Your Cart'), backgroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final cartItems = snapshot.data!.docs;
          if (cartItems.isEmpty) {
            return Center(child: Text('Your cart is empty'));
          }

          return ListView.builder(
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final cartDoc = cartItems[index];
              final cartData = cartDoc.data() as Map<String, dynamic>;
              final productId = cartData['product_id'];
              final quantity = cartData['quantity'] ?? 1;
              final color = cartData['color'] ?? '';
              final size = cartData['size'] ?? '';

              return FutureBuilder<DocumentSnapshot?>(
                future: getProductById(productId),
                builder: (context, productSnapshot) {
                  if (!productSnapshot.hasData) return SizedBox();

                  final productDoc = productSnapshot.data;
                  if (productDoc == null || !productDoc.exists) {
                    return ListTile(
                      title: Text('Product not found'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => deleteItem(cartDoc.id),
                      ),
                    );
                  }

                  final productData = productDoc.data() as Map<String, dynamic>;
                  final imageUrl =
                      List<String>.from(
                        productData['image_urls'] ?? [],
                      ).firstOrNull ??
                      '';

                  return Card(
                    color: Colors.white,
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productData['name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text("Color: $color   Size: $size"),
                                SizedBox(height: 4),
                                Text(
                                  "Price: ${NumberFormat("#,###").format(productData['price'])} đ",
                                  style: TextStyle(color: Colors.red),
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    _roundIcon(
                                      Icons.remove,
                                      () => decreaseQuantity(cartDoc),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '$quantity',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(width: 8),
                                    _roundIcon(
                                      Icons.add,
                                      () => increaseQuantity(cartDoc),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 4),
                          _roundIcon(
                            Icons.delete,
                            () => deleteItem(cartDoc.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: cartRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return SizedBox();
          }

          return FutureBuilder<List<DocumentSnapshot?>>(
            future: Future.wait(
              snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return getProductById(data['product_id']);
              }),
            ),
            builder: (context, productSnapshots) {
              if (!productSnapshots.hasData) return SizedBox();

              double total = 0;
              final prices = productSnapshots.data!;
              for (int i = 0; i < prices.length; i++) {
                final product = prices[i];
                if (product == null || !product.exists) continue;
                final productData = product.data() as Map<String, dynamic>;
                final price = productData['price'] ?? 0;
                final quantity =
                    (snapshot.data!.docs[i].data() as Map)['quantity'] ?? 1;
                total += price * quantity;
              }

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total: ${NumberFormat("#,###").format(total)} đ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    // ElevatedButton(
                    //   onPressed: () {
                    //     showDialog(
                    //       context: context,
                    //       builder: (_) {
                    //         final addressCtrl = TextEditingController();
                    //         final phoneCtrl = TextEditingController();
                    //         return AlertDialog(
                    //           backgroundColor: Colors.white,
                    //           title: Text('Confirm Order'),
                    //           content: Column(
                    //             mainAxisSize: MainAxisSize.min,
                    //             children: [
                    //               Text(
                    //                 'Total: ${NumberFormat("#,###").format(total)} đ',
                    //               ),
                    //               SizedBox(height: 12),
                    //               TextField(
                    //                 controller: addressCtrl,
                    //                 decoration: InputDecoration(
                    //                   labelText: 'Shipping Address',
                    //                 ),
                    //               ),
                    //               TextField(
                    //                 controller: phoneCtrl,
                    //                 keyboardType: TextInputType.phone,
                    //                 decoration: InputDecoration(
                    //                   labelText: 'Phone Number',
                    //                 ),
                    //               ),
                    //             ],
                    //           ),
                    //           actions: [
                    //             TextButton(
                    //               child: Text('Cancel'),
                    //               onPressed: () => Navigator.pop(context),
                    //             ),
                    //             ElevatedButton(
                    //               style: ElevatedButton.styleFrom(
                    //                 backgroundColor: Colors.black,
                    //               ),
                    //               child: Text('Confirm'),
                    //               onPressed: () async {
                    //                 final address = addressCtrl.text.trim();
                    //                 final phone = phoneCtrl.text.trim();
                    //
                    //                 if (address.isEmpty ||
                    //                     phone.isEmpty ||
                    //                     phone.length < 9) {
                    //                   ScaffoldMessenger.of(
                    //                     context,
                    //                   ).showSnackBar(
                    //                     SnackBar(
                    //                       content: Text(
                    //                         'Please enter valid address and phone number',
                    //                       ),
                    //                     ),
                    //                   );
                    //                   return;
                    //                 }
                    //
                    //                 Navigator.pop(context); // Close dialog
                    //
                    //                 try {
                    //                   final orderItems =
                    //                       snapshot.data!.docs.map((doc) {
                    //                         final data =
                    //                             doc.data()
                    //                                 as Map<String, dynamic>;
                    //                         return {
                    //                           'product_id': data['product_id'],
                    //                           'quantity': data['quantity'],
                    //                           'color': data['color'],
                    //                           'size': data['size'],
                    //                         };
                    //                       }).toList();
                    //
                    //                   await FirebaseFirestore.instance
                    //                       .collection('bills')
                    //                       .add({
                    //                         'email': widget.email,
                    //                         'address': address,
                    //                         'phone': phone,
                    //                         'items': orderItems,
                    //                         'total': total,
                    //                         'status': 'awaiting_payment',
                    //                         'created_at': Timestamp.now(),
                    //                       });
                    //
                    //                   // Clear cart
                    //                   final batch =
                    //                       FirebaseFirestore.instance.batch();
                    //                   for (var doc in snapshot.data!.docs) {
                    //                     batch.delete(doc.reference);
                    //                   }
                    //                   await batch.commit();
                    //                 } catch (e) {
                    //                   if (context.mounted) {
                    //                     ScaffoldMessenger.of(
                    //                       context,
                    //                     ).showSnackBar(
                    //                       SnackBar(
                    //                         content: Text(
                    //                           'Failed to place order.',
                    //                         ),
                    //                       ),
                    //                     );
                    //                   }
                    //                 }
                    //               },
                    //             ),
                    //           ],
                    //         );
                    //       },
                    //     );
                    //   },
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: Colors.black,
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(8),
                    //     ),
                    //     padding: EdgeInsets.symmetric(
                    //       horizontal: 24,
                    //       vertical: 12,
                    //     ),
                    //   ),
                    //   child: Text(
                    //     'Place Order',
                    //     style: TextStyle(color: Colors.white),
                    //   ),
                    // ),
                    ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConfirmOrderScreen(
                              email: widget.email,
                              cartDocs: snapshot.data!.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>(),
                              total: total.toInt(),
                            ),
                          ),
                        );

                        if (result == true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order placed successfully!')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Place Order', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
