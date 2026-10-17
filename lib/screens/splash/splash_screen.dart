import 'dart:async';

import 'package:flutter/material.dart';
import 'package:field_survey/screens/auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 65,
                color: Color(0xFF2E7D6B),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Field Survey',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Solusi mudah untuk melakukan survei lapangan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Color(0xFF78909C)),
            ),

            const SizedBox(height: 40),

            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF2E7D6B),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Memuat aplikasi...',
              style: TextStyle(fontSize: 13, color: Color(0xFF90A4AE)),
            ),
          ],
        ),
      ),
    );
  }
}
