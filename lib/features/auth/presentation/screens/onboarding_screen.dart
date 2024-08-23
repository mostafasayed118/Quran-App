import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          children: [
            Text(
              'بسم الله الرحمن الرحيم',
              style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
            ),
            
          ],
        ),
      ),
    );
  }
}
