import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PermintaanPosScreen extends StatefulWidget {
  const PermintaanPosScreen({super.key});

  @override
  State<PermintaanPosScreen> createState() => _PermintaanPosScreenState();
}

class _PermintaanPosScreenState extends State<PermintaanPosScreen> {
  String _formatWaktu(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    return DateFormat('dd-MM-yyyy HH:mm').format(timestamp.toDate());
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

  Future<void> _updateStatusPermintaan(String docId, String statusBaru, String namaBarangDiminta, int jumlahDiminta) async {
    try {
      if (statusBaru == 'Disetujui') {
        var gudangQuery = await FirebaseFirestore.instance
            .collection('gudang_barang')
            .where('nama', isEqualTo: namaBarangDiminta)
            .get();

        if (gudangQuery.docs.isNotEmpty) {
          var gudangDoc = gudangQuery.docs.first;
          int stokSekarang = gudangDoc['jumlah'] ?? 0;
          int stokBaru = stokSekarang - jumlahDiminta;
          if (stokBaru < 0) stokBaru = 0;

          await FirebaseFirestore.instance
              .collection('gudang_barang')
              .doc(gudangDoc.id)
              .update({'jumlah': stokBaru});
        }
      }

      await FirebaseFirestore.instance
          .collection('laporan_kerusakan')
          .doc(docId)
          .update({'status': statusBaru});

      if (!mounted) return;
      _tampilkanDialog('Permintaan berhasil ${statusBaru.toLowerCase()}!', isBerhasil: true);
    } catch (e) {
      _tampilkanDialog('Gagal memperbarui status: $e');
    }
  }

  // FUNGSI YANG DIPERBARUI: Pembatasan Tinggi Card & Zoom Interaktif
  Widget _buildImageWidget(String? imageUrl) {
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
        margin: const EdgeInsets.only(top: 8),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        title: const Text('Permintaan Masuk dari Pos', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('laporan_kerusakan')
            .where('status', isEqualTo: 'Menunggu')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final daftarPermintaanPos = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            String tingkatKerusakan = data['tingkatKerusakan'] ?? '';
            String namaPelanggan = (data['namaPelanggan'] ?? data['role'] ?? '').toString().toLowerCase();
            
            return tingkatKerusakan == 'Pengajuan Baru' && namaPelanggan.contains('pos');
          }).toList();

          if (daftarPermintaanPos.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: daftarPermintaanPos.length,
            itemBuilder: (context, index) {
              final doc = daftarPermintaanPos[index];
              final data = doc.data() as Map<String, dynamic>;

              String namaPelanggan = data['namaPelanggan'] ?? data['role'] ?? 'Pos Pemadam';
              String namaBarang = data['namaBarang'] ?? 'Tanpa Nama';
              int jumlah = data['jumlah'] ?? 0;
              String keterangan = data['keterangan'] ?? 'Tidak ada keterangan';
              // Ditambahkan pengecekan foto_bukti untuk berjaga-jaga
              String imageUrl = data['imageUrl'] ?? data['foto_bukti'] ?? '';
              Timestamp? createdAt = data['createdAt'] as Timestamp?;

              return Card(
                elevation: 3,
                shadowColor: Colors.grey.withOpacity(0.3),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.orange.shade50, // Diberi warna latar tipis untuk variasi
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.orange, 
                            child: Icon(Icons.assignment_turned_in, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(namaBarang, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  'Dari: $namaPelanggan', 
                                  style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text('Jumlah: $jumlah Unit', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500)),
                                Text('Keterangan: $keterangan', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Menunggu',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(
                            'Dikirim: ${_formatWaktu(createdAt)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),

                      // Panggilan widget gambar
                      _buildImageWidget(imageUrl),
                      
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _updateStatusPermintaan(doc.id, 'Ditolak', namaBarang, jumlah),
                            icon: const Icon(Icons.close, color: Colors.red, size: 18),
                            label: const Text('Tolak', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _updateStatusPermintaan(doc.id, 'Disetujui', namaBarang, jumlah),
                            icon: const Icon(Icons.check, color: Colors.white, size: 18),
                            label: const Text('Setujui', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text('Tidak ada permintaan masuk dari Pos.', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}