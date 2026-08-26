import 'dart:convert'; // Untuk Base64
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class LaporRusakScreen extends StatefulWidget {
  const LaporRusakScreen({super.key});

  @override
  State<LaporRusakScreen> createState() => _LaporRusakScreenState();
}

class _LaporRusakScreenState extends State<LaporRusakScreen> {
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  
  String _tingkatKerusakan = 'Sedang'; 
  Uint8List? _imageBytes; 
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Resolusi dikompres agar ukuran Base64 tidak terlalu besar untuk Firestore
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 800, maxHeight: 800);
    
    if (pickedFile != null) {
      Uint8List bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _kirimLaporan() async {
    if (_namaBarangController.text.trim().isEmpty || _jumlahController.text.trim().isEmpty) {
      _tampilkanDialog('Peringatan', 'Nama barang dan jumlah wajib diisi!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Anda belum login!");

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
      } catch (e) {
        // Abaikan
      }

      // 1. MENGUBAH GAMBAR JADI BASE64 (Sama seperti halaman Edit Barang)
      String fotoBase64 = '';
      if (_imageBytes != null) {
        fotoBase64 = base64Encode(_imageBytes!);
      }

      // 2. SIMPAN LANGSUNG KE FIRESTORE (Tanpa Firebase Storage)
      await FirebaseFirestore.instance.collection('laporan_kerusakan').add({
        'namaBarang': _namaBarangController.text.trim(),
        'tingkatKerusakan': _tingkatKerusakan,
        'jumlah': int.tryParse(_jumlahController.text.trim()) ?? 0,
        'keterangan': _keteranganController.text.trim(),
        'imageUrl': fotoBase64, // Disimpan sebagai Base64
        'status': 'Menunggu',
        'namaPelanggan': namaPelanggan, 
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('Berhasil'),
            ],
          ),
          content: const Text('Laporan kerusakan berhasil dikirim!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
                Navigator.pop(context); 
              },
              child: const Text('OK', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      _tampilkanDialog('Error', 'Gagal mengirim laporan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _tampilkanDialog(String judul, String pesan, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(isError ? Icons.error : Icons.check_circle, color: isError ? Colors.red[800] : Colors.green),
            const SizedBox(width: 10),
            Text(judul),
          ],
        ),
        content: Text(pesan),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: isError ? Colors.red[800] : Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        title: const Text('Lapor Kerusakan Barang', style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                            SizedBox(height: 5),
                            Text('Foto Kerusakan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _namaBarangController,
              decoration: const InputDecoration(labelText: 'Nama Barang', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory_2)),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _tingkatKerusakan,
              decoration: const InputDecoration(labelText: 'Tingkat Kerusakan', border: OutlineInputBorder(), prefixIcon: Icon(Icons.warning_amber)),
              items: const [
                DropdownMenuItem(value: 'Sedang', child: Text('Kerusakan Sedang')),
                DropdownMenuItem(value: 'Berat', child: Text('Kerusakan Berat')),
              ],
              onChanged: (value) => setState(() => _tingkatKerusakan = value!),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah Unit', border: OutlineInputBorder(), prefixIcon: Icon(Icons.format_list_numbered)),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _keteranganController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Keterangan Kerusakan', border: OutlineInputBorder(), alignLabelWithHint: true),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: _isLoading ? null : _kirimLaporan,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Kirim Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () => Navigator.pop(context),
                child: const Text('KEMBALI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}