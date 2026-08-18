import 'dart:convert'; // Untuk base64Encode & base64Decode
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditBarangScreen extends StatefulWidget {
  final String docId; // Menerima ID dari Firestore
  final Map<String, dynamic> dataLama; // Menerima data lama

  const EditBarangScreen({super.key, required this.docId, required this.dataLama});

  @override
  State<EditBarangScreen> createState() => _EditBarangScreenState();
}

class _EditBarangScreenState extends State<EditBarangScreen> {
  late TextEditingController _namaBarangController;
  late TextEditingController _jumlahController;
  late String _kategoriTerpilih;
  
  String _imageUrlLama = '';
  Uint8List? _imageBytes; // Menggunakan bytes agar kompatibel di Web dan Mobile
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    _namaBarangController = TextEditingController(text: widget.dataLama['nama'] ?? '');
    _jumlahController = TextEditingController(text: widget.dataLama['jumlah']?.toString() ?? '');
    
    List<String> validKategori = ['Alat Pemadam', 'APD (Alat Pelindung Diri)', 'Kendaraan', 'Lainnya'];
    String kategoriDariDB = widget.dataLama['kategori'] ?? 'Lainnya';
    _kategoriTerpilih = validKategori.contains(kategoriDariDB) ? kategoriDariDB : 'Lainnya';
    
    _imageUrlLama = widget.dataLama['imageUrl'] ?? '';
  }

  Future<void> _pilihGambar(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        Uint8List bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka media: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateBarang() async {
    if (_namaBarangController.text.trim().isEmpty || _jumlahController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peringatan: Nama barang dan jumlah harus diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String finalImageBase64 = _imageUrlLama;

      // Jika user memilih gambar baru, konversi ke Base64
      if (_imageBytes != null) {
        finalImageBase64 = base64Encode(_imageBytes!);
      }

      // Update data langsung ke Firestore
      await FirebaseFirestore.instance.collection('gudang_barang').doc(widget.docId).update({
        'nama': _namaBarangController.text.trim(),
        'kategori': _kategoriTerpilih,
        'jumlah': int.tryParse(_jumlahController.text.trim()) ?? 0,
        'imageUrl': finalImageBase64,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data barang berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); 
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _namaBarangController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  // Helper untuk menampilkan preview gambar lama (Base64) atau baru
  Widget _buildPreviewImage() {
    if (_imageBytes != null) {
      return Image.memory(_imageBytes!, fit: BoxFit.cover);
    } else if (_imageUrlLama.isNotEmpty) {
      try {
        Uint8List decodedBytes = base64Decode(_imageUrlLama);
        return Image.memory(decodedBytes, fit: BoxFit.cover);
      } catch (e) {
        return const Icon(Icons.inventory_2, color: Colors.red);
      }
    } else {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
          SizedBox(height: 5),
          Text('Foto Barang', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Barang Gudang'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: _buildPreviewImage(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
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
            const SizedBox(height: 25),
            TextField(
              controller: _namaBarangController,
              decoration: const InputDecoration(
                labelText: 'Nama Barang',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _kategoriTerpilih,
              decoration: const InputDecoration(
                labelText: 'Kategori Barang',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: <String>[
                'Alat Pemadam', 
                'APD (Alat Pelindung Diri)', 
                'Kendaraan', 
                'Lainnya'
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  if (newValue != null) {
                    _kategoriTerpilih = newValue;
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Stok',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateBarang,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800],
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}