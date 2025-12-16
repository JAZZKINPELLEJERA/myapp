
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tindahance/screens/login_screen.dart';
import 'package:tindahance/screens/signup_screen.dart';
import 'package:tindahance/screens/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainScreen(),
    ),
  ],
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final user = FirebaseAuth.instance.currentUser;

    // If the user is logged in and is trying to access the login/signup page,
    // redirect them to the main screen.
    if (isLoggedIn && user != null && (state.uri.toString() == '/' || state.uri.toString() == '/signup')) {
      return '/main';
    }
    // If the user is not logged in and is trying to access a protected page,
    // redirect them to the login screen.
    if (!isLoggedIn && user == null && state.uri.toString() != '/' && state.uri.toString() != '/signup') {
      return '/';
    }
    return null; // No redirect needed
  },
);
