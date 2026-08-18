import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class LaporRusakScreen extends StatefulWidget {
  const LaporRusakScreen({super.key});

  @override
  State<LaporRusakScreen> createState() => _LaporRusakScreenState();
}

class _LaporRusakScreenState extends State<LaporRusakScreen> {
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  
  // Default pilihan diubah menjadi Kerusakan Sedang karena Ringan sudah dihapus
  String _tingkatKerusakan = 'Kerusakan Sedang';
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('laporan_kerusakan/$fileName.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _kirimLaporan() async {
    if (_namaBarangController.text.trim().isEmpty || _jumlahController.text.trim().isEmpty) {
      _tampilkanDialog('Peringatan', 'Nama barang dan jumlah wajib diisi!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? fotoUrl;
      if (_selectedImage != null) {
        fotoUrl = await _uploadImage(_selectedImage!);
      }

      await FirebaseFirestore.instance.collection('laporan_kerusakan').add({
        'namaBarang': _namaBarangController.text.trim(),
        'tingkatKerusakan': _tingkatKerusakan,
        'jumlah': int.tryParse(_jumlahController.text.trim()) ?? 0,
        'keterangan': _keteranganController.text.trim(),
        'fotoUrl': fotoUrl ?? '',
        'status': 'Menunggu',
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      // Dialog sukses konfirmasi sebelum kembali ke dashboard
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
                Navigator.pop(context); // Tutup dialog
                Navigator.pop(context); // Kembali ke halaman sebelumnya secara mulus
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
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
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
              decoration: const InputDecoration(
                labelText: 'Nama Barang',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: _tingkatKerusakan,
              decoration: const InputDecoration(
                labelText: 'Tingkat Kerusakan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warning_amber),
              ),
              items: const [
                // PERBAIKAN: "Kerusakan Ringan" sudah dihapus dari sini
                DropdownMenuItem(value: 'Kerusakan Sedang', child: Text('Kerusakan Sedang')),
                DropdownMenuItem(value: 'Kerusakan Berat', child: Text('Kerusakan Berat')),
              ],
              onChanged: (value) => setState(() => _tingkatKerusakan = value!),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Unit',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _keteranganController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Keterangan Kerusakan',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 25),

            // Tombol Kirim Laporan
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isLoading ? null : _kirimLaporan,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Kirim Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            
            const SizedBox(height: 12),

            // Tombol KEMBALI
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700], 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
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