import 'package:flutter/material.dart';
import 'screens/auth_screens.dart';

// ==========================================
// CONFIGURACIÓN GLOBAL DE RED
// ==========================================
const String ipServidor = '100.56.40.83'; 
const String apiUrlTours = 'http://$ipServidor:8000/api/tours/';
const String apiUrlReservas = 'http://$ipServidor:8000/api/reservas/';
const String apiUrlUsuarios = 'http://$ipServidor:8000/api/usuarios/';

void main() {
  runApp(const TurismoApp());
}

class TurismoApp extends StatelessWidget {
  const TurismoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TalcaTravel Tech',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), 
          primary: const Color(0xFF0F172A), 
          secondary: const Color(0xFF059669), 
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        cardTheme: CardTheme(
          elevation: 3,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
      ),
      home: const LoginScreen(), // Inicia en el Login
    );
  }
}