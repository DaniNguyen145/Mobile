import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ConfirmOrderScreen extends StatefulWidget {
  final int total;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> cartDocs;
  final String email;

  const ConfirmOrderScreen({
    super.key,
    required this.total,
    required this.cartDocs,
    required this.email,
  });

  @override
  State<ConfirmOrderScreen> createState() => _ConfirmOrderScreenState();
}

class _ConfirmOrderScreenState extends State<ConfirmOrderScreen> {
  final addressCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    addressCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmOrder() async {
    final address = addressCtrl.text.trim();
    final phone = phoneCtrl.text.trim();

    if (address.isEmpty || phone.isEmpty || phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid address and phone number'),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final orderItems =
          widget.cartDocs.map((doc) {
            final data = doc.data();
            return {
              'product_id': data['product_id'],
              'quantity': data['quantity'],
              'color': data['color'],
              'size': data['size'],
            };
          }).toList();

      final createdAt = DateTime.now();
      final docRef = await FirebaseFirestore.instance.collection('bills').add({
        'email': widget.email,
        'address': address,
        'phone': phone,
        'items': orderItems,
        'total': widget.total,
        'status': 'awaiting_payment',
        'created_at': createdAt,
      });

      final newOrderId = docRef.id;

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in widget.cartDocs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/payment',
          (Route<dynamic> route) => false,
          arguments: {
            'orderId': newOrderId,
            'createdAt': createdAt.toIso8601String(),
            'total': widget.total,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to place order.')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Confirm Order'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Total: ${NumberFormat("#,###").format(widget.total)} đ',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Shipping Address'),
            ),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 24),
            isLoading
                ? const CircularProgressIndicator()
                : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _confirmOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
