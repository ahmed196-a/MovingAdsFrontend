
import 'package:flutter/material.dart';
import '../../theme/apptheme.dart';
// import 'package:ads_frontend/assets/images/logo.png';


class Splashview extends StatefulWidget {
  const Splashview({super.key});

  @override
  State<Splashview> createState() => _SplashviewState();
}

class _SplashviewState extends State<Splashview> {
  @override
  void initState() {
    super.initState();


    Future.delayed( Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryTeal, // your brand color
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // LOGO
            Image.asset(
              'assets/images/logo.png',
              width: 160,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 10),

            Text(
              'MOVING ADS',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 2),

            // TAGLINE
            const Text(
              'Ad lagao, paisa kamao',
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
  }

