
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('rememberedEmail');
      if (email != null) {
        setState(() {
          _emailController.text = email;
          _rememberMe = true;
        });
      }
    } catch (e) {
      // Handle exceptions
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        final user = await _auth.signIn(
          _emailController.text,
          _passwordController.text,
        );
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          if (_rememberMe) {
            await prefs.setString('rememberedEmail', _emailController.text);
          } else {
            await prefs.remove('rememberedEmail');
          }
          if (mounted) {
            context.go('/main');
          }
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _errorMessage = 'Invalid email or password. Please try again.';
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
                      'TINDAHANCE',
                      style: GoogleFonts.poppins(
                        fontSize: 24.0,
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
                    _buildEmailField(),
                    const SizedBox(height: 16.0),
                    _buildPasswordField(),
                    const SizedBox(height: 16.0),
                    _buildRememberMeCheckbox(),
                    const SizedBox(height: 24.0),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal[400],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                            ),
                            child: const Center(
                              child: Text(
                                'Log in',
                                style: TextStyle(color: Colors.white, fontSize: 16.0),
                              ),
                            ),
                          ),
                    const SizedBox(height: 16.0),
                    GestureDetector(
                      onTap: () => context.go('/signup'),
                      child: RichText(
                        text: TextSpan(
                          text: 'Don\'t have an account? ',
                          style: const TextStyle(color: Colors.black87, fontFamily: 'Poppins'),
                          children: [
                            TextSpan(
                              text: 'Sign up',
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
        if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
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
        return null;
      },
    );
  }

  Widget _buildRememberMeCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value!;
            });
          },
          activeColor: Colors.teal[400],
        ),
        const Text('Remember Me'),
      ],
    );
  }
}
