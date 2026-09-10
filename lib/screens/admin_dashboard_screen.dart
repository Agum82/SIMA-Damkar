import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
  final User? user = FirebaseAuth.instance.currentUser;
  
  String _photoUrl = '';

  @override
  void initState() {
    super.initState();
    _ambilDataProfilAdmin();
  }

  Future<void> _ambilDataProfilAdmin() async {
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _photoUrl = data['photoUrl'] ?? '';
            });
          }
        }
      } catch (e) {
        // Abaikan error jaringan
      }
    }
  }

  ImageProvider? _getAvatarImage() {
    if (_photoUrl.isEmpty) return null;
    
    if (_photoUrl.startsWith('http')) {
      return NetworkImage(_photoUrl);
    } 
    
    try {
      Uint8List decodedBytes = base64Decode(_photoUrl);
      return MemoryImage(decodedBytes);
    } catch (e) {
      return null;
    }
  }

  // Fungsi Cetak PDF dari Dashboard Admin dengan Perhitungan Sisa Stok Akurat (Tanpa Mengurangi Pengadaan)
  Future<void> _cetakPdfDariDashboard() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.red),
      ),
    );

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('gudang_barang').orderBy('createdAt', descending: true).get();
      List<QueryDocumentSnapshot> docs = snapshot.docs;

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading

      if (docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data barang di gudang untuk dicetak!'), backgroundColor: Colors.orange),
        );
        return;
      }

      final pdf = pw.Document();

      Set<String> dynamicKeys = {};
      List<Map<String, dynamic>> parsedDataList = [];
      List<String> excludeKeys = ['nama', 'kategori', 'jumlah', 'harga', 'status', 'imageurl', 'createdat', 'updatedat', 'detail', 'merk / tipe', 'nomor kendaraan', 'sisa'];

      for (var doc in docs) {
        var data = doc.data() as Map<String, dynamic>;
        parsedDataList.add(data);
        data.forEach((key, value) {
          if (!excludeKeys.contains(key.toLowerCase()) && value != null && value.toString().isNotEmpty && value.toString() != '-') {
            dynamicKeys.add(key);
          }
        });
      }

      List<String> sortedKeys = dynamicKeys.toList()..sort();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('PEMADAM KEBAKARAN KABUPATEN GARUT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('Laporan Keseluruhan Stok Gudang & Penempatan Prasarana', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              pw.SizedBox(height: 10),
            ],
          ),
          build: (context) {
            List<String> headers = ['No', 'Nama Barang', 'Kategori', 'Jumlah Stok', 'Status'];
            for (var key in sortedKeys) {
              String formattedKey = key[0].toUpperCase() + key.substring(1);
              headers.add(formattedKey);
            }
            // Tambahkan Kolom Sisa di Paling Ujung Kanan
            headers.add('Sisa');

            List<List<String>> rows = [];
            for (int i = 0; i < parsedDataList.length; i++) {
              var data = parsedDataList[i];
              
              String statusAsli = data['status']?.toString() ?? 'Tersedia';
              if (statusAsli.toLowerCase() == 'baik') {
                statusAsli = 'Tersedia';
              }

              int totalAwal = data['jumlah'] ?? 0;
              int totalKeluar = 0;

              List<String> row = [
                '${i + 1}',
                data['nama']?.toString() ?? '-',
                data['kategori']?.toString() ?? '-',
                '$totalAwal Unit',
                statusAsli,
              ];

              for (var key in sortedKeys) {
                String val = data[key]?.toString() ?? '-';
                String lowerKey = key.toLowerCase();
                
                // PENTING: Jangan kurangi stok jika kolom mengandung kata 'pengadaan'
                if (val != '-' && val.isNotEmpty && !lowerKey.contains('pengadaan')) {
                  totalKeluar += int.tryParse(val) ?? 0;
                }
                row.add(val);
              }

              int sisaStok = totalAwal - totalKeluar;
              if (sisaStok < 0) sisaStok = 0;

              // Masukkan nilai Sisa yang akurat ke kolom terakhir
              row.add('$sisaStok');
              rows.add(row);
            }

            Map<int, pw.TableColumnWidth> customColumnWidths = {
              0: const pw.FixedColumnWidth(25),  // Kolom No
              1: const pw.FixedColumnWidth(100), // Kolom Nama Barang
              2: const pw.FixedColumnWidth(70),  // Kolom Kategori
              3: const pw.FixedColumnWidth(50),  // Kolom Jumlah Stok
              4: const pw.FixedColumnWidth(50),  // Kolom Status
            };
            
            for (int i = 5; i < headers.length - 1; i++) {
              customColumnWidths[i] = const pw.FixedColumnWidth(40);
            }
            customColumnWidths[headers.length - 1] = const pw.FixedColumnWidth(40);

            return [
              pw.Table.fromTextArray(
                headers: headers,
                data: rows,
                columnWidths: customColumnWidths,
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFB71C1C)),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              ),
            ];
          },
          footer: (context) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Dicetak otomatis dari Sistem SIMA Damkar', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
              pw.Text('Halaman ${context.pageNumber} dari ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
            ],
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Laporan_Gudang_Damkar_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencetak laporan: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Dashboard Admin'),
        centerTitle: true,
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        actions: [
          // TOMBOL PROFIL ADMIN DENGAN FOTO DINAMIS
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminProfileScreen()),
              );
              _ambilDataProfilAdmin(); 
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white24,
                backgroundImage: _getAvatarImage(),
                child: _getAvatarImage() == null ? const Icon(Icons.account_circle, color: Colors.white) : null,
              ),
            ),
          ),
          // TOMBOL LOGOUT
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar Akun',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 1,
            color: const Color(0xFFFAF0FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              onTap: _cetakPdfDariDashboard,
              leading: CircleAvatar(backgroundColor: Colors.purple.withOpacity(0.2), child: const Icon(Icons.print, color: Colors.purple)),
              title: const Text('Cetak Laporan Gudang', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Print / Export PDF seluruh barang', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 1,
            color: const Color(0xFFFCF5F5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TambahBarangScreen())),
              leading: CircleAvatar(backgroundColor: Colors.red.withOpacity(0.2), child: const Icon(Icons.add, color: Colors.redAccent)),
              title: const Text('Tambah Barang', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Input manual', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 1,
            color: const Color(0xFFF0F5FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GudangBarangScreen())),
              leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.2), child: const Icon(Icons.home, color: Colors.blueAccent)),
              title: const Text('Gudang Barang', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Lihat data stok', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 1,
            color: const Color(0xFFF0FFF0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatAdminScreen())),
              leading: CircleAvatar(backgroundColor: Colors.green.withOpacity(0.2), child: const Icon(Icons.history, color: Colors.green)),
              title: const Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Log aktivitas', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 1,
            color: const Color(0xFFFCF5F5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PermintaanUptScreen())),
              leading: CircleAvatar(backgroundColor: Colors.red.withOpacity(0.2), child: const Icon(Icons.assignment, color: Colors.redAccent)),
              title: const Text('Permintaan UPT', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Kelola pengajuan UPT', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 1,
            color: const Color(0xFFFFF9F0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PermintaanPosScreen())),
              leading: CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.2), child: const Icon(Icons.check_box, color: Colors.orange)),
              title: const Text('Permintaan Pos', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Kelola pengajuan Pos', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 10),

          // MENU KERUSAKAN SEDANG
          Card(
            elevation: 1,
            color: const Color(0xFFFFFDE7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const KerusakanSedangScreen())),
              leading: CircleAvatar(backgroundColor: Colors.amber.withOpacity(0.2), child: const Icon(Icons.warning_amber, color: Colors.amber)),
              title: const Text('Kerusakan Sedang', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Kelola laporan kerusakan sedang', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 10),

          // MENU KERUSAKAN BERAT
          Card(
            elevation: 1,
            color: const Color(0xFFFFEBEE),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const KerusakanBeratScreen())),
              leading: CircleAvatar(backgroundColor: Colors.redAccent.withOpacity(0.2), child: const Icon(Icons.error_outline, color: Colors.redAccent)),
              title: const Text('Kerusakan Berat', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Kelola laporan kerusakan berat', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}