import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'src/ui/screens/splash_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => FirestoreService()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(), 
      ),
    ),
  );
}
