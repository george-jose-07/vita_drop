import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:vita_drop/screens/dashboard/home_screen.dart';
import 'package:vita_drop/splashscreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vita_drop/start_page.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.8; // 80% of screen width

    return MaterialApp(
      title: 'VitaDrop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF627D98), // Deep Mauve
          secondary: const Color(0xFFFFD28E), // Apricot
          surface: const Color(0xFFFFF7E6), // Ivory Warm
        ),
        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          headlineLarge: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w300,
            color: Colors.black87,
            letterSpacing: 2,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const Startpage();
        },
      ),
    );
  }
}