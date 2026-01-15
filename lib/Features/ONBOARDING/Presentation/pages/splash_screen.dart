import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // 1. Configure the animation
    _controller = AnimationController(
      duration: const Duration(seconds: 1, milliseconds: 500), 
      vsync: this,
    )..repeat(reverse: true); 

    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 2. ⚠️ IMPORTANT: CALL THE NAVIGATION FUNCTION HERE!
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate loading time (e.g. 3 seconds)
    // If you set this to 1ms, it might flash too fast to see the animation
    await Future.delayed(const Duration(seconds: 3));
    
    // 3. Navigate once loading is complete
    if (mounted) {
      context.go('/intake'); 
    }
  }

  @override
  void dispose() {
    _controller.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121820), // Added background color to match app
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Image.asset(
            'assets/Images/appicon.png',
            width: 150, 
            height: 150,
          ),
        ),
      ),
    );
  }
}