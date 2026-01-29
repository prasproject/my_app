import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'loginpage.dart';

// ============================================
// FILE UTAMA APLIKASI
// ============================================
// File ini adalah entry point aplikasi Flutter
// MaterialApp adalah widget root yang mengatur tema dan routing aplikasi
Future<void> main() async {
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
    return MaterialApp(
      title: 'Todo List Apps',
      debugShowCheckedModeBanner: false, // Sembunyikan banner debug
      theme: ThemeData(
        // Tema aplikasi dengan warna dasar
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Set halaman awal ke LoginPage
      // User akan melihat halaman login saat pertama kali membuka aplikasi
      home: const LoginPage(),
    );
  }
}
