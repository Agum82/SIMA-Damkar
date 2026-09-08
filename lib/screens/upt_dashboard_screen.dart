import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pengajuan_barang_screen.dart';
import 'lapor_rusak_screen.dart';
import 'riwayat_permintaan_screen.dart';
import 'upt_profile_screen.dart'; 

class UptDashboardScreen extends StatefulWidget {
  const UptDashboardScreen({super.key});

  @override
  State<UptDashboardScreen> createState() => _UptDashboardScreenState();
}

class _UptDashboardScreenState extends State<UptDashboardScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  
  String _namaUpt = 'UPT / POS';
  String _photoUrl = '';
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _ambilDataProfil();
  }

  // Fungsi untuk mengambil nama dan foto profil dari Firestore
  Future<void> _ambilDataProfil() async {
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _namaUpt = data['nama'] ?? 'UPT / POS';
              _photoUrl = data['photoUrl'] ?? '';
              _isLoadingProfile = false;
            });
          }
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingProfile = false);
      }
    }
  }

  // Fungsi aman untuk mendeteksi URL atau Base64
  ImageProvider? _getAvatarImage() {
    if (_photoUrl.isEmpty) return null;
    
    // Jika berupa link URL internet (data lama)
    if (_photoUrl.startsWith('http')) {
      return NetworkImage(_photoUrl);
    } 
    
    // Jika berupa teks Base64 (data baru)
    try {
      Uint8List decodedBytes = base64Decode(_photoUrl);
      return MemoryImage(decodedBytes);
    } catch (e) {
      return null;
    }
  }

  // Fungsi untuk menampilkan preview foto ukuran penuh
  void _lihatFotoPenuh() {
    if (_photoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada foto profil.')),
      );
      return;
    }

    Widget imageWidget;
    if (_photoUrl.startsWith('http')) {
      imageWidget = Image.network(_photoUrl, fit: BoxFit.contain);
    } else {
      Uint8List decodedBytes = base64Decode(_photoUrl);
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

  void _logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        title: const Text('Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        actions: [
          // TOMBOL PROFIL UPT/POS DI APPBAR
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UptProfileScreen()),
              );
              _ambilDataProfil(); 
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white24,
                backgroundImage: _getAvatarImage(),
                child: _getAvatarImage() == null ? const Icon(Icons.account_circle, color: Colors.white) : null,
              ),
            ),
          ),
          // TOMBOL LOGOUT
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar Akun',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // PROFIL PELANGGAN (UPT/POS)
            // ==========================================
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Lingkaran foto profil saja yang bisa diklik untuk preview
                    GestureDetector(
                      onTap: _lihatFotoPenuh,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.red[300],
                        backgroundImage: _getAvatarImage(),
                        child: _getAvatarImage() == null 
                            ? const Icon(Icons.business, size: 30, color: Colors.white) 
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _isLoadingProfile 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(
                                _namaUpt,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          const SizedBox(height: 4),
                          const Text(
                            'Dinas Pemadam Kebakaran Kab. Garut',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // ==========================================
            // MENU PELAYANAN
            // ==========================================
            const Text('Menu Pelayanan Prasarana', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // Menu 1: Ajukan Permintaan
            Card(
              elevation: 1,
              color: const Color(0xFFFCF5F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), 
                side: BorderSide(color: Colors.grey.shade300)
              ),
              child: ListTile(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PengajuanBarangScreen())),
                leading: CircleAvatar(backgroundColor: Colors.red.withOpacity(0.2), child: const Icon(Icons.add_circle, color: Colors.redAccent)),
                title: const Text('Ajukan Permintaan', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Form pengajuan barang prasarana baru', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),

            // Menu 2: Lapor Kerusakan
            Card(
              elevation: 1,
              color: const Color(0xFFFFF9F0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300)
              ),
              child: ListTile(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LaporRusakScreen())),
                leading: CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.2), child: const Icon(Icons.broken_image, color: Colors.orange)),
                title: const Text('Lapor Kerusakan', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Form pelaporan barang rusak', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),

            // Menu 3: Riwayat Permintaan
            Card(
              elevation: 1,
              color: const Color(0xFFF0F5FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300)
              ),
              child: ListTile(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatPermintaanScreen())),
                leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.2), child: const Icon(Icons.history, color: Colors.blueAccent)),
                title: const Text('Riwayat Permintaan', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Lihat status pengajuan & laporan Anda', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}