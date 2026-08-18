import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _ambilDataAdmin();
  }

  Future<void> _ambilDataAdmin() async {
    if (user != null) {
      _emailController.text = user!.email ?? '';
      
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;
          _namaController.text = data['nama'] ?? '';
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
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'nama': _namaController.text.trim(),
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
                    child: Icon(Icons.account_circle, size: 100, color: Colors.red[800]),
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

                  // Tombol Simpan Perubahan
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

                  // Tombol Kembali ke Dashboard Admin
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