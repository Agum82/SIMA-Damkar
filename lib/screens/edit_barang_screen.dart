import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class EditBarangScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> dataLama;

  const EditBarangScreen({super.key, required this.docId, required this.dataLama});

  @override
  State<EditBarangScreen> createState() => _EditBarangScreenState();
}

class _EditBarangScreenState extends State<EditBarangScreen> {
  late TextEditingController _namaController;
  late TextEditingController _kategoriController;
  late TextEditingController _jumlahController;

  String _imageBase64 = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.dataLama['nama'] ?? '');
    _kategoriController = TextEditingController(text: widget.dataLama['kategori'] ?? '');
    _jumlahController = TextEditingController(text: widget.dataLama['jumlah']?.toString() ?? '0');
    _imageBase64 = widget.dataLama['imageUrl'] ?? '';
  }

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
                Navigator.pop(context);
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

  Future<void> _updateDataBarang() async {
    if (_namaController.text.trim().isEmpty || 
        _kategoriController.text.trim().isEmpty || 
        _jumlahController.text.trim().isEmpty) {
      _tampilkanDialog('Semua kolom harus diisi!');
      return;
    }

    int? jumlah = int.tryParse(_jumlahController.text.trim());
    if (jumlah == null) {
      _tampilkanDialog('Jumlah harus berupa angka!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('gudang_barang').doc(widget.docId).update({
        'nama': _namaController.text.trim(),
        'kategori': _kategoriController.text.trim(),
        'jumlah': jumlah,
        'imageUrl': _imageBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _tampilkanDialog('Data barang berhasil diperbarui!', isBerhasil: true);
    } catch (e) {
      _tampilkanDialog('Gagal memperbarui: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Barang Gudang'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        centerTitle: true,
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
                          child: _imageBase64.startsWith('http')
                              ? Image.network(_imageBase64, fit: BoxFit.cover, height: 120, width: 120)
                              : Image.memory(base64Decode(_imageBase64), fit: BoxFit.cover, height: 120, width: 120),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Barang',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _kategoriController,
              decoration: const InputDecoration(
                labelText: 'Kategori Barang',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Stok (Total)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
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
                onPressed: _isLoading ? null : _updateDataBarang,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}