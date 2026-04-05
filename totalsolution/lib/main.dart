// Main entry point for Total Solution - Distributor Salesman Order Management System

import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Total Solution',
      theme: ThemeData(
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFF1A3B70),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A3B70),
          primary: const Color(0xFF1A3B70),
          secondary: const Color(0xFF00A68A),
        ),
        useMaterial3: true,
      ),
      home: LoginScreen(),
    );
  }
}
