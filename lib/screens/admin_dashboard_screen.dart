// ignore_for_file: unused_import

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart'; 

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

  // Helper untuk menampilkan dialog pop-up di tengah layar
  void _tampilkanDialog(String pesan, {bool isBerhasil = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(
              isBerhasil ? Icons.check_circle : Icons.error,
              color: isBerhasil ? Colors.green : Colors.red[800],
            ),
            const SizedBox(width: 10),
            Text(isBerhasil ? 'Berhasil' : 'Peringatan'),
          ],
        ),
        content: Text(pesan, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'OK',
              style: TextStyle(
                color: isBerhasil ? Colors.green : Colors.red[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi Import Cerdas untuk menangani 2 Kategori (Kendaraan & Barang)
  Future<void> _importExcelToFirestore() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'], 
      );

      if (result != null) {
        setState(() => _isImporting = true);
        
        String fileName = result.files.single.name.toLowerCase();
        int totalImported = 0;

        if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
          Uint8List? bytes = result.files.single.bytes ?? await File(result.files.single.path!).readAsBytes();
          var excel = Excel.decodeBytes(bytes);

          for (var table in excel.tables.keys) {
            var sheet = excel.tables[table];
            if (sheet == null) continue;

            String kategoriAktif = 'Peralatan / Barang'; 

            for (var i = 0; i < sheet.maxRows; i++) {
              var row = sheet.rows[i];
              if (row.isEmpty) continue;

              String kolomPertama = row[0]?.value?.toString().trim() ?? '';

              if (kolomPertama.toUpperCase().contains('MOBIL') || kolomPertama.toUpperCase().contains('KENDARAAN')) {
                kategoriAktif = 'Kendaraan';
                continue; 
              } else if (kolomPertama.toUpperCase().contains('PERALATAN') || 
                         kolomPertama.toUpperCase().contains('FIRE HOUSE') || 
                         kolomPertama.toUpperCase().contains('SEBELUMNYA')) {
                kategoriAktif = 'Peralatan';
                continue;
              }

              if (kolomPertama.isEmpty || 
                  kolomPertama.toLowerCase().contains('data eksisting') || 
                  kolomPertama.toLowerCase().contains('tahun') ||
                  kolomPertama.toLowerCase().contains('nama mobil')) {
                continue;
              }

              String namaBarang = kolomPertama;
              
              int jumlah = 0;
              for (var cell in row.reversed) {
                if (cell?.value != null) {
                  int? parsedNum = int.tryParse(cell!.value.toString().trim());
                  if (parsedNum != null && parsedNum >= 0 && parsedNum < 1000) {
                    jumlah = parsedNum;
                    break;
                  }
                }
              }

              if (jumlah == 0 && row.length > 21 && row[21]?.value != null) {
                jumlah = int.tryParse(row[21]!.value.toString().trim()) ?? 1;
              }
              if (jumlah == 0) jumlah = 1; 

              await FirebaseFirestore.instance.collection('gudang_barang').add({
                'nama': namaBarang,
                'kategori': kategoriAktif,
                'jumlah': jumlah,
                'status': 'Baik',
                'imageUrl': '',
                'createdAt': FieldValue.serverTimestamp(),
              });

              totalImported++;
            }
          }
        } 
        else if (fileName.endsWith('.csv')) {
          String content = result.files.single.bytes != null 
              ? utf8.decode(result.files.single.bytes!) 
              : await File(result.files.single.path!).readAsString();

          List<String> lines = content.split(RegExp(r'\r\n|\n|\r'));
          String separator = lines.isNotEmpty && lines[0].contains(';') ? ';' : ',';

          for (var i = 1; i < lines.length; i++) {
            List<String> cols = lines[i].split(separator).map((c) => c.replaceAll('"', '').trim()).toList();
            if (cols.isEmpty || cols[0].isEmpty) continue;

            String namaBarang = cols[0];
            String kategori = cols.length > 1 && cols[1].isNotEmpty ? cols[1] : 'Peralatan';
            int jumlah = cols.length > 2 ? (int.tryParse(cols[2]) ?? 1) : 1;
            String status = cols.length > 3 && cols[3].isNotEmpty ? cols[3] : 'Baik';

            await FirebaseFirestore.instance.collection('gudang_barang').add({
              'nama': namaBarang,
              'kategori': kategori,
              'jumlah': jumlah,
              'status': status,
              'imageUrl': '',
              'createdAt': FieldValue.serverTimestamp(),
            });

            totalImported++;
          }
        }

        if (!mounted) return;
        _tampilkanDialog('Berhasil mengimpor $totalImported data barang sesuai kategori Excel ke Gudang!', isBerhasil: true);
      }
    } catch (e) {
      if (!mounted) return;
      _tampilkanDialog('Gagal mengimpor file.\nDetail Error: $e');
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
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: iconColor.withOpacity(0.3)),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
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
            tooltip: 'Profil Admin',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: _isImporting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(height: 16),
                  Text('Sedang mengimpor data prasarana...\nMohon tunggu.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Menu Kelola Prasarana', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  _buildCompactMenuCard(
                    title: 'Import Data Excel/CSV Prasarana',
                    subtitle: 'Unggah file .xlsx atau .csv master data Damkar',
                    icon: Icons.file_upload,
                    iconColor: Colors.green,
                    bgColor: const Color(0xFFF0FFF0),
                    onTap: _importExcelToFirestore,
                  ),
                  
                  _buildCompactMenuCard(
                    title: 'Tambah Barang Baru',
                    subtitle: 'Input prasarana ke dalam sistem',
                    icon: Icons.add_box,
                    iconColor: Colors.redAccent,
                    bgColor: const Color(0xFFFCF5F5),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TambahBarangScreen())).then((_) => setState(() {})),
                  ),

                  _buildCompactMenuCard(
                    title: 'Gudang Barang',
                    subtitle: 'Lihat stok keseluruhan prasarana',
                    icon: Icons.warehouse,
                    iconColor: Colors.blueAccent,
                    bgColor: const Color(0xFFF0F5FF),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GudangBarangScreen())).then((_) => setState(() {})),
                  ),

                  _buildCompactMenuCard(
                    title: 'Riwayat Transaksi',
                    subtitle: 'Lihat riwayat permintaan yang sudah diproses',
                    icon: Icons.history,
                    iconColor: Colors.green,
                    bgColor: const Color(0xFFF4FAF4),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatAdminScreen())).then((_) => setState(() {})),
                  ),

                  _buildCompactMenuCard(
                    title: 'Permintaan UPT',
                    subtitle: 'Kelola pengajuan masuk dari UPT Damkar',
                    icon: Icons.assignment,
                    iconColor: Colors.redAccent,
                    bgColor: const Color(0xFFFFF5F5), // Diperbaiki langsung menggunakan const Color
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PermintaanUptScreen())).then((_) => setState(() {})),
                  ),

                  _buildCompactMenuCard(
                    title: 'Permintaan Pos',
                    subtitle: 'Kelola pengajuan masuk dari Pos Sektor',
                    icon: Icons.assignment_turned_in,
                    iconColor: Colors.orange,
                    bgColor: const Color(0xFFFFF8F0),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PermintaanPosScreen())).then((_) => setState(() {})),
                  ),

                  _buildCompactMenuCard(
                    title: 'Kerusakan Sedang',
                    subtitle: 'Lihat laporan barang dengan kerusakan sedang',
                    icon: Icons.warning,
                    iconColor: Colors.amber,
                    bgColor: const Color(0xFFFFFDF0),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const KerusakanSedangScreen())).then((_) => setState(() {})),
                  ),

                  _buildCompactMenuCard(
                    title: 'Kerusakan Berat',
                    subtitle: 'Lihat laporan barang dengan kerusakan berat',
                    icon: Icons.dangerous,
                    iconColor: Colors.deepOrange,
                    bgColor: const Color(0xFFFFF3F0),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const KerusakanBeratScreen())).then((_) => setState(() {})),
                  ),
                ],
              ),
            ),
    );
  }
}

