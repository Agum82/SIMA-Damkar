import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RiwayatAdminScreen extends StatelessWidget {
  const RiwayatAdminScreen({super.key});

  // Helper untuk menampilkan gambar Base64 pada riwayat
  Widget _buildBase64Image(String base64String) {
    if (base64String.isEmpty) return const SizedBox.shrink();
    try {
      Uint8List decodedBytes = base64Decode(base64String);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          decodedBytes,
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Mengambil data dari koleksi laporan_kerusakan secara real-time
        stream: FirebaseFirestore.instance.collection('laporan_kerusakan').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 70, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('Belum ada riwayat transaksi.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          // Filter secara lokal: Hanya tampilkan data yang statusnya sudah diproses (Disetujui / Ditolak)
          final riwayatList = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'Menunggu';
            return status != 'Menunggu';
          }).toList();

          if (riwayatList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 70, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('Belum ada riwayat transaksi.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: riwayatList.length,
            itemBuilder: (context, index) {
              final doc = riwayatList[index];
              final data = doc.data() as Map<String, dynamic>;

              String namaBarang = data['namaBarang'] ?? 'Tanpa Nama';
              String jumlah = data['jumlah']?.toString() ?? '0';
              String tingkatKerusakan = data['tingkatKerusakan'] ?? 'Sedang';
              String status = data['status'] ?? '-';
              String keterangan = data['keterangan'] ?? 'Tidak ada keterangan';
              String base64Image = data['imageUrl'] ?? '';
              String namaPelanggan = data['namaPelanggan'] ?? 'UPT / Pos';

              Color statusColor = status == 'Disetujui' ? Colors.green : Colors.red;

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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Pengaju: $namaPelanggan', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('Tingkat Kerusakan: $tingkatKerusakan'),
                      Text('Jumlah: $jumlah Unit'),
                      Text('Keterangan: $keterangan'),
                      
                      if (base64Image.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildBase64Image(base64Image),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}