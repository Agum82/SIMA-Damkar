import 'package:flutter/material.dart';
import 'rauden_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String role; // Menerima data role dari halaman Login
  
  const DashboardScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Operasional'),
        centerTitle: true,
        backgroundColor: Colors.red, // Disamakan dengan tema Damkar
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar Akun',
            onPressed: () {
              // Menghapus semua riwayat halaman dan kembali ke Login
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/login', 
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            
            // Menampilkan siapa yang sedang login
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'Selamat datang, Hak Akses: $role',
                style: const TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            
            // Tombol Menuju Modul Rauden
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RaudenScreen(role: role),
                  ),
                );
              },
              icon: const Icon(Icons.fire_truck, size: 30),
              label: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Kelola Modul Rauden', style: TextStyle(fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            
            // TODO: Kamu bisa menambahkan tombol modul lain di bawah sini jika diperlukan nanti
          ],
        ),
      ),
    );
  }
}