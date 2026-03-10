import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gamma_app/screens/call_listener.dart';
import 'firebase_options.dart';
import 'package:gamma_app/screens/auth_gate.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GammaApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 161, 187, 160), brightness: Brightness.light),
        useMaterial3: true,
        textTheme: TextTheme(
          titleLarge: GoogleFonts.montserrat(
            fontSize: 30,
            fontWeight: FontWeight.w600
          ),
          displayLarge: GoogleFonts.montserrat(
            fontSize: 60,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold
          ),
          bodyMedium: GoogleFonts.merriweather(),
          displaySmall: GoogleFonts.pacifico(),
          labelMedium: GoogleFonts.actor(
            fontSize: 15,
            fontStyle: FontStyle.italic
          )
        )
      ),
      home: const GlobalCallListener(
        child: AuthGate()
        ),
  
      debugShowCheckedModeBanner: false,
    );
  }
}
