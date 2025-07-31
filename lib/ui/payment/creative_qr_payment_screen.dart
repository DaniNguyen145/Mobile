import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreativeQrPaymentScreen extends StatefulWidget {
  const CreativeQrPaymentScreen({super.key});

  @override
  State<CreativeQrPaymentScreen> createState() =>
      _CreativeQrPaymentScreenState();
}

class _CreativeQrPaymentScreenState extends State<CreativeQrPaymentScreen> {
  int selectedIndex = 0;

  final qrAccounts = [
    {'label': 'Momo', 'qrPath': 'assets/images/momo_pay.png'},
    {'label': 'VNPAY', 'qrPath': 'assets/images/bank_pay.png'},
  ];

  final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  Widget build(BuildContext context) {
    final selectedAccount = qrAccounts[selectedIndex];

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final String orderId = args['orderId'];
    final String createdAtStr = args['createdAt'];
    final int total = args['total'];

    final createdAt = DateFormat(
      'HH:mm dd/MM/yyyy',
    ).format(DateTime.parse(createdAtStr));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Payment Confirmation'),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Toggle Switch
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ToggleButtons(
                isSelected: [selectedIndex == 0, selectedIndex == 1],
                onPressed: (index) {
                  setState(() => selectedIndex = index);
                },
                borderRadius: BorderRadius.circular(12),
                fillColor: Colors.blue.shade100,
                selectedColor: Colors.blue.shade800,
                color: Colors.black87,
                constraints: const BoxConstraints(minHeight: 48, minWidth: 120),
                children: qrAccounts.map((e) => Text(e['label']!)).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // QR & Order Info
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // 🎉 QR Animated Switch
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        key: ValueKey(selectedIndex),
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            selectedAccount['qrPath']!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Order Info Cards
                    _OrderInfoCard(
                      icon: Icons.receipt_long,
                      title: '',
                      value: orderId,
                    ),
                    _OrderInfoCard(
                      icon: Icons.attach_money,
                      title: '',
                      value: '${NumberFormat("#,###").format(total)}đ',
                      valueColor: Colors.redAccent,
                    ),
                    _OrderInfoCard(
                      icon: Icons.access_time,
                      title: '',
                      value: createdAt,
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('bills')
                            .doc(orderId)
                            .update({'status': 'canceled'});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order has been canceled.'),
                            ),
                          );
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                            (Route<dynamic> route) => false,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14, color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Confirm button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('bills')
                            .doc(orderId)
                            .update({'status': 'paid'});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order has been paid.'),
                            ),
                          );
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                                (Route<dynamic> route) => false,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      label: const Text(
                        'Confirm',
                        style: TextStyle(fontSize: 14, color: Colors.green),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.grey.withValues(alpha: 0.2),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        trailing: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ),
    );
  }
}
