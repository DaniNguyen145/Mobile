import 'package:flutter/material.dart';

class OrderHistoryPageView extends StatelessWidget {
  const OrderHistoryPageView({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = [
      {"id": "HD001", "customer": "Nguyễn Văn A", "total": 350000, "date": "12-07-2025"},
      {"id": "HD002", "customer": "Trần Thị B", "total": 245000, "date": "11-07-2025"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Lịch sử đơn hàng")),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return ListTile(
            leading: const Icon(Icons.receipt_long),
            title: Text("Đơn: ${order['id']} - ${order['customer']}"),
            subtitle: Text("Ngày: ${order['date']}"),
            trailing: Text("${order['total']}đ"),
          );
        },
      ),
    );
  }
}
