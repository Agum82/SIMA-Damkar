import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordBaruController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscurePassword = true;

  File? _imageFile;
  String? _currentPhotoBase64;

  @override
  void initState() {
    super.initState();
    _ambilDataAdmin();
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 50,
    );
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _hapusFoto() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Foto Profil?'),
        content: const Text('Foto profil akan dihapus. Jangan lupa klik tombol "SIMPAN PERUBAHAN".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              setState(() {
                _imageFile = null;
                _currentPhotoBase64 = ''; 
              });
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _tampilkanMenuOpsiFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Pengaturan Foto Profil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ),
            if (_imageFile != null || (_currentPhotoBase64 != null && _currentPhotoBase64!.isNotEmpty))
              ListTile(
                leading: const Icon(Icons.fullscreen, color: Colors.black87),
                title: const Text('Lihat Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _lihatFotoPenuh();
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Edit / Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Edit / Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_imageFile != null || (_currentPhotoBase64 != null && _currentPhotoBase64!.isNotEmpty))
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus Foto', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _hapusFoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _lihatFotoPenuh() {
    if (_imageFile == null && (_currentPhotoBase64 == null || _currentPhotoBase64!.isEmpty)) {
      _tampilkanDialog('Belum ada foto profil untuk dilihat.');
      return;
    }

    Widget imageWidget;
    if (_imageFile != null) {
      imageWidget = Image.file(_imageFile!, fit: BoxFit.contain);
    } else {
      Uint8List decodedBytes = base64Decode(_currentPhotoBase64!);
      imageWidget = Image.memory(decodedBytes, fit: BoxFit.contain);
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true, 
              minScale: 0.5,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageWidget,
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ambilDataAdmin() async {
    if (user != null) {
      _emailController.text = user!.email ?? '';
      
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;
          _namaController.text = data['nama'] ?? '';
          _currentPhotoBase64 = data['photoUrl'] ?? ''; // Mengambil Base64 foto dari Firestore
        }
      } catch (e) {
        // Abaikan error jaringan saat memuat
      }
    }
    setState(() => _isLoading = false);
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: isBerhasil ? Colors.green : Colors.red[800], fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _simpanPerubahan() async {
    if (_namaController.text.trim().isEmpty) {
      _tampilkanDialog('Nama lengkap tidak boleh kosong!');
      return;
    }

    setState(() => _isSaving = true);

    try {
      String finalImageBase64 = _currentPhotoBase64 ?? '';

      // Konversi ke Base64 jika ada file baru
      if (_imageFile != null) {
        List<int> imageBytes = await _imageFile!.readAsBytes();
        finalImageBase64 = base64Encode(imageBytes);
      }

      // Memperbarui data nama dan photoUrl di Firestore
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'nama': _namaController.text.trim(),
        'photoUrl': finalImageBase64,
      });

      if (_passwordBaruController.text.trim().isNotEmpty) {
        if (_passwordBaruController.text.trim().length < 6) {
          _tampilkanDialog('Password baru minimal harus 6 karakter!');
          setState(() => _isSaving = false);
          return;
        }
        await user!.updatePassword(_passwordBaruController.text.trim());
      }

      if (!mounted) return;
      _tampilkanDialog('Profil admin berhasil diperbarui!', isBerhasil: true);
      _passwordBaruController.clear();
      _currentPhotoBase64 = finalImageBase64;
      _imageFile = null; 
      
    } on FirebaseAuthException catch (e) {
      String pesan = 'Gagal memperbarui profil.';
      if (e.code == 'requires-recent-login') {
        pesan = 'Sesi telah kedaluwarsa. Silakan masuk kembali sebelum mengubah password.';
      } else {
        pesan = 'Error: ${e.message}';
      }
      _tampilkanDialog(pesan);
    } catch (e) {
      _tampilkanDialog('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  ImageProvider? _getAvatarImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (_currentPhotoBase64 != null && _currentPhotoBase64!.isNotEmpty) {
      try {
        Uint8List decodedBytes = base64Decode(_currentPhotoBase64!);
        return MemoryImage(decodedBytes);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profil Admin'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _lihatFotoPenuh, 
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _getAvatarImage(),
                            child: _getAvatarImage() == null
                                ? Icon(Icons.account_circle, size: 100, color: Colors.grey[400])
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _tampilkanMenuOpsiFoto, 
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red[800],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text('Kasi Prasarana / Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  const SizedBox(height: 30),

                  TextField(
                    controller: _namaController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap / Instansi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _emailController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Email (Tidak dapat diubah)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                      filled: true,
                      fillColor: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _passwordBaruController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password Baru (Opsional)',
                      hintText: 'Kosongkan jika tidak ingin mengubah password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : _simpanPerubahan,
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('SIMPAN PERUBAHAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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