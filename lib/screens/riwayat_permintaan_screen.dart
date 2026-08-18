import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RiwayatPermintaanScreen extends StatefulWidget {
  const RiwayatPermintaanScreen({super.key});

  @override
  State<RiwayatPermintaanScreen> createState() => _RiwayatPermintaanScreenState();
}

class _RiwayatPermintaanScreenState extends State<RiwayatPermintaanScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  String _formatWaktu(Timestamp? timestamp) {
    if (timestamp == null) return 'Waktu tidak tersedia';
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    String currentUserName = 'UPT / Pos';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // PERBAIKAN: Mengaktifkan panah kembali bawaan dan menghapus tombol KEMBALI biru
        automaticallyImplyLeading: true,
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        title: const Text('Riwayat Permintaan & Laporan', style: TextStyle(fontSize: 15)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null 
            ? FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots() 
            : null,
        builder: (context, userSnapshot) {
          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            currentUserName = userSnapshot.data!.get('nama') ?? 'UPT / Pos';
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('laporan_kerusakan')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 70, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      const Text('Belum ada riwayat permintaan atau laporan.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                );
              }

              final daftarRiwayat = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                String namaPelanggan = data['namaPelanggan'] ?? '';
                return namaPelanggan.toLowerCase() == currentUserName.toLowerCase();
              }).toList();

              if (daftarRiwayat.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 70, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      const Text('Belum ada riwayat dari akun ini.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: daftarRiwayat.length,
                itemBuilder: (context, index) {
                  final doc = daftarRiwayat[index];
                  final data = doc.data() as Map<String, dynamic>;

                  String namaBarang = data['namaBarang'] ?? 'Tanpa Nama';
                  int jumlah = data['jumlah'] ?? 0;
                  String keterangan = data['keterangan'] ?? 'Tidak ada keterangan';
                  String status = data['status'] ?? 'Menunggu';
                  Timestamp? createdAt = data['createdAt'] as Timestamp?;
                  String? fotoUrl = data['fotoUrl'];

                  Color statusColor = Colors.orange;
                  if (status == 'Disetujui') statusColor = Colors.green;
                  if (status == 'Ditolak') statusColor = Colors.red;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  namaBarang, 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Jumlah: $jumlah Unit', style: TextStyle(color: Colors.grey[800])),
                          Text('Keterangan: $keterangan', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          
                          // Pembatasan tinggi gambar agar rapi dan tidak terlalu besar
                          if (fotoUrl != null && fotoUrl.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                height: 140,
                                width: double.infinity,
                                child: Image.network(
                                  fotoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Text('Gagal memuat gambar', style: TextStyle(color: Colors.red, fontSize: 12)),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                'Waktu: ${_formatWaktu(createdAt)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}