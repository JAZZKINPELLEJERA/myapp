
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        final user = await _auth.signUp(
          _emailController.text,
          _passwordController.text,
          _storeNameController.text,
          _ownerNameController.text,
        );
        if (user != null && mounted) {
          context.go('/home');
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          _errorMessage = 'This email is already registered. Please log in.';
        } else if (e.code == 'weak-password') {
          _errorMessage = 'The password is too weak. Please choose a stronger one.';
        } else {
          _errorMessage = 'An error occurred. Please try again later.';
        }
      } catch (e) {
        _errorMessage = 'An unexpected error occurred.';
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[400],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              margin: const EdgeInsets.symmetric(horizontal: 24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10.0,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create Your Account',
                      style: GoogleFonts.poppins(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[400],
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    _buildTextField(
                      controller: _storeNameController,
                      labelText: 'Store Name',
                      prefixIcon: Icons.store_outlined,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your store name' : null,
                    ),
                    const SizedBox(height: 16.0),
                    _buildTextField(
                      controller: _ownerNameController,
                      labelText: 'Owner Name',
                      prefixIcon: Icons.person_outline,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter the owner\'s name' : null,
                    ),
                    const SizedBox(height: 16.0),
                    _buildEmailField(),
                    const SizedBox(height: 16.0),
                    _buildPasswordField(),
                    const SizedBox(height: 16.0),
                    _buildConfirmPasswordField(),
                    const SizedBox(height: 24.0),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal[400],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                            ),
                            child: const Center(
                              child: Text(
                                'Sign up',
                                style: TextStyle(color: Colors.white, fontSize: 16.0),
                              ),
                            ),
                          ),
                    const SizedBox(height: 16.0),
                    GestureDetector(
                      onTap: () => context.go('/'),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: const TextStyle(color: Colors.black87, fontFamily: 'Poppins'),
                          children: [
                            TextSpan(
                              text: 'Log in',
                              style: TextStyle(color: Colors.teal[400], fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, color: Colors.black87),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.teal[400]!, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      validator: validator,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: const Icon(Icons.email_outlined, color: Colors.black87),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.teal[400]!, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.black87),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.black87,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.teal[400]!, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.black87),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.teal[400]!, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }
}
