import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

import 'admin_profile_screen.dart'; 
import 'tambah_barang_screen.dart';
import 'gudang_barang_screen.dart';
import 'riwayat_admin_screen.dart';
import 'permintaan_upt_screen.dart';
import 'permintaan_pos_screen.dart';
import 'kerusakan_sedang_screen.dart';
import 'kerusakan_berat_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isImporting = false;

  void _logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _tampilkanDialog(String pesan, {bool isBerhasil = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(isBerhasil ? Icons.check_circle : Icons.error, color: isBerhasil ? Colors.green : Colors.red[800]),
            const SizedBox(width: 10),
            Text(isBerhasil ? 'Berhasil' : 'Peringatan'),
          ],
        ),
        content: Text(pesan, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _importDataToFirestore() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, 
        allowedExtensions: ['csv'] 
      );
      
      if (result == null) return;
      
      setState(() => _isImporting = true);
      int totalImported = 0;

      String content = result.files.single.bytes != null 
          ? utf8.decode(result.files.single.bytes!) 
          : await File(result.files.single.path!).readAsString();

      List<String> lines = content.split(RegExp(r'\r\n|\n|\r'));
      String separator = lines.isNotEmpty && lines[0].contains(';') ? ';' : ',';
      
      bool isDataMobil = content.toLowerCase().contains('jenis kendaraan') && content.toLowerCase().contains('nomor kendaraan');

      if (isDataMobil) {
        for (var i = 1; i < lines.length; i++) {
          List<String> cols = lines[i].split(separator).map((c) => c.replaceAll('"', '').trim()).toList();
          
          if (cols.length < 2) continue;
          String nama = cols[1]; 

          if (nama.isEmpty || nama.toLowerCase().contains('jenis kendaraan')) continue;

          Map<String, dynamic> dataUpload = {
            'nama': nama,
            'kategori': 'Kendaraan',
            'jumlah': 1,
            'status': cols.length > 5 && cols[5].isNotEmpty ? cols[5] : 'Baik',
            'Merk / Tipe': cols.length > 2 && cols[2].isNotEmpty ? cols[2] : '-',
            'Tahun Pembuatan': cols.length > 3 && cols[3].isNotEmpty ? cols[3] : '-',
            'Tahun Perolehan': cols.length > 4 && cols[4].isNotEmpty ? cols[4] : '-',
            'Nomor Kendaraan': cols.length > 6 && cols[6].isNotEmpty ? cols[6] : '-',
            'Keterangan': cols.length > 7 && cols[7].isNotEmpty ? cols[7] : '-',
            'createdAt': FieldValue.serverTimestamp(),
          };

          await FirebaseFirestore.instance.collection('gudang_barang').add(dataUpload);
          totalImported++;
        }
      } else {
        String kategoriAktif = 'Peralatan Umum';
        String namaIndukBarang = '';

        for (var i = 1; i < lines.length; i++) {
          List<String> cols = lines[i].split(separator).map((c) => c.replaceAll('"', '').trim()).toList();
          if (cols.isEmpty || cols[0].isEmpty) continue;

          String namaMentah = cols[0];

          if (namaMentah.toLowerCase().contains('data eksisting') || 
              namaMentah.toLowerCase().contains('tahun') || 
              namaMentah.toLowerCase().contains('nama mobil') ||
              namaMentah.toLowerCase().contains('mako/bkpp') ||
              namaMentah.length <= 1) {
            continue;
          }

          if (namaMentah == namaMentah.toUpperCase() && !namaMentah.toUpperCase().contains('UKURAN') && namaMentah.length > 3) {
            kategoriAktif = namaMentah; 
            continue; 
          }

          int jumlah = 0;
          for (int c = cols.length - 1; c >= 1; c--) {
            if (cols[c].isNotEmpty) {
              int? parsedNum = int.tryParse(cols[c].replaceAll(RegExp(r'[^0-9]'), '')); 
              if (parsedNum != null && parsedNum > 0 && parsedNum < 5000 && parsedNum != 2026) {
                jumlah = parsedNum;
                break;
              }
            }
          }
          
          if (jumlah == 0 && !namaMentah.toLowerCase().contains('ukuran')) {
            namaIndukBarang = namaMentah; 
            continue; 
          }

          String namaFinal = namaMentah;
          if (namaMentah.toLowerCase().startsWith('ukuran') && namaIndukBarang.isNotEmpty) {
             namaFinal = '$namaIndukBarang - $namaMentah';
          }
          if (jumlah == 0) jumlah = 1;

          Map<String, dynamic> detailLokasi = {};
          if (cols.length > 1 && cols[1].isNotEmpty) detailLokasi['Pos Mako/BKPP'] = '${cols[1]} Unit/Buah';
          if (cols.length > 5 && cols[5].isNotEmpty) detailLokasi['Pos Limbangan'] = '${cols[5]} Unit/Buah';
          if (cols.length > 7 && cols[7].isNotEmpty) detailLokasi['Pos Pameungpeuk'] = '${cols[7]} Unit/Buah';
          if (cols.length > 9 && cols[9].isNotEmpty) detailLokasi['Pos Bungbulang'] = '${cols[9]} Unit/Buah';
          if (cols.length > 11 && cols[11].isNotEmpty) detailLokasi['Pos Leles'] = '${cols[11]} Unit/Buah';
          if (cols.length > 13 && cols[13].isNotEmpty) detailLokasi['Pos Cikajang'] = '${cols[13]} Unit/Buah';
          if (cols.length > 15 && cols[15].isNotEmpty) detailLokasi['Pos Malangbong'] = '${cols[15]} Unit/Buah';
          if (cols.length > 17 && cols[17].isNotEmpty) detailLokasi['Pos Singajaya'] = '${cols[17]} Unit/Buah';
          if (cols.length > 19 && cols[19].isNotEmpty) detailLokasi['Pos Pangatkan'] = '${cols[19]} Unit/Buah';

          Map<String, dynamic> dataUpload = {
            'nama': namaFinal,
            'kategori': kategoriAktif,
            'jumlah': jumlah,
            'status': 'Baik',
            'createdAt': FieldValue.serverTimestamp(),
          };
          dataUpload.addAll(detailLokasi);

          await FirebaseFirestore.instance.collection('gudang_barang').add(dataUpload);
          totalImported++;
        }
      }

      if (!mounted) return;
      _tampilkanDialog('Berhasil mengimpor $totalImported data dengan sangat rapi!', isBerhasil: true);
    } catch (e) {
      if (mounted) _tampilkanDialog('Gagal mengimpor file. Pastikan file berformat CSV UTF-8.\nDetail Error: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Widget _buildCompactMenuCard({
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color iconColor, 
    required Color bgColor, 
    required VoidCallback onTap
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), 
        side: BorderSide(color: iconColor.withOpacity(0.3))
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10), 
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15), 
                  borderRadius: BorderRadius.circular(8)
                ), 
                child: Icon(icon, color: iconColor, size: 26)
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), 
                    const SizedBox(height: 4), 
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12))
                  ]
                )
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Dashboard Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle), 
            tooltip: 'Profil', 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen()))
          ),
          IconButton(
            icon: const Icon(Icons.logout), 
            tooltip: 'Keluar', 
            onPressed: () => _logout(context)
          ),
        ],
      ),
      body: _isImporting 
        ? const Center(child: CircularProgressIndicator(color: Colors.red))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildCompactMenuCard(title: 'Import File CSV', subtitle: 'Impor master data Damkar', icon: Icons.file_upload, iconColor: Colors.green, bgColor: const Color(0xFFF0FFF0), onTap: _importDataToFirestore),
                _buildCompactMenuCard(title: 'Tambah Barang', subtitle: 'Input manual', icon: Icons.add_box, iconColor: Colors.redAccent, bgColor: const Color(0xFFFCF5F5), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TambahBarangScreen()))),
                _buildCompactMenuCard(title: 'Gudang Barang', subtitle: 'Lihat data stok', icon: Icons.warehouse, iconColor: Colors.blueAccent, bgColor: const Color(0xFFF0F5FF), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GudangBarangScreen()))),
                _buildCompactMenuCard(title: 'Riwayat Transaksi', subtitle: 'Log aktivitas', icon: Icons.history, iconColor: Colors.green, bgColor: const Color(0xFFF4FAF4), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatAdminScreen()))),
                _buildCompactMenuCard(title: 'Permintaan UPT', subtitle: 'Kelola pengajuan UPT', icon: Icons.assignment, iconColor: Colors.redAccent, bgColor: const Color(0xFFFFF5F5), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PermintaanUptScreen()))),
                _buildCompactMenuCard(title: 'Permintaan Pos', subtitle: 'Kelola pengajuan Pos', icon: Icons.assignment_turned_in, iconColor: Colors.orange, bgColor: const Color(0xFFFFF8F0), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PermintaanPosScreen()))),
                _buildCompactMenuCard(title: 'Kerusakan Sedang', subtitle: 'Data kerusakan sedang', icon: Icons.warning, iconColor: Colors.amber, bgColor: const Color(0xFFFFFDF0), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KerusakanSedangScreen()))),
                _buildCompactMenuCard(title: 'Kerusakan Berat', subtitle: 'Data kerusakan berat', icon: Icons.dangerous, iconColor: Colors.deepOrange, bgColor: const Color(0xFFFFF3F0), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KerusakanBeratScreen()))),
              ],
            ),
          ),
    );
  }
}