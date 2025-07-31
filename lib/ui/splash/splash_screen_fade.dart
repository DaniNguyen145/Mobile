import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nike/widgets/fade_image_switcher.dart';

class SplashScreenFade extends StatefulWidget {
  const SplashScreenFade({super.key});

  @override
  State<SplashScreenFade> createState() => _SplashScreenFadeState();
}

class _SplashScreenFadeState extends State<SplashScreenFade>
    with SingleTickerProviderStateMixin {
  final List<String> _images = [
    'assets/images/splash_01.png',
    'assets/images/splash_02.png',
    'assets/images/splash_03.png',
  ];

  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Đã login
      setState(() {
        _isLoggedIn = true;
      });

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.email)
              .get();

      if (!doc.exists) {
        throw Exception("User data not found in Firestore");
      }

      final data = doc.data();
      final role = data?['role'];

      // Navigate to home page
      if (mounted) {
        if (role == 'admin') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/admin',
            (Route<dynamic> route) => false,
          );
        } else if (role == 'user') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (Route<dynamic> route) => false,
          );
        }
      }
    } else {
      // Chưa login
      setState(() {
        _isLoggedIn = false;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FadeImageSwitcher(images: _images),

          // Overlay gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 1),
                    Colors.black.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/logo_nike.png',
                  fit: BoxFit.cover,
                  width: 80,
                  height: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Free shipping, members-only products, the best of Nike, personalized for you.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  Center(child: CircularProgressIndicator(color: Colors.white))
                else if (!_isLoggedIn)
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text('Sign Up'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
