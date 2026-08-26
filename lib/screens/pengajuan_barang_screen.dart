import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart'; // DITAMBAHKAN: Untuk upload gambar

class PengajuanBarangScreen extends StatefulWidget {
  const PengajuanBarangScreen({super.key});

  @override
  State<PengajuanBarangScreen> createState() => _PengajuanBarangScreenState();
}

class _PengajuanBarangScreenState extends State<PengajuanBarangScreen> {
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  
  File? _selectedImage; // PERBAIKAN: Menggunakan File asli, bukan Base64
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _tampilkanDialog('Gagal mengambil gambar: $e');
    }
  }

  // PERBAIKAN: Fungsi upload gambar ke Firebase Storage (Sama seperti Lapor Rusak)
  Future<String?> _uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('pengajuan_barang/$fileName.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

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
      if (user == null) throw Exception("Anda belum login!");

      // 1. Cari Nama Pengirim / Fallback ke Email
      String namaPelanggan = user.email ?? 'Akun Tanpa Email';
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
           Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
           if (userData != null) {
              if (userData.containsKey('nama') && userData['nama'].toString().isNotEmpty) {
                 namaPelanggan = userData['nama'];
              } else if (userData.containsKey('name') && userData['name'].toString().isNotEmpty) {
                 namaPelanggan = userData['name'];
              } else if (userData.containsKey('username') && userData['username'].toString().isNotEmpty) {
                 namaPelanggan = userData['username'];
              }
           }
        }
      } catch (e) {}

      // 2. Upload Gambar jika ada
      String? fotoUrl;
      if (_selectedImage != null) {
        fotoUrl = await _uploadImage(_selectedImage!);
      }

      // 3. Simpan ke database (Sengaja tetap di laporan_kerusakan sesuai desain asli Anda)
      await FirebaseFirestore.instance.collection('laporan_kerusakan').add({
        'namaBarang': _namaBarangController.text.trim(),
        'jumlah': jumlah,
        'tingkatKerusakan': 'Pengajuan Baru', // Ini tanda bahwa ini adalah Permintaan
        'keterangan': _keteranganController.text.trim().isEmpty ? 'Tidak ada keterangan' : _keteranganController.text.trim(),
        'imageUrl': fotoUrl ?? '', // Format URL Firebase
        'status': 'Menunggu',
        'namaPelanggan': namaPelanggan,
        'userId': user.uid, // KUNCI UTAMA: Agar muncul di Riwayat!
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _tampilkanDialog('Pengajuan barang berhasil dikirim!', isBerhasil: true);

      // Kosongkan form
      _namaBarangController.clear();
      _jumlahController.clear();
      _keteranganController.clear();
      setState(() {
        _selectedImage = null;
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
                  child: _selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                            SizedBox(height: 6),
                            Text('Foto Barang', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            height: 120,
                            width: 120,
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
            
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context), 
                child: const Text('KEMBALI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}