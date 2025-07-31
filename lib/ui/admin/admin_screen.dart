import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nike/ui/splash/splash_screen_fade.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_AdminFeature> features = [
      _AdminFeature(Icons.person, "Accounts & Analytics", () {
        Navigator.pushNamed(context, '/account_analysis');
      }),
      _AdminFeature(Icons.history, "Order History", () {
        Navigator.pushNamed(context, '/order_history');
      }),
      _AdminFeature(Icons.list_alt, "Manage Orders", () {
        Navigator.pushNamed(context, '/order_management');
      }),
      _AdminFeature(Icons.bar_chart, "Revenue", () {
        Navigator.pushNamed(context, '/revenue');
      }),
      _AdminFeature(Icons.category, "Categories & Products", () {
        Navigator.pushNamed(context, '/category_product');
      }),
      _AdminFeature(Icons.logout, "Logout", () async {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SplashScreenFade()),
            (route) => false,
          );
        }
      }),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: features.map((feature) => feature.toWidget()).toList(),
        ),
      ),
    );
  }
}

class _AdminFeature {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _AdminFeature(this.icon, this.title, this.onTap);

  Widget toWidget() {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.blue),
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
