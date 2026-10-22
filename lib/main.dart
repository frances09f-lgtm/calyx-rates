import 'package:flutter/material.dart';

import 'api/calyx_api.dart';
import 'screens/login_screen.dart';

void main() => runApp(const CalyxRatesApp());

class CalyxRatesApp extends StatelessWidget {
  const CalyxRatesApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF006B5E);
    return MaterialApp(
      title: 'Calyx Rates',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: seed, brightness: Brightness.dark),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      home: LoginScreen(api: CalyxApi()),
    );
  }
}
