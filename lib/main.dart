import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import core Firebase
import 'firebase_options.dart'; // Import konfigurasi otomatis dari FlutterFire CLI
import 'package:local_notifier/local_notifier.dart'; // <-- TAMBAHAN UNTUK NOTIFIKASI WINDOWS

import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/upt_dashboard_screen.dart';
import 'screens/register_screen.dart';

// Ubah fungsi main menjadi asynchronous (async)
void main() async {
  // Wajib ditambahkan: Memastikan binding Flutter sudah siap sebelum inisialisasi Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Mengaktifkan dan menghubungkan Firebase ke aplikasi sesuai platform
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // <-- TAMBAHAN INISIALISASI NOTIFIKASI WINDOWS -->
  await localNotifier.setup(
    appName: 'SIMA DAmkar', // Nama aplikasi yang akan muncul di pop-up Windows
    shortcutPolicy: ShortcutPolicy.requireCreate,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistem Operasional Rauden',
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug di pojok kanan atas
      theme: ThemeData(
        // Menggunakan standar Material 3 terbaru dari Flutter
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true, 
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const AdminDashboardScreen(), // Ditambahkan sebagai alias tujuan login
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/upt-dashboard': (context) => const UptDashboardScreen(), 
      },
    );
  }
}