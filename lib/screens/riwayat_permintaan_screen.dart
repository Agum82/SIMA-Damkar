import 'dart:convert';
import 'dart:typed_data';
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

  // Fungsi universal untuk menampilkan gambar (bisa Base64 atau URL Internet) dengan fitur Zoom
  Widget _buildImageWidget(String imageUrl, BuildContext context) {
    if (imageUrl.isEmpty || imageUrl == 'null') {
      return const SizedBox.shrink(); // Menyembunyikan ruang jika tidak ada foto
    }

    void tampilkanFotoPenuh(Widget imageWidget) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(child: InteractiveViewer(child: imageWidget)),
              Positioned(
                top: 20,
                right: 20,
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

    if (imageUrl.startsWith('http')) {
      return InkWell(
        onTap: () => tampilkanFotoPenuh(Image.network(imageUrl)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl, 
            width: double.infinity, 
            height: 100, // Tinggi dibuat ramping
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
        ),
      );
    } else {
      try {
        String cleanBase64 = imageUrl;
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }
        cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
        
        int padLength = 4 - (cleanBase64.length % 4);
        if (padLength > 0 && padLength < 4) {
           cleanBase64 += '=' * padLength;
        }

        Uint8List decodedBytes = base64Decode(cleanBase64);
        
        return InkWell(
          onTap: () => tampilkanFotoPenuh(Image.memory(decodedBytes)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              decodedBytes, 
              width: double.infinity, 
              height: 100, // Tinggi dibuat ramping
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        );
      } catch (e) {
        return const SizedBox.shrink();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Riwayat')),
        body: const Center(child: Text('Anda belum login')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        title: const Text('Riwayat Laporan & Permintaan', style: TextStyle(fontSize: 15)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('laporan_kerusakan')
            .where('userId', isEqualTo: user!.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada riwayat laporan/permintaan.'));
          }

          final daftarRiwayat = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: daftarRiwayat.length,
            itemBuilder: (context, index) {
              final data = daftarRiwayat[index].data() as Map<String, dynamic>;

              String namaBarang = data['namaBarang'] ?? 'Tanpa Nama';
              int jumlah = data['jumlah'] ?? 0;
              String keterangan = data['keterangan'] ?? 'Tidak ada keterangan';
              String status = data['status'] ?? 'Menunggu';
              String tingkatKerusakan = data['tingkatKerusakan'] ?? '';
              Timestamp? createdAt = data['createdAt'] as Timestamp?;
              String fotoUrl = data['imageUrl'] ?? ''; // Diambil dan diolah oleh widget

              bool isPermintaan = tingkatKerusakan == 'Pengajuan Baru';
              Color statusColor = status == 'Disetujui' ? Colors.green : (status == 'Ditolak' ? Colors.red : Colors.orange);

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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(namaBarang, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  isPermintaan ? 'Permintaan Barang' : 'Laporan Kerusakan ($tingkatKerusakan)',
                                  style: TextStyle(
                                    color: isPermintaan ? Colors.blue[700] : Colors.red[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold
                                  )
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Jumlah: $jumlah Unit'),
                      Text('Keterangan: $keterangan', style: TextStyle(color: Colors.grey[700])),
                      
                      const SizedBox(height: 10),
                      // Memanggil widget gambar pintar yang baru
                      _buildImageWidget(fotoUrl, context), 
                      
                      const SizedBox(height: 10),
                      Text('Dikirim: ${_formatWaktu(createdAt)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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