
import 'package:go_router/go_router.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/signup_screen.dart';
import 'package:myapp/screens/main_screen.dart';

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
);
