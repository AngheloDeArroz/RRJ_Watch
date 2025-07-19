import 'package:flutter/material.dart';
import 'dart:async';
import 'main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<Offset> _slideAnimation;

  double progress = 0.0;
  String loadingMessage = "Initializing...";

  final List<String> loadingMessages = [
    "Initializing...",
    "Connecting to sensors...",
    "Loading dashboard...",
    "Almost there..."
  ];

  int currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    ));

    _logoController.forward();

    // Simulate loading
    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        progress += 0.25;
        if (progress >= 1.0) {
          timer.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        } else {
          currentMessageIndex =
              (currentMessageIndex + 1) % loadingMessages.length;
          loadingMessage = loadingMessages[currentMessageIndex];
        }
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF006D77),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideTransition(
              position: _slideAnimation,
              child: Image.asset(
                'assets/images/splash_logo_centered.png',
                width: 200,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'RRJ WATCH',
              style: TextStyle(
                fontFamily: 'SuperWater',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Wireless Aquarium Tracking & Control Hub',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loadingMessage,
              style: const TextStyle(
                fontFamily: 'Lexend',
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
