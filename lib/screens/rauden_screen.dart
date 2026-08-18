import 'package:flutter/material.dart';
// Pastikan file tambah_barang_screen.dart berada di folder yang sama 
// atau sesuaikan path import-nya jika berbeda.
import 'tambah_barang_screen.dart'; 

class RaudenScreen extends StatelessWidget {
  final String role; // Menerima data role dari Dashboard (misal: 'Admin' atau 'UPT')

  const RaudenScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    // ==========================================
    // TAMPILAN UNTUK ADMIN (KASI PRASARANA)
    // ==========================================
    if (role == 'Admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kelola Barang - Admin'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'Daftar Permintaan dari UPT',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            // Contoh list permintaan (nantinya diambil dari database)
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.assignment_late, color: Colors.red),
                title: const Text('Permintaan: Selang Pemadam 2.5 Inch'),
                subtitle: const Text('Dari: UPT Wilayah 1\nStatus: Menunggu'),
                isThreeLine: true,
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // TODO: Aksi untuk menyetujui permintaan dan update status di database
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Permintaan sedang diproses...')),
                    );
                  },
                  child: const Text('Proses'),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // Navigasi ke form Tambah Barang untuk Admin
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TambahBarangScreen(),
              ),
            );
          },
          backgroundColor: Colors.red,
          icon: const Icon(Icons.add_box, color: Colors.white),
          label: const Text('Input Barang', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    // ==========================================
    // TAMPILAN UNTUK UPT / PELANGGAN
    // ==========================================
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Barang - UPT'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Text(
            'Riwayat Permintaan Saya',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          
          // Contoh list riwayat (nantinya diambil dari database)
          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.history, color: Colors.grey),
              title: Text('Permintaan: APD Helm Pemadam'),
              subtitle: Text('Tanggal: 10 Agustus 2026'),
              trailing: Text(
                'Disetujui',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Buka form pengajuan permintaan barang baru untuk UPT ke Admin
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Form pengajuan belum tersedia.')),
          );
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.send, color: Colors.white),
        label: const Text('Buat Permintaan', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}