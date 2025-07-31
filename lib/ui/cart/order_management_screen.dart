import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderManagementScreen extends StatelessWidget {
  final String email;

  const OrderManagementScreen({super.key, required this.email});

  Future<List<Map<String, dynamic>>> fetchOrderItems(List items) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    List<Map<String, dynamic>> result = [];

    for (var item in items) {
      final doc =
          await firestore.collection('products').doc(item['product_id']).get();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<QuerySnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('bills')
                .where('email', isEqualTo: email)
                .get(),
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
              final data = orders[index].data() as Map<String, dynamic>;

              String status =
                  (data['status'] ?? 'unknown').toString().toLowerCase();
              Color statusColor;
              String displayStatus;

              print('status = $status');
              switch (status) {
                case 'pending':
                case 'awaiting_payment':
                  statusColor = Colors.amber;
                  displayStatus = 'Pending Confirmation';
                  break;
                case 'canceled':
                  statusColor = Colors.red;
                  displayStatus = 'Canceled';
                  break;
                case 'paid':
                  statusColor = Colors.green;
                  displayStatus = 'Paid';
                  break;
                case 'shipping':
                  statusColor = Colors.orange;
                  displayStatus = 'Shipping';
                  break;
                case 'delivered':
                  statusColor = Colors.green;
                  displayStatus = 'Delivered';
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
                        '🧾 Order ID: ${orders[index].id}',
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
                              const Text(
                                '📦 Purchased Products:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              ...items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    '- ${item['name']} x${item['quantity']} (${item['price']}₫)',
                                  ),
                                ),
                              ),
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
                      Text(
                        '📍 Shipping Address: ${data['address'] ?? 'Unknown'}',
                      ),
                      Text('📞 Phone Number: ${data['phone'] ?? 'Unknown'}'),

                      // Hiển thị nút tương ứng theo trạng thái
                      if (status == 'pending') ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('bills')
                                  .doc(orders[index].id)
                                  .update({'status': 'canceled'});

                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'The order has been cancelled.',
                                  ),
                                ),
                              );

                              // ignore: use_build_context_synchronously
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          OrderManagementScreen(email: email),
                                ),
                              );
                            },
                            child: const Text(
                              'Cancel Order',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ] else if (status == 'shipping') ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('bills')
                                  .doc(orders[index].id)
                                  .update({'status': 'delivered'});

                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Thank you for confirming!'),
                                ),
                              );

                              // ignore: use_build_context_synchronously
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          OrderManagementScreen(email: email),
                                ),
                              );
                            },
                            child: const Text(
                              'Received Order',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
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
