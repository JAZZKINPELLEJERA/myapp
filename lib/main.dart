
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tindahance/router/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TINDAHANCE',
      theme: ThemeData(
        primaryColor: const Color(0xFF1ABC9C),
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: const Color(0xFF2C3E50)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          labelStyle: TextStyle(color: Colors.grey[600]),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: const Color(0xFF2ECC71)),
      ),
      routerConfig: router,
    );
  }
}
