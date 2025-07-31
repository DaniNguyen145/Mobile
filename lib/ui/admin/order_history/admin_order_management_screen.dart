import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrderManagementScreen extends StatelessWidget {
  const AdminOrderManagementScreen({super.key});

  Future<List<Map<String, dynamic>>> fetchOrderItems(List items) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> result = [];

    for (var item in items) {
      final doc = await firestore.collection('products').doc(item['product_id']).get();
      if (doc.exists) {
        result.add({
          'name': doc['name'],
          'price': doc['price'],
          'quantity': item['quantity'],
        });
      }
    }

    return result;
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance.collection('bills').doc(orderId).update({
      'status': newStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Order Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bills').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders found."));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;
              final orderId = doc.id;

              String status = (data['status'] ?? 'unknown').toString().toLowerCase();
              Color statusColor;
              String displayStatus;

              switch (status) {
                case 'pending':
                  statusColor = Colors.amber;
                  displayStatus = 'Pending Confirmation';
                  break;
                case 'shipping':
                  statusColor = Colors.orange;
                  displayStatus = 'Shipping';
                  break;
                case 'delivered':
                  statusColor = Colors.green;
                  displayStatus = 'Delivered';
                  break;
                case 'cancelled':
                  statusColor = Colors.red;
                  displayStatus = 'Cancelled';
                  break;
                default:
                  statusColor = Colors.grey;
                  displayStatus = 'Unknown';
                  break;
              }

              return Card(
                margin: const EdgeInsets.all(12),
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🧾 Order ID: $orderId',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: fetchOrderItems(data['items']),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          final items = snapshot.data!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('📦 Purchased Products:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              ...items.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text('- ${item['name']} x${item['quantity']} (${item['price']}₫)'),
                              )),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 10),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: '🚚 Status: ',
                              style: TextStyle(color: Colors.black),
                            ),
                            TextSpan(
                              text: displayStatus,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text('👤 Email: ${data['email'] ?? 'Unknown'}'),
                      Text('📍 Shipping Address: ${data['address'] ?? 'Unknown'}'),
                      Text('📞 Phone Number: ${data['phone'] ?? 'Unknown'}'),

                      if (status == 'pending') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await updateOrderStatus(orderId, 'shipping');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Order confirmed and set to Shipping.')),
                                  );
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Confirm'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await updateOrderStatus(orderId, 'cancelled');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Order cancelled.')),
                                  );
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('Cancel'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
