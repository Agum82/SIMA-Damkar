import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RiwayatAdminScreen extends StatelessWidget {
  const RiwayatAdminScreen({super.key});

  // Helper pembersih Base64
  String _cleanBase64(String base64String) {
    String cleaned = base64String.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.contains(',')) cleaned = cleaned.split(',').last;
    while (cleaned.length % 4 != 0) cleaned += '=';
    return cleaned;
  }

  // FUNGSI YANG DIPERBARUI: Standar dengan layar lain (Tinggi dibatasi & Zoom Interaktif)
  Widget _buildImageWidget(String? imageUrl, BuildContext context) {
    if (imageUrl == null || imageUrl.isEmpty || imageUrl == 'null') {
      return const SizedBox.shrink(); // Sembunyikan jika tidak ada foto
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
        Uint8List decodedBytes = base64Decode(_cleanBase64(imageUrl));
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
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.hardEdge,
        child: imageContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Riwayat Transaksi', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Mengambil data dari koleksi laporan_kerusakan secara real-time
        stream: FirebaseFirestore.instance
            .collection('laporan_kerusakan')
            .orderBy('createdAt', descending: true) // Urutkan dari yang terbaru
            .snapshots(),
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
              String namaPelanggan = data['namaPelanggan'] ?? 'UPT / Pos';
              
              // PERBAIKAN BUG GAMBAR: Mengecek 'imageUrl' DAN 'foto_bukti'
              String fotoUrl = data['imageUrl'] ?? data['foto_bukti'] ?? '';

              Color statusColor = status == 'Disetujui' ? Colors.green : Colors.red;

              return Card(
                elevation: 3,
                shadowColor: Colors.grey.withOpacity(0.3),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
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
                      Text('Pengaju: $namaPelanggan', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('Tingkat Kerusakan: $tingkatKerusakan', style: TextStyle(color: Colors.grey[800])),
                      Text('Jumlah: $jumlah Unit', style: TextStyle(color: Colors.grey[800])),
                      Text('Keterangan: $keterangan', style: TextStyle(color: Colors.grey[800])),
                      
                      // Pemanggilan Widget Gambar 
                      _buildImageWidget(fotoUrl, context),
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