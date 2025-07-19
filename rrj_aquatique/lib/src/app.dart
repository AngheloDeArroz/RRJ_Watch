import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'ui/screens/dashboard_screen.dart';

class RRJAquatiqueApp extends StatelessWidget {
  const RRJAquatiqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RRJ Aquatique',
      theme: rrjAquatiqueTheme,
      debugShowCheckedModeBanner: false,
      home: const DashboardScreen(),
    );
  }
}
