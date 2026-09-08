import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:local_notifier/local_notifier.dart';
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
  bool _isImporting = false;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _pantauLaporanBaru();
  }

  void _pantauLaporanBaru() {
    FirebaseFirestore.instance
        .collection('laporan_kerusakan')
        .snapshots()
        .listen((snapshot) {
          
      if (_isInitialLoad) {
        _isInitialLoad = false;
        return; 
      }

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() ?? {};
          
          String pengaju = data['namaPelanggan'] ?? 'UPT / Pos';
          String barang = data['namaBarang'] ?? 'Barang';
          String tingkat = data['tingkatKerusakan'] ?? '';
          
          String titleNotif = '';
          String bodyNotif = '';

          if (tingkat == 'Pengajuan Baru') {
            titleNotif = "Ada Permintaan Baru!";
            bodyNotif = "$pengaju telah mengirim permintaan untuk $barang.";
          } else {
            titleNotif = "Ada Laporan Kerusakan $tingkat Terbaru!";
            bodyNotif = "$pengaju melaporkan kendala pada $barang.";
          }

          LocalNotification notification = LocalNotification(
            title: titleNotif,
            body: bodyNotif,
          );
          
          notification.show();
        }
      }
    });
  }

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

  List<String> _parseCsvLine(String line, String separator) {
    List<String> cols = [];
    bool inQuotes = false;
    String currentCol = '';
    for (int c = 0; c < line.length; c++) {
      String char = line[c];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == separator && !inQuotes) {
        cols.add(currentCol.replaceAll('"', '').trim());
        currentCol = '';
      } else {
        currentCol += char;
      }
    }
    cols.add(currentCol.replaceAll('"', '').trim());
    return cols;
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

      int headerIndex = -1;
      List<String> headers = [];
      for (int i = 0; i < lines.length; i++) {
        String lowerLine = lines[i].toLowerCase();
        if ((lowerLine.contains('nama barang') || lowerLine.contains('jenis barang') || lowerLine.contains('nama')) && lowerLine.contains('no')) {
          headerIndex = i;
          headers = _parseCsvLine(lines[i], separator);
          break;
        }
      }

      if (headerIndex == -1) {
        for (int i = 0; i < lines.length; i++) {
          String lowerLine = lines[i].toLowerCase();
          if (lowerLine.contains('nama barang') || lowerLine.contains('jenis barang') || lowerLine.contains('nama')) {
            headerIndex = i;
            headers = _parseCsvLine(lines[i], separator);
            break;
          }
        }
      }

      if (headerIndex == -1) headerIndex = 0;

      for (int i = headerIndex + 1; i < lines.length; i++) {
        String lineStr = lines[i].trim();
        if (lineStr.isEmpty) continue;

        List<String> cols = _parseCsvLine(lineStr, separator);
        if (cols.length < 2) continue;
        String namaBarang = '';
        

        if (int.tryParse(cols[0].trim()) != null && cols.length > 1) {
          namaBarang = cols[1].trim();
          
        } else {
          namaBarang = cols[0].trim();
          
        }

        String lowerNama = namaBarang.toLowerCase();
        if (namaBarang.isEmpty || 
            lowerNama.contains('garut') || 
            lowerNama.contains('kepala') || 
            lowerNama.contains('catatan') ||
            lowerNama.contains('nip.') ||
            lowerNama.contains('bid pencegahan') ||
            lowerNama.contains('kabid ops') ||
            (int.tryParse(namaBarang) != null && namaBarang.length < 3)) {
          continue;
        }

        Map<String, String> rowMap = {};
        for (int h = 0; h < headers.length; h++) {
          String key = headers[h].trim().isEmpty ? 'Kolom_$h' : headers[h].trim();
          String val = h < cols.length ? cols[h].trim() : '';
          rowMap[key] = val;
        }

        String kategori = 'Peralatan Umum';
        for (var entry in rowMap.entries) {
          String k = entry.key.toLowerCase();
          if (k.contains('rekening') || k.contains('kategori') || k.contains('penyusun') || k.contains('kelompok')) {
            if (!k.contains('pengadaan') && !k.contains('jumlah') && !k.contains('stok') && !k.contains('sisa')) {
              if (entry.value.isNotEmpty && entry.value != '-') {
                kategori = entry.value;
                break;
              }
            }
          }
        }
        if (content.toLowerCase().contains('kendaraan') && kategori == 'Peralatan Umum') {
          kategori = 'Kendaraan';
        }

        int jumlahStok = 1;
        for (var entry in rowMap.entries) {
          String k = entry.key.toLowerCase();
          if (k.contains('pengadaan') || k.contains('kuantitas') || k == 'jumlah' || k.contains('stok')) {
            double? parsedVal = double.tryParse(entry.value.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), ''));
            if (parsedVal != null && parsedVal > 0) {
              jumlahStok = parsedVal.toInt();
              break;
            }
          }
        }
        if (jumlahStok == 1 && cols.length > 2) {
          int? col2Val = int.tryParse(cols[2].replaceAll(RegExp(r'[^0-9]'), ''));
          if (col2Val != null && col2Val > 0) jumlahStok = col2Val;
        }

        double hargaSatuan = 0.0;
        for (var entry in rowMap.entries) {
          String k = entry.key.toLowerCase();
          if (k.contains('harga') || k.contains('satuan')) {
            if (!k.contains('total') && !k.contains('jumlah')) {
              String cleanH = entry.value.replaceAll(',', '').trim();
              double? parsedH = double.tryParse(cleanH);
              if (parsedH != null) {
                hargaSatuan = parsedH;
                break;
              }
            }
          }
        }

        Map<String, dynamic> dataUpload = {
          'nama': namaBarang,
          'kategori': kategori,
          'jumlah': jumlahStok,
          'status': 'Tersedia',
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (hargaSatuan > 0) {
          dataUpload['harga'] = hargaSatuan;
        }

        rowMap.forEach((k, v) {
          String lowerK = k.toLowerCase();
          if (!lowerK.contains('nama') && 
              !lowerK.contains('jenis barang') && 
              !lowerK.contains('no') && 
              v.isNotEmpty) {
            dataUpload[k] = v;
          }
        });

        await FirebaseFirestore.instance.collection('gudang_barang').add(dataUpload);
        totalImported++;
      }

      if (!mounted) return;
      _tampilkanDialog('Berhasil mengimpor $totalImported data secara akurat sesuai file!', isBerhasil: true);
    } catch (e) {
      if (mounted) _tampilkanDialog('Gagal mengimpor file. Pastikan format file benar.\nDetail Error: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // Fungsi untuk mencetak semua barang di gudang ke PDF / Printer
  Future<void> _cetakSemuaBarang() async {
    try {
      setState(() => _isImporting = true);
      
      // Ambil seluruh data dari koleksi gudang_barang
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('gudang_barang')
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) _tampilkanDialog('Tidak ada data barang di gudang untuk dicetak.');
        return;
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('PEMADAM KEBAKARAN KABUPATEN GARUT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Laporan Stok Gudang', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('DAFTAR KESELURUHAN BARANG GUDANG PRASARANA', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 15),
              pw.Table.fromTextArray(
                headers: ['No', 'Nama Barang', 'Kategori', 'Jumlah Stok', 'Status'],
                data: List<List<String>>.generate(snapshot.docs.length, (index) {
                  var data = snapshot.docs[index].data() as Map<String, dynamic>;
                  return [
                    '${index + 1}',
                    data['nama']?.toString() ?? '-',
                    data['kategori']?.toString() ?? '-',
                    '${data['jumlah'] ?? 0} Unit',
                    data['status']?.toString() ?? 'Tersedia',
                  ];
                }),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFB71C1C)), // Warna merah Damkar
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FixedColumnWidth(70),
                  4: const pw.FixedColumnWidth(70),
                },
              ),
            ];
          },
        ),
      );

      // Buka dialog preview dan cetak PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Laporan_Gudang_Barang.pdf',
      );

    } catch (e) {
      if (mounted) _tampilkanDialog('Gagal mencetak laporan: $e');
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
                _buildCompactMenuCard(title: 'Cetak Laporan Gudang', subtitle: 'Print / Export PDF seluruh barang', icon: Icons.print, iconColor: Colors.purple, bgColor: const Color(0xFFF9F0FF), onTap: _cetakSemuaBarang),
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