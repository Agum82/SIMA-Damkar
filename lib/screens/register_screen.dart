import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _roleTerpilih = 'UPT'; 
  bool _isLoading = false;
  bool _obscurePassword = true;

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
        content: Text(
          pesan,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isBerhasil) {
                Navigator.pushReplacementNamed(context, '/login');
              }
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

  Future<void> _daftarFirebase() async {
    if (_namaController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _tampilkanDialog('Semua kolom harus diisi!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'nama': _namaController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _roleTerpilih,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _tampilkanDialog('Pendaftaran Berhasil! Silakan Login.', isBerhasil: true);

    } on FirebaseAuthException catch (e) {
      String pesan = 'Terjadi kesalahan.';
      if (e.code == 'weak-password') pesan = 'Password terlalu lemah (minimal 6 karakter).';
      else if (e.code == 'email-already-in-use') pesan = 'Email ini sudah terdaftar.';
      else if (e.code == 'invalid-email') pesan = 'Format email tidak valid.';
      else pesan = 'Firebase Auth Error (${e.code}): ${e.message}';
      
      _tampilkanDialog(pesan);
    } catch (e) {
      _tampilkanDialog('Error: $e');
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
        title: const Text('Daftar Akun Baru'), 
        backgroundColor: Colors.red[800], 
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ikon Profil (Warna Merah)
              Icon(Icons.account_circle, size: 90, color: Colors.red[800]),
              const SizedBox(height: 30),
              
              TextField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap / Nama Instansi', 
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.person)
                ),
              ),
              const SizedBox(height: 15),
              
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Alamat Email', 
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.email)
                ),
              ),
              const SizedBox(height: 15),
              
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password (Min. 6 Karakter)', 
                  border: const OutlineInputBorder(), 
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              
              DropdownButtonFormField<String>(
                value: _roleTerpilih,
                decoration: const InputDecoration(
                  labelText: 'Daftar Sebagai', 
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.badge)
                ),
                items: ['UPT', 'Pos', 'Admin'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                onChanged: (value) => setState(() => _roleTerpilih = value!),
              ),
              
              const SizedBox(height: 30),
              
              // Tombol Daftar Sekarang
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800], 
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _daftarFirebase,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('DAFTAR SEKARANG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 16),

              // Tombol Kembali berbentuk persegi dengan warna biru
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700], 
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'), 
                  child: const Text('KEMBALI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}