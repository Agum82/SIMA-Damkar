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
  
  // Variabel untuk fitur Multi-Select Delete
  bool _isSelectionMode = false;
  Set<String> _selectedDocs = {};

  String _formatWaktu(Timestamp? timestamp) {
    if (timestamp == null) return 'Waktu tidak tersedia';
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
  }

  // Fungsi toggle pilihan dokumen
  void _toggleSelection(String docId) {
    setState(() {
      if (_selectedDocs.contains(docId)) {
        _selectedDocs.remove(docId);
        // Jika sudah tidak ada yang dipilih, matikan mode seleksi
        if (_selectedDocs.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedDocs.add(docId);
      }
    });
  }

  // Fungsi hapus riwayat secara massal (Batch Delete)
  Future<void> _hapusRiwayatTerpilih() async {
    bool konfirmasi = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Hapus Riwayat?'),
        content: Text('Apakah Anda yakin ingin menghapus ${_selectedDocs.length} riwayat yang dipilih? Data yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    ) ?? false;

    if (!konfirmasi) return;

    try {
      // Menggunakan WriteBatch agar proses hapus banyak dokumen berjalan ringan dan aman
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (String docId in _selectedDocs) {
        DocumentReference docRef = FirebaseFirestore.instance.collection('laporan_kerusakan').doc(docId);
        batch.delete(docRef);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Riwayat berhasil dihapus'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSelectionMode = false;
          _selectedDocs.clear();
        });
      }
    }
  }

  // FUNGSI GAMBAR: Standar dengan Admin (Tinggi Dibatasi & Zoom Interaktif)
  Widget _buildImageWidget(String? imageUrl, BuildContext context) {
    if (imageUrl == null || imageUrl.isEmpty || imageUrl == 'null') {
      return const SizedBox.shrink(); 
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
        height: 120, 
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
          height: 120, 
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

    // Membungkus Scaffold dengan StreamBuilder agar AppBar bisa membaca jumlah data
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('laporan_kerusakan')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        
        // Menyimpan semua ID dokumen yang ada saat ini untuk fitur "Pilih Semua"
        List<String> allDocIds = snapshot.hasData ? snapshot.data!.docs.map((e) => e.id).toList() : [];

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: _isSelectionMode ? Colors.blueGrey[800] : Colors.red[800],
            foregroundColor: Colors.white,
            // Jika mode seleksi aktif, ganti judul jadi jumlah yang dipilih
            title: _isSelectionMode 
                ? Text('${_selectedDocs.length} Terpilih', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                : const Text('Riwayat Laporan & Permintaan', style: TextStyle(fontSize: 16)),
            centerTitle: !_isSelectionMode,
            
            // Tombol Kiri AppBar (Close Selection)
            leading: _isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedDocs.clear();
                      });
                    },
                  )
                : null, // Menggunakan tombol back bawaan

            // Tombol Kanan AppBar (Select All & Delete)
            actions: _isSelectionMode
                ? [
                    IconButton(
                      icon: Icon(
                        _selectedDocs.length == allDocIds.length ? Icons.deselect : Icons.select_all,
                      ),
                      tooltip: 'Pilih Semua',
                      onPressed: () {
                        setState(() {
                          if (_selectedDocs.length == allDocIds.length) {
                            _selectedDocs.clear();
                            _isSelectionMode = false;
                          } else {
                            _selectedDocs.addAll(allDocIds);
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Hapus',
                      onPressed: _selectedDocs.isEmpty ? null : _hapusRiwayatTerpilih,
                    ),
                  ]
                : null,
          ),
          body: () {
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
                final docId = daftarRiwayat[index].id;
                final data = daftarRiwayat[index].data() as Map<String, dynamic>;

                String namaBarang = data['namaBarang'] ?? 'Tanpa Nama';
                int jumlah = data['jumlah'] ?? 0;
                String keterangan = data['keterangan'] ?? 'Tidak ada keterangan';
                String status = data['status'] ?? 'Menunggu';
                String tingkatKerusakan = data['tingkatKerusakan'] ?? '';
                Timestamp? createdAt = data['createdAt'] as Timestamp?;
                
                String fotoUrl = data['imageUrl'] ?? data['foto_bukti'] ?? ''; 
                bool isPermintaan = tingkatKerusakan == 'Pengajuan Baru';
                Color statusColor = status == 'Disetujui' ? Colors.green : (status == 'Ditolak' ? Colors.red : Colors.orange);
                
                bool isSelected = _selectedDocs.contains(docId);

                return Card(
                  elevation: isSelected ? 6 : 3, // Tambah bayangan jika dipilih
                  shadowColor: Colors.grey.withOpacity(0.3),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? Colors.red.shade800 : Colors.transparent, 
                      width: 2
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    // Logika ketika kartu ditahan (Long Press)
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        setState(() {
                          _isSelectionMode = true;
                          _selectedDocs.add(docId);
                        });
                      }
                    },
                    // Logika ketika kartu diklik (Tap) biasa
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(docId);
                      }
                    },
                    child: Container(
                      color: isSelected ? Colors.red.shade50 : Colors.white,
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Menampilkan Checkbox jika dalam mode seleksi
                          if (_isSelectionMode)
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0, top: 8.0),
                              child: Checkbox(
                                value: isSelected,
                                activeColor: Colors.red[800],
                                onChanged: (value) => _toggleSelection(docId),
                              ),
                            ),
                            
                          Expanded(
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
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }(),
        );
      },
    );
  }
}