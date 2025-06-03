import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _floatAnimation;

  final Color primaryRed = const Color.fromRGBO(112, 1, 0, 1);
  final Color primaryYellow = const Color.fromRGBO(246, 196, 1, 1);
  final Color lightRed = const Color.fromRGBO(112, 1, 0, 0.1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: const Color(0xFFF0F1F5),
        child: SafeArea(
          child: Stack(
            children: [
              // Patterned background with many student-related icons
              Positioned.fill(
                child: Opacity(
                  opacity: 0.13,
                  child: Stack(
                    children: [
                      // Row 1
                      Positioned(top: 40, left: 20, child: Icon(Icons.book_rounded, size: 50, color: primaryRed)),
                      Positioned(top: 80, right: 30, child: Icon(Icons.backpack_rounded, size: 40, color: primaryYellow)),
                      Positioned(top: 60, left: 120, child: Icon(Icons.laptop_mac_rounded, size: 35, color: primaryYellow)),
                      Positioned(top: 120, right: 100, child: Icon(Icons.edit_note_rounded, size: 30, color: primaryRed)),
                      Positioned(top: 30, right: 80, child: Icon(Icons.science_rounded, size: 38, color: primaryRed)),
                      // Row 2
                      Positioned(top: 180, left: 60, child: Icon(Icons.search_rounded, size: 40, color: primaryRed)),
                      Positioned(top: 200, right: 40, child: Icon(Icons.school_rounded, size: 45, color: primaryYellow)),
                      Positioned(top: 220, left: 180, child: Icon(Icons.calculate_rounded, size: 32, color: primaryYellow)),
                      Positioned(top: 160, right: 120, child: Icon(Icons.palette_rounded, size: 36, color: primaryRed)),
                      // Row 3
                      Positioned(bottom: 220, left: 40, child: Icon(Icons.menu_book_rounded, size: 40, color: primaryRed)),
                      Positioned(bottom: 200, right: 60, child: Icon(Icons.sports_esports_rounded, size: 38, color: primaryYellow)),
                      Positioned(bottom: 180, left: 120, child: Icon(Icons.headphones_rounded, size: 32, color: primaryYellow)),
                      Positioned(bottom: 160, right: 100, child: Icon(Icons.coffee_rounded, size: 36, color: primaryRed)),
                      // Row 4
                      Positioned(bottom: 120, left: 60, child: Icon(Icons.search_rounded, size: 40, color: primaryRed)),
                      Positioned(bottom: 60, right: 80, child: Icon(Icons.laptop_mac_rounded, size: 55, color: primaryYellow)),
                      Positioned(bottom: 40, left: 180, child: Icon(Icons.edit_note_rounded, size: 45, color: primaryRed)),
                      Positioned(bottom: 30, right: 30, child: Icon(Icons.science_rounded, size: 38, color: primaryRed)),
                      // Extra scattered
                      Positioned(top: 300, left: 30, child: Icon(Icons.book_rounded, size: 30, color: primaryRed)),
                      Positioned(top: 350, right: 60, child: Icon(Icons.backpack_rounded, size: 30, color: primaryYellow)),
                      Positioned(bottom: 300, left: 100, child: Icon(Icons.palette_rounded, size: 28, color: primaryRed)),
                      Positioned(bottom: 350, right: 120, child: Icon(Icons.calculate_rounded, size: 28, color: primaryYellow)),
                    ],
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: Transform.rotate(
                            angle: _rotateAnimation.value,
                            child: Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Opacity(
                                opacity: _opacityAnimation.value,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: lightRed,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryRed.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Positioned(
                                        bottom: 25,
                                        child: Transform.translate(
                                          offset: Offset(0, _floatAnimation.value * 0.5),
                                          child: Icon(
                                            Icons.backpack_rounded,
                                            size: 50,
                                            color: primaryRed,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 30,
                                        top: 30,
                                        child: Transform.translate(
                                          offset: Offset(_floatAnimation.value * 0.3, -_floatAnimation.value * 0.3),
                                          child: Icon(
                                            Icons.book_rounded,
                                            size: 40,
                                            color: primaryYellow,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 30,
                                        top: 30,
                                        child: Transform.translate(
                                          offset: Offset(-_floatAnimation.value * 0.3, -_floatAnimation.value * 0.3),
                                          child: Icon(
                                            Icons.search_rounded,
                                            size: 40,
                                            color: primaryRed,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Findle',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryRed,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find your lost items with ease.',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 60),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Get Started',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 