import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Ditambahkan untuk TextInput.finishAutofillContext()
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'upt_dashboard_screen.dart';
import 'admin_dashboard_screen.dart'; 
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _muatDataTersimpan();
  }

  Future<void> _muatDataTersimpan() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('saved_email') ?? '';
      _passwordController.text = prefs.getString('saved_password') ?? '';
    });
  }

  Future<void> _simpanDataLokal(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_password', password);
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

  Future<void> _login() async {
    // Beri sinyal ke OS bahwa proses input selesai (memicu pop-up simpan sandi)
    TextInput.finishAutofillContext(); 

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _tampilkanDialog('Email dan password harus diisi!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _simpanDataLokal(email, password);

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        String role = userDoc.get('role') ?? 'UPT';

        if (role == 'Admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
          );
        } else if (role == 'UPT' || role == 'Pos') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UptDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UptDashboardScreen()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UptDashboardScreen()),
        );
      }

    } on FirebaseAuthException catch (e) {
      String pesan = 'Gagal masuk.';
      if (e.code == 'user-not-found') pesan = 'Email tidak terdaftar.';
      else if (e.code == 'wrong-password') pesan = 'Password salah.';
      else if (e.code == 'invalid-email') pesan = 'Format email tidak valid.';
      else pesan = 'Error: ${e.message}';
      
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: AutofillGroup( // 1. MENGGUNAKAN AutofillGroup
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_fire_department, size: 80, color: Colors.red[600]),
                const SizedBox(height: 20),
                const Text('Sistem Operasional Sapras', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Text('Dinas Pemadam Kebakaran Kab. Garut', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email], // 2. HINT UNTUK EMAIL
                  decoration: const InputDecoration(
                    labelText: 'Email', 
                    border: OutlineInputBorder(), 
                    prefixIcon: Icon(Icons.email)
                  ),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password], // 3. HINT UNTUK PASSWORD
                  onEditingComplete: () => _login(), // Tekan Enter di keyboard langsung login
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], foregroundColor: Colors.white),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Masuk', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 15),

                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  ),
                  child: const Text('Belum punya akun? Daftar di sini', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}