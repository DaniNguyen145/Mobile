import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show
        GlobalCupertinoLocalizations,
        GlobalMaterialLocalizations,
        GlobalWidgetsLocalizations;
import 'package:nike/ui/admin/account_analysis/account_analysis_page_view.dart';
import 'package:nike/ui/admin/admin_screen.dart';
import 'package:nike/ui/admin/categories/category_product_page.dart';
import 'package:nike/ui/admin/order_history/admin_order_management_screen.dart';
import 'package:nike/ui/admin/order_history/order_history_page_view.dart';
import 'package:nike/ui/forgot_password/forgot_password_screen.dart';
import 'package:nike/ui/home/home_screen.dart';
import 'package:nike/ui/login/login_screen.dart';
import 'package:nike/ui/payment/creative_qr_payment_screen.dart';
import 'package:nike/ui/register/register_screen.dart';
import 'package:nike/ui/splash/splash_screen_fade.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nike',
      debugShowCheckedModeBanner: false,
      locale: const Locale('en', 'US'),
      supportedLocales: const [Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(primarySwatch: Colors.lightBlue),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreenFade(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/forgot_password': (context) => ForgotPasswordScreen(),

        '/admin': (context) => AdminScreen(),
        '/account_analysis': (_) => const AccountAnalysisPageView(),
        '/order_history': (_) => const AdminOrderManagementScreen(),

        '/category_product': (_) => const CategoryProductPage(),
        '/payment': (_) => const CreativeQrPaymentScreen(),
      },
    );
  }
}
