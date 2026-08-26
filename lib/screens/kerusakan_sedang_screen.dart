import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class KerusakanSedangScreen extends StatefulWidget {
  const KerusakanSedangScreen({super.key});

  @override
  State<KerusakanSedangScreen> createState() => _KerusakanSedangScreenState();
}

class _KerusakanSedangScreenState extends State<KerusakanSedangScreen> {
  
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

  Future<void> _updateStatus(String docId, String statusBaru, String namaBarang) async {
    try {
      await FirebaseFirestore.instance
          .collection('laporan_kerusakan')
          .doc(docId)
          .update({'status': statusBaru});
      
      if (!mounted) return;
      _tampilkanDialog('Laporan "$namaBarang" berhasil di-$statusBaru dan dipindah ke Riwayat!', isBerhasil: true);
    } catch (e) {
      _tampilkanDialog('Gagal memperbarui status: $e');
    }
  }

  // FUNGSI YANG DIPERBARUI: Lebih ramping, hemat tempat, dan bisa di-klik untuk Zoom
  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.isEmpty || imageUrl == 'null') {
      return const SizedBox.shrink(); // Menyembunyikan ruang kosong jika tidak ada foto
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
            height: 100, // Tinggi diperkecil
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
              height: 100, // Tinggi diperkecil
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.amber[800],
        foregroundColor: Colors.white,
        title: const Text('Data Kerusakan Sedang', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('laporan_kerusakan')
            .where('tingkatKerusakan', isEqualTo: 'Sedang')
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
                  Icon(Icons.warning_amber, size: 70, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text('Tidak ada data kerusakan sedang.', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          final daftarRusakSedang = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'Menunggu';
            return status == 'Menunggu';
          }).toList();

          if (daftarRusakSedang.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 70, color: Colors.green[300]),
                  const SizedBox(height: 10),
                  Text('Semua laporan kerusakan sedang telah diproses.', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: daftarRusakSedang.length,
            itemBuilder: (context, index) {
              final doc = daftarRusakSedang[index];
              final data = doc.data() as Map<String, dynamic>;

              String namaBarang = data['namaBarang'] ?? 'Tanpa Nama';
              String jumlah = data['jumlah']?.toString() ?? '0';
              String keterangan = data['keterangan'] ?? 'Tidak ada keterangan';
              String imageUrl = data['imageUrl'] ?? ''; 
              String status = data['status'] ?? 'Menunggu'; 
              String namaPelanggan = data['namaPelanggan'] ?? 'UPT / Pos Tidak Diketahui';
              Timestamp? createdAt = data['createdAt'] as Timestamp?;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.amber, 
                            child: Icon(Icons.warning, color: Colors.white)
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(namaBarang, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('Dari: $namaPelanggan', 
                                     style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text('Jumlah: $jumlah Unit', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500)),
                                Text('Keterangan: $keterangan', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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

                      const SizedBox(height: 16),
                      _buildImageWidget(imageUrl), 
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _updateStatus(doc.id, 'Ditolak', namaBarang),
                            icon: const Icon(Icons.close, color: Colors.red, size: 18),
                            label: const Text('Tolak', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _updateStatus(doc.id, 'Disetujui', namaBarang),
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
}