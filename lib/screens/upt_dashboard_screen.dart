import 'package:flutter/material.dart';
import 'pengajuan_barang_screen.dart';
import 'lapor_rusak_screen.dart';
import 'riwayat_permintaan_screen.dart';
import 'upt_profile_screen.dart'; // Import halaman profil UPT/Pos

class UptDashboardScreen extends StatefulWidget {
  const UptDashboardScreen({super.key});

  @override
  State<UptDashboardScreen> createState() => _UptDashboardScreenState();
}

class _UptDashboardScreenState extends State<UptDashboardScreen> {
  void _logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        actions: [
          // TOMBOL PROFIL UPT/POS
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Profil UPT/Pos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UptProfileScreen()),
              );
            },
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
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.business, size: 30, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'UPT / POS',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          SizedBox(height: 4),
                          Text(
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