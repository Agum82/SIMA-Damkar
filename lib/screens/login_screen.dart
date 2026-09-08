import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
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

  // Variabel untuk menampung pesan error spesifik per kolom
  String? _emailError;
  String? _passwordError;

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

  Future<void> _resetPassword(String email) async {
    if (email.isEmpty) {
      setState(() => _emailError = 'Harap masukkan email terlebih dahulu');
      return;
    }
    
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan reset password telah dikirim ke email Anda.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim email: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _tampilkanDialogLupaPassword(BuildContext context) {
    final TextEditingController emailResetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Lupa Password?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Masukkan email yang terdaftar, kami akan mengirimkan tautan untuk mengatur ulang kata sandi.'),
              const SizedBox(height: 15),
              TextField(
                controller: emailResetController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                _resetPassword(emailResetController.text.trim());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
              child: const Text('Kirim Tautan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _login() async {
    TextInput.finishAutofillContext(); 

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Reset error sebelum validasi ulang
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    bool adaError = false;
    if (email.isEmpty) {
      setState(() => _emailError = 'Email harus diisi!');
      adaError = true;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password harus diisi!');
      adaError = true;
    }

    if (adaError) return;

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
      setState(() {
        // Pemetaan error Firebase langsung ke kolom input yang sesuai
        if (e.code == 'user-not-found' || e.code == 'invalid-email') {
          _emailError = 'Email tidak terdaftar atau format salah.';
        } else if (e.code == 'wrong-password') {
          _passwordError = 'Password yang Anda masukkan salah.';
        } else if (e.code == 'invalid-credential') {
          // Firebase versi baru sering menggabungkan error salah email/password menjadi invalid-credential
          _emailError = 'Periksa kembali email atau password Anda.';
          _passwordError = 'Periksa kembali email atau password Anda.';
        } else {
          _tampilkanDialog('Error: ${e.message}');
        }
      });
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
          child: AutofillGroup(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_fire_department, size: 80, color: Colors.red[600]),
                const SizedBox(height: 20),
                const Text('Sistem Operasional Sapras', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Text('Dinas Pemadam Kebakaran Kab. Garut', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),

                // TEXTFIELD EMAIL DENGAN ERROR TEXT
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: 'Email', 
                    border: const OutlineInputBorder(), 
                    prefixIcon: const Icon(Icons.email),
                    errorText: _emailError, // <-- Garis dan teks merah muncul di sini jika ada error
                  ),
                ),
                const SizedBox(height: 15),

                // TEXTFIELD PASSWORD DENGAN ERROR TEXT
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  onEditingComplete: () => _login(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    errorText: _passwordError, // <-- Garis dan teks merah muncul di sini jika ada error
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // TOMBOL MASUK
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
                const SizedBox(height: 10),

                // TOMBOL LUPA PASSWORD
                TextButton(
                  onPressed: () => _tampilkanDialogLupaPassword(context),
                  child: Text(
                    'Lupa Password?',
                    style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
                  ),
                ),

                // TOMBOL DAFTAR
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