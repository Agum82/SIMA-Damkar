import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EditBarangScreen extends StatefulWidget {
  final String docId; 
  final Map<String, dynamic> dataLama; 

  const EditBarangScreen({
    super.key, 
    required this.docId, 
    required this.dataLama,
  });

  @override
  State<EditBarangScreen> createState() => _EditBarangScreenState();
}

class _EditBarangScreenState extends State<EditBarangScreen> {
  late TextEditingController _namaBarangController;
  late TextEditingController _kategoriController; 
  late TextEditingController _jumlahController;
  late TextEditingController _hargaController;   
  
  final Map<String, TextEditingController> _atributDinamisControllers = {};
  
  String _imageUrlLama = '';
  Uint8List? _imageBytes; 
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    _namaBarangController = TextEditingController(text: widget.dataLama['nama'] ?? '');
    _kategoriController = TextEditingController(text: widget.dataLama['kategori'] ?? ''); 
    _jumlahController = TextEditingController(text: widget.dataLama['jumlah']?.toString() ?? '');
    _hargaController = TextEditingController(text: widget.dataLama['harga']?.toString() ?? '0'); 
    
    _imageUrlLama = widget.dataLama['imageUrl'] ?? '';

    List<String> fieldUtama = ['nama', 'kategori', 'jumlah', 'harga', 'imageUrl', 'createdAt', 'status'];
    widget.dataLama.forEach((key, value) {
      if (!fieldUtama.contains(key)) {
        _atributDinamisControllers[key] = TextEditingController(text: value.toString());
      }
    });
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
    if (_namaBarangController.text.trim().isEmpty || 
        _kategoriController.text.trim().isEmpty || 
        _jumlahController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peringatan: Nama, Kategori, dan Jumlah harus diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int? jumlah = int.tryParse(_jumlahController.text.trim());
    if (jumlah == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah stok harus berupa angka!'), backgroundColor: Colors.red),
      );
      return;
    }

    double? harga;
    if (_hargaController.text.trim().isNotEmpty) {
      harga = double.tryParse(_hargaController.text.trim().replaceAll(RegExp(r'[^0-9.]'), ''));
    }

    setState(() => _isLoading = true);

    try {
      String finalImageBase64 = _imageUrlLama;

      if (_imageBytes != null) {
        finalImageBase64 = base64Encode(_imageBytes!);
      }

      Map<String, dynamic> dataToUpdate = {
        'nama': _namaBarangController.text.trim(),
        'kategori': _kategoriController.text.trim(), 
        'jumlah': jumlah,
        'imageUrl': finalImageBase64,
      };

      if (harga != null && harga > 0) {
        dataToUpdate['harga'] = harga;
      } else {
        dataToUpdate['harga'] = FieldValue.delete();
      }

      _atributDinamisControllers.forEach((key, controller) {
        if (controller.text.trim().isNotEmpty) {
          dataToUpdate[key] = controller.text.trim();
        } else {
          dataToUpdate[key] = FieldValue.delete();
        }
      });

      await FirebaseFirestore.instance.collection('gudang_barang').doc(widget.docId).update(dataToUpdate);

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
    _kategoriController.dispose();
    _jumlahController.dispose();
    _hargaController.dispose();
    for (var controller in _atributDinamisControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

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
            TextField(
              controller: _kategoriController,
              decoration: const InputDecoration(
                labelText: 'Kategori Barang (Ketik bebas)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Stok (Total)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _hargaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga Satuan (Opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
            ),
            if (_atributDinamisControllers.isNotEmpty) ...[
              const SizedBox(height: 30),
              const Divider(thickness: 1.5),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Detail / Penempatan Wilayah:', 
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)
                ),
              ),
              const SizedBox(height: 15),
              ..._atributDinamisControllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: TextField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: entry.key,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_city, color: Colors.grey),
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateBarang,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}