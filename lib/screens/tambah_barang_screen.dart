import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class TambahBarangScreen extends StatefulWidget {
  const TambahBarangScreen({super.key});

  @override
  State<TambahBarangScreen> createState() => _TambahBarangScreenState();
}

class _TambahBarangScreenState extends State<TambahBarangScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  String _kategoriTerpilih = 'Alat Pemadam';
  String _imageBase64 = '';
  bool _isLoading = false;

  final List<String> _kategoriList = [
    'Alat Pemadam',
    'APD',
    'Selang & Aksesoris',
    'Kendaraan',
    'Lainnya',
  ];

  // Fungsi untuk memilih gambar dan mengubahnya ke Base64
  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.bytes != null) {
      Uint8List fileBytes = result.files.single.bytes!;
      setState(() {
        _imageBase64 = base64Encode(fileBytes);
      });
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
              Navigator.pop(context);
              if (isBerhasil) {
                Navigator.pop(context); // Kembali ke dashboard setelah sukses menyimpan
              }
            },
            child: Text(
              'OK',
              style: TextStyle(color: isBerhasil ? Colors.green : Colors.red[800], fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk menyimpan data barang ke Firestore
  Future<void> _simpanDataBarang() async {
    if (_namaController.text.trim().isEmpty || _jumlahController.text.trim().isEmpty) {
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
      await FirebaseFirestore.instance.collection('gudang_barang').add({
        'nama': _namaController.text.trim(),
        'kategori': _kategoriTerpilih,
        'jumlah': jumlah,
        'status': 'Baik',
        'imageUrl': _imageBase64,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _tampilkanDialog('Data barang berhasil disimpan ke gudang!', isBerhasil: true);

    } catch (e) {
      _tampilkanDialog('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Menghilangkan ikon panah kembali di atas
        title: const Text('Tambah Barang Baru'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bagian Upload Foto
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
                          child: Image.memory(
                            base64Decode(_imageBase64),
                            fit: BoxFit.cover,
                            height: 120,
                            width: 120,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Input Nama Barang
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Barang',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
            ),
            const SizedBox(height: 15),

            // Dropdown Kategori
            DropdownButtonFormField<String>(
              value: _kategoriTerpilih,
              decoration: const InputDecoration(
                labelText: 'Kategori Barang',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _kategoriList.map((kategori) {
                return DropdownMenuItem(
                  value: kategori,
                  child: Text(kategori),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _kategoriTerpilih = value!;
                });
              },
            ),
            const SizedBox(height: 15),

            // Input Jumlah
            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
            ),
            const SizedBox(height: 30),

            // Tombol Simpan Data Barang
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isLoading ? null : _simpanDataBarang,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Simpan Data Barang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 15),

            // Tombol Persegi Kembali ke Dashboard
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