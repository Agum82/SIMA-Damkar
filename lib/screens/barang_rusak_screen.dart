import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class BarangRusakScreen extends StatefulWidget {
  const BarangRusakScreen({super.key});

  @override
  State<BarangRusakScreen> createState() => _BarangRusakScreenState();
}

class _BarangRusakScreenState extends State<BarangRusakScreen> {
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _jumlahRusakController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  
  String _tingkatKerusakan = 'Sedang'; // Default pilihan
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Fungsi untuk memilih gambar dari galeri atau kamera
  Future<void> _pilihGambar(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka media: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Fungsi untuk menyimpan data ke Firebase
  Future<void> _simpanLaporanRusak() async {
    if (_namaBarangController.text.trim().isEmpty || _jumlahRusakController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peringatan: Nama barang dan jumlah rusak harus diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = '';

      // 1. Upload Foto ke Firebase Storage (Jika dilampirkan)
      if (_imageFile != null) {
        String fileName = 'laporan_rusak_${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child('laporan_kerusakan_images/$fileName');
        
        UploadTask uploadTask = storageRef.putFile(_imageFile!);
        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // 2. Simpan Data Laporan ke Firestore
      await FirebaseFirestore.instance.collection('laporan_kerusakan').add({
        'namaBarang': _namaBarangController.text.trim(),
        'jumlah': int.tryParse(_jumlahRusakController.text.trim()) ?? 0,
        'keterangan': _keteranganController.text.trim(),
        'tingkatKerusakan': _tingkatKerusakan, // 'Sedang' atau 'Berat'
        'imageUrl': imageUrl,
        'status': 'Menunggu', // Status default saat pertama kali dilapor
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan barang rusak berhasil dikirim ke Admin!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim laporan: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _namaBarangController.dispose();
    _jumlahRusakController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lapor Barang Rusak'),
        backgroundColor: Colors.orange[800], 
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- BAGIAN UPLOAD FOTO BUKTI ---
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange.shade300, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: _imageFile != null
                          ? (kIsWeb 
                              ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                              : Image.file(_imageFile!, fit: BoxFit.cover))
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.orange),
                                SizedBox(height: 8),
                                Text('Foto Bukti Rusak', style: TextStyle(fontSize: 12, color: Colors.orange)),
                              ],
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: -5,
                    right: -5,
                    child: CircleAvatar(
                      backgroundColor: Colors.orange[800],
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text('Pilih dari Galeri'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pilihGambar(ImageSource.gallery);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text('Ambil Foto Kamera'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pilihGambar(ImageSource.camera);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- FORM INPUT ---
            TextField(
              controller: _namaBarangController,
              decoration: const InputDecoration(
                labelText: 'Nama Barang yang Rusak',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.broken_image),
              ),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _tingkatKerusakan,
              decoration: const InputDecoration(
                labelText: 'Tingkat Kerusakan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warning_amber_rounded),
              ),
              items: ['Sedang', 'Berat'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text('Kerusakan $value'),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) setState(() => _tingkatKerusakan = newValue);
              },
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _jumlahRusakController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Rusak',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _keteranganController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Keterangan Kerusakan (Opsional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 40),

            // --- TOMBOL SIMPAN ---
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _simpanLaporanRusak,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Kirim Laporan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}