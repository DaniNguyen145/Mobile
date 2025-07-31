import 'package:flutter/material.dart';

class OrderStatusScreen extends StatelessWidget {
  final String email;

  const OrderStatusScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order Status')),
      body: Center(
        child: Text(
          'Your order has been placed.\nWe will process it shortly!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
