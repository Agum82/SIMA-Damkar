import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PermintaanPosScreen extends StatefulWidget {
  const PermintaanPosScreen({super.key});

  @override
  State<PermintaanPosScreen> createState() => _PermintaanPosScreenState();
}

class _PermintaanPosScreenState extends State<PermintaanPosScreen> {
  // Fungsi helper untuk menampilkan dialog pop-up di tengah layar
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

  // Fungsi untuk memperbarui status permintaan dan mengurangi stok gudang jika disetujui
  Future<void> _updateStatusPermintaan(String docId, String statusBaru, String namaBarangDiminta, int jumlahDiminta) async {
    try {
      // 1. Jika disetujui, kurangi stok barang di gudang secara otomatis
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

          // Update stok di gudang
          await FirebaseFirestore.instance
              .collection('gudang_barang')
              .doc(gudangDoc.id)
              .update({'jumlah': stokBaru});
        }
      }

      // 2. Update status pada dokumen laporan/permintaan
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        title: const Text('Permintaan Masuk dari Pos', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        // Ini akan memunculkan tanda panah di kiri atas untuk kembali
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Mengambil data secara real-time dari Firestore khusus yang statusnya 'Menunggu' dari Pos
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

          // Filter data secara lokal untuk memastikan hanya menampilkan dari 'Pos'
          final daftarPermintaanPos = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            String namaPelanggan = (data['namaPelanggan'] ?? data['role'] ?? '').toString().toLowerCase();
            return namaPelanggan.contains('pos');
          }).toList();

          if (daftarPermintaanPos.isEmpty) {
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
              String imageUrl = data['imageUrl'] ?? '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaPelanggan.toUpperCase(), 
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)
                      ),
                      const SizedBox(height: 4),
                      Text(namaBarang, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Jumlah: $jumlah Unit'),
                      Text('Keterangan: $keterangan'),
                      
                      // Tampilkan foto jika ada lampiran
                      if (imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _updateStatusPermintaan(doc.id, 'Ditolak', namaBarang, jumlah),
                            child: const Text('Tolak', style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _updateStatusPermintaan(doc.id, 'Disetujui', namaBarang, jumlah),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, 
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Setujui'),
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