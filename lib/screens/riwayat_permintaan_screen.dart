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

  // FUNGSI YANG DIPERBARUI: Standar dengan Admin (Tinggi Dibatasi & Zoom Interaktif)
  Widget _buildImageWidget(String? imageUrl, BuildContext context) {
    if (imageUrl == null || imageUrl.isEmpty || imageUrl == 'null') {
      return const SizedBox.shrink(); // Sembunyikan ruang jika tidak ada foto
    }

    void tampilkanFotoPenuh(Widget imageWidget) {
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
                maxScale: 4.0,
                child: imageWidget,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget imageContent;

    if (imageUrl.startsWith('http')) {
      imageContent = Image.network(
        imageUrl,
        width: double.infinity,
        height: 120, // BATAS TINGGI GAMBAR
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 50, color: Colors.grey),
      );
    } else {
      try {
        String cleanBase64 = imageUrl.replaceAll(RegExp(r'\s+'), '');
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }
        while (cleanBase64.length % 4 != 0) {
          cleanBase64 += '=';
        }

        Uint8List decodedBytes = base64Decode(cleanBase64);

        imageContent = Image.memory(
          decodedBytes,
          width: double.infinity,
          height: 120, // BATAS TINGGI GAMBAR
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 50, color: Colors.grey),
        );
      } catch (e) {
        return const SizedBox.shrink();
      }
    }

    return InkWell(
      onTap: () {
        Widget fullImage = imageUrl.startsWith('http')
            ? Image.network(imageUrl)
            : Image.memory(base64Decode(_cleanBase64(imageUrl)));
        tampilkanFotoPenuh(fullImage);
      },
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.hardEdge,
        child: imageContent,
      ),
    );
  }

  String _cleanBase64(String base64String) {
    String cleaned = base64String.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.contains(',')) cleaned = cleaned.split(',').last;
    while (cleaned.length % 4 != 0) cleaned += '=';
    return cleaned;
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
        title: const Text('Riwayat Laporan & Permintaan', style: TextStyle(fontSize: 16)),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 70, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text('Belum ada riwayat laporan/permintaan.', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
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
              
              // PERBAIKAN BUG GAMBAR: Mengecek 'imageUrl' DAN 'foto_bukti'
              String fotoUrl = data['imageUrl'] ?? data['foto_bukti'] ?? ''; 

              bool isPermintaan = tingkatKerusakan == 'Pengajuan Baru';
              Color statusColor = status == 'Disetujui' ? Colors.green : (status == 'Ditolak' ? Colors.red : Colors.orange);

              return Card(
                elevation: 3,
                shadowColor: Colors.grey.withOpacity(0.3),
                margin: const EdgeInsets.only(bottom: 16),
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
                                const SizedBox(height: 4),
                                Text(
                                  isPermintaan ? 'Permintaan Barang' : 'Laporan Kerusakan ($tingkatKerusakan)',
                                  style: TextStyle(
                                    color: isPermintaan ? Colors.blue[700] : Colors.red[700],
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold
                                  )
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Jumlah: $jumlah Unit', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[800])),
                      const SizedBox(height: 2),
                      Text('Keterangan: $keterangan', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      
                      // Memanggil widget gambar yang sudah dirapikan ukurannya
                      _buildImageWidget(fotoUrl, context), 
                      
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text('Dikirim: ${_formatWaktu(createdAt)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
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