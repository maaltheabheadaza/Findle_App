import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart'; // Import LoginScreen

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _formErrorMessage;

  // Add per-field error messages
  String? _emailError;
  String? _usernameError;
  String? _passwordError;
  String? _confirmPasswordError;

  // Define colors as class fields
  final Color primaryRed = const Color.fromRGBO(112, 1, 0, 1);
  final Color primaryYellow = const Color.fromRGBO(246, 196, 1, 1);
  final Color white = const Color(0xFFF3F3F3);
  final Color lightRed = const Color.fromRGBO(112, 1, 0, 0.1);
  final Color textColor = const Color.fromRGBO(51, 51, 51, 1);
  final Color hintColor = const Color.fromRGBO(153, 153, 153, 1);

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearEmailError);
    _usernameController.addListener(_clearUsernameError);
    _passwordController.addListener(_clearPasswordError);
    _confirmPasswordController.addListener(_clearConfirmPasswordError);
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearEmailError);
    _usernameController.removeListener(_clearUsernameError);
    _passwordController.removeListener(_clearPasswordError);
    _confirmPasswordController.removeListener(_clearConfirmPasswordError);
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearEmailError() {
    if (_emailError != null) {
      setState(() {
        _emailError = null;
      });
    }
  }

  void _clearUsernameError() {
    if (_usernameError != null) {
      setState(() {
        _usernameError = null;
      });
    }
  }

  void _clearPasswordError() {
    if (_passwordError != null) {
      setState(() {
        _passwordError = null;
      });
    }
  }

  void _clearConfirmPasswordError() {
    if (_confirmPasswordError != null) {
      setState(() {
        _confirmPasswordError = null;
      });
    }
  }

  Future<void> _validateAndSubmit() async {
    setState(() {
      _emailError = null;
      _usernameError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _formErrorMessage = null;
    });

    bool allEmpty = _emailController.text.isEmpty &&
        _usernameController.text.isEmpty &&
        _passwordController.text.isEmpty &&
        _confirmPasswordController.text.isEmpty;

    if (allEmpty) {
      setState(() {
        _formErrorMessage = 'All of the fields are required to fill in.';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _formErrorMessage != null) {
          setState(() {
            _formErrorMessage = null;
          });
        }
      });
      return;
    }

    bool hasError = false;

    // Email validation
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _emailError = 'This field is required';
      hasError = true;
    } else if (!email.contains('@')) {
      _emailError = "Email must contain '@'";
      _emailController.clear();
      hasError = true;
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _emailError = 'Please enter a valid email address';
      _emailController.clear();
      hasError = true;
    }

    // Username validation
    if (_usernameController.text.trim().isEmpty) {
      _usernameError = 'This field is required';
      hasError = true;
    }

    // Password validation
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      _passwordError = 'This field is required';
      hasError = true;
    } else {
      final hasUppercase = password.contains(RegExp(r'[A-Z]'));
      final hasNumber = password.contains(RegExp(r'[0-9]'));
      final hasSymbol = password.contains(RegExp(r'[!@#\$%^&*(),_.?":{}|<>]'));

      if (!hasUppercase || !hasNumber || !hasSymbol) {
        _passwordError = 'Password must include an uppercase letter, a number, and a symbol';
        hasError = true;
      }
    }

    // Confirm password validation
    final confirmPassword = _confirmPasswordController.text;
    if (confirmPassword.isEmpty) {
      _confirmPasswordError = 'This field is required';
      hasError = true;
    } else if (confirmPassword != password) {
      _confirmPasswordError = "Passwords don't match";
      hasError = true;
    }

    if (hasError) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Attempt to sign up the user
      final authResponse = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'username': _usernameController.text.trim(),
        },
      );

      if (authResponse.user != null) {
        print('✅ User created with ID: ${authResponse.user!.id}');
        
        // Show success dialog
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: primaryRed, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Registration Successful!\nPlease check your email to confirm your account.',
                    style: GoogleFonts.poppins(
                      color: primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop(); // Close dialog
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      child: Text(
                        'OK',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
         // Handle cases where user is null but no exception was thrown (shouldn't happen with signUp usually)
         print('⚠️ Signup returned null user.');
         setState(() {
           _formErrorMessage = 'Registration failed unexpectedly.';
         });
      }

    } on AuthException catch (error) {
      print('❌ Supabase Auth error: ${error.message}');
      if (mounted) {
        if (error.message.contains('already registered') || error.message.contains('exists')) {
          setState(() {
            _emailError = 'Email is already in use.';
            _formErrorMessage = null; // Clear form error if email error is shown
          });
        } else {
          setState(() {
            _formErrorMessage = 'Registration failed: ${error.message}';
             _emailError = null; // Clear email error if form error is shown
          });
        }
      }
    } catch (error) {
      print('❌ Generic registration error: $error');
      if (mounted) {
        setState(() {
          _formErrorMessage = 'An unexpected error occurred. Please try again.';
           _emailError = null; // Clear email error if form error is shown
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _getInputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: GoogleFonts.poppins(
        color: hintColor.withValues(alpha: 0.7 * 255),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.poppins(
        color: hintColor.withValues(alpha: 0.7 * 255),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: primaryRed, size: 20),
      filled: true,
      fillColor: white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.blueGrey.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.blueGrey.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.blueGrey, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.blueGrey.withOpacity(0.5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.blueGrey, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: Container(
        // Change background to grayish
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
                      // ...add more for density if needed
                    ],
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cute Logo and Title (reuse from AuthScreen if needed)
                      Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        child: Column(
                          children: [
                            // Animated logo
                            AnimatedLogo(
                              primaryRed: primaryRed,
                              primaryYellow: primaryYellow,
                              lightRed: lightRed,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Findle',
                              style: GoogleFonts.poppins(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: primaryRed,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lost it? Don\'t worry, just Findle it!',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_formErrorMessage != null) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: primaryRed.withValues(alpha: 0.5 * 255)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline, color: primaryRed),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _formErrorMessage!,
                                          style: GoogleFonts.poppins(
                                            color: primaryRed,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // Email error
                              if (_emailError != null) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    _emailError!,
                                    style: GoogleFonts.poppins(
                                      color: primaryRed,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                              TextFormField(
                                controller: _emailController,
                                decoration: _getInputDecoration(
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  hintText: 'Enter your email address',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.poppins(
                                  color: textColor,
                                  fontSize: 14,
                                ),
                                onChanged: (value) {
                                  // Trigger validation on change to provide immediate feedback
                                  _formKey.currentState?.validate();
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'This field is required';
                                  }
                                  // Basic email format validation
                                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Username error
                              if (_usernameError != null) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    _usernameError!,
                                    style: GoogleFonts.poppins(
                                      color: primaryRed,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                              TextFormField(
                                controller: _usernameController,
                                decoration: _getInputDecoration(
                                  label: 'Username',
                                  icon: Icons.person_outline,
                                  hintText: 'Choose a username',
                                ),
                                style: GoogleFonts.poppins(
                                  color: textColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Password error
                              if (_passwordError != null) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    _passwordError!,
                                    style: GoogleFonts.poppins(
                                      color: primaryRed,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                              TextFormField(
                                controller: _passwordController,
                                decoration: _getInputDecoration(
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  hintText: 'Enter your password',
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showPassword ? Icons.visibility : Icons.visibility_off,
                                      color: primaryRed,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showPassword = !_showPassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !_showPassword,
                                style: GoogleFonts.poppins(
                                  color: textColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Confirm password error
                              if (_confirmPasswordError != null) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    _confirmPasswordError!,
                                    style: GoogleFonts.poppins(
                                      color: primaryRed,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: _getInputDecoration(
                                  label: 'Confirm Password',
                                  icon: Icons.lock_outline,
                                  hintText: 'Confirm your password',
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                      color: primaryRed,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showConfirmPassword = !_showConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !_showConfirmPassword,
                                style: GoogleFonts.poppins(
                                  color: textColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _validateAndSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryRed,
                                  foregroundColor: white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Create account',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: Text(
                                  'Already have an account? Sign in',
                                  style: GoogleFonts.poppins(
                                    color: primaryRed,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// AnimatedLogo widget for animated logo symbols
class AnimatedLogo extends StatefulWidget {
  final Color primaryRed;
  final Color primaryYellow;
  final Color lightRed;
  const AnimatedLogo({
    super.key,
    required this.primaryRed,
    required this.primaryYellow,
    required this.lightRed,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bookRotation;
  late Animation<double> _searchRotation;
  late Animation<double> _backpackOffset;
  late Animation<double> _bookOffset;
  late Animation<double> _searchOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _bookRotation = Tween<double>(begin: -0.2, end: -0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _searchRotation = Tween<double>(begin: 0.2, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _backpackOffset = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _bookOffset = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _searchOffset = Tween<double>(begin: 0, end: -8).animate(
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: widget.lightRed,
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 20 + _backpackOffset.value,
                child: Icon(
                  Icons.backpack_rounded,
                  size: 40,
                  color: widget.primaryRed,
                ),
              ),
              Positioned(
                right: 25,
                top: 25 + _bookOffset.value,
                child: Transform.rotate(
                  angle: _bookRotation.value,
                  child: Icon(
                    Icons.book_rounded,
                    size: 30,
                    color: widget.primaryYellow,
                  ),
                ),
              ),
              Positioned(
                left: 25,
                top: 25 + _searchOffset.value,
                child: Transform.rotate(
                  angle: _searchRotation.value,
                  child: Icon(
                    Icons.search_rounded,
                    size: 30,
                    color: widget.primaryRed,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}