import 'dart:convert';
import 'dart:io'; // DITAMBAHKAN: Wajib untuk membaca path file di Android
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';

class PengajuanBarangScreen extends StatefulWidget {
  const PengajuanBarangScreen({super.key});

  @override
  State<PengajuanBarangScreen> createState() => _PengajuanBarangScreenState();
}

class _PengajuanBarangScreenState extends State<PengajuanBarangScreen> {
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  String _imageBase64 = '';
  bool _isLoading = false;

  // PERBAIKAN: Fungsi _pickImage diubah agar bisa membaca file di HP Android
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      // Gunakan 'path', bukan 'bytes', karena di Android 'bytes' seringkali null
      if (result != null && result.files.single.path != null) {
        // Baca file dari lokasi path-nya
        File file = File(result.files.single.path!);
        Uint8List fileBytes = await file.readAsBytes();
        
        setState(() {
          _imageBase64 = base64Encode(fileBytes);
        });
      }
    } catch (e) {
      _tampilkanDialog('Gagal mengambil gambar: $e');
    }
  }

  // Fungsi helper untuk menampilkan dialog pop-up di tengah layar
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
              Navigator.pop(context); // Hanya menutup dialog, tetap di halaman pengajuan
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

  Future<void> _kirimPengajuan() async {
    if (_namaBarangController.text.trim().isEmpty || _jumlahController.text.trim().isEmpty) {
      _tampilkanDialog('Nama barang dan jumlah harus diisi!');
      return;
    }

    int? jumlah = int.tryParse(_jumlahController.text.trim());
    if (jumlah == null) {
      _tampilkanDialog('Jumlah harus berupa angka!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      String namaPelanggan = 'UPT / Pos';
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          namaPelanggan = userDoc.get('nama') ?? 'UPT / Pos';
        }
      }

      await FirebaseFirestore.instance.collection('laporan_kerusakan').add({
        'namaBarang': _namaBarangController.text.trim(),
        'jumlah': jumlah,
        'tingkatKerusakan': 'Pengajuan Baru',
        'keterangan': _keteranganController.text.trim().isEmpty ? 'Tidak ada keterangan' : _keteranganController.text.trim(),
        'imageUrl': _imageBase64, // Menyimpan base64 gambar
        'status': 'Menunggu',
        'namaPelanggan': namaPelanggan,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _tampilkanDialog('Pengajuan barang berhasil dikirim!', isBerhasil: true);

      // Kosongkan kembali form input agar siap digunakan kembali tanpa keluar halaman
      _namaBarangController.clear();
      _jumlahController.clear();
      _keteranganController.clear();
      setState(() {
        _imageBase64 = '';
      });

    } catch (e) {
      _tampilkanDialog('Gagal mengirim pengajuan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        title: const Text('Ajukan Permintaan Barang', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _imageBase64.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                            SizedBox(height: 6),
                            Text('Foto Barang', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          // PERBAIKAN: Menambahkan errorBuilder agar tahu jika konversi gagal
                          child: Image.memory(
                            base64Decode(_imageBase64),
                            fit: BoxFit.cover,
                            height: 120,
                            width: 120,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.broken_image,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: _namaBarangController,
              decoration: const InputDecoration(
                labelText: 'Nama Barang',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _keteranganController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Keterangan / Keperluan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 30),
            
            // Tombol Kirim Pengajuan
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isLoading ? null : _kirimPengajuan,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Kirim Pengajuan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 15),
            
            // Tombol KEMBALI di bagian bawah
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context), // Tombol Kembali ke Dashboard
                child: const Text('KEMBALI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}