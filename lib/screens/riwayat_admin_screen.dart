import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RiwayatAdminScreen extends StatefulWidget {
  const RiwayatAdminScreen({super.key});

  @override
  State<RiwayatAdminScreen> createState() => _RiwayatAdminScreenState();
}

class _RiwayatAdminScreenState extends State<RiwayatAdminScreen> {
  // Variabel untuk fitur Multi-Select Delete
  bool _isSelectionMode = false;
  Set<String> _selectedDocs = {};

  // Controller dan variabel untuk fitur Pencarian
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi toggle pilihan dokumen
  void _toggleSelection(String docId) {
    setState(() {
      if (_selectedDocs.contains(docId)) {
        _selectedDocs.remove(docId);
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
        content: Text('Apakah Anda yakin ingin menghapus ${_selectedDocs.length} riwayat transaksi? Data yang dihapus tidak dapat dikembalikan.'),
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

  // Helper pembersih Base64
  String _cleanBase64(String base64String) {
    String cleaned = base64String.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.contains(',')) cleaned = cleaned.split(',').last;
    while (cleaned.length % 4 != 0) cleaned += '=';
    return cleaned;
  }

  // FUNGSI GAMBAR: Standar dengan layar lain (Tinggi dibatasi & Zoom Interaktif)
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
        Uint8List decodedBytes = base64Decode(_cleanBase64(imageUrl));
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('laporan_kerusakan')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        
        List<String> filteredDocIds = [];
        List<QueryDocumentSnapshot> riwayatList = [];

        if (snapshot.hasData) {
          // 1. Filter dasar: Hanya data yang bukan status 'Menunggu'
          riwayatList = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'Menunggu';
            return status != 'Menunggu';
          }).toList();

          // 2. Filter tambahan berdasarkan teks pencarian
          if (_searchQuery.isNotEmpty) {
            String query = _searchQuery.toLowerCase();
            riwayatList = riwayatList.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              String namaBarang = (data['namaBarang'] ?? '').toString().toLowerCase();
              String namaPelanggan = (data['namaPelanggan'] ?? '').toString().toLowerCase();
              String status = (data['status'] ?? '').toString().toLowerCase();
              String keterangan = (data['keterangan'] ?? '').toString().toLowerCase();

              return namaBarang.contains(query) ||
                     namaPelanggan.contains(query) ||
                     status.contains(query) ||
                     keterangan.contains(query);
            }).toList();
          }

          filteredDocIds = riwayatList.map((doc) => doc.id).toList();
        }

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: _isSelectionMode ? Colors.blueGrey[800] : Colors.red[800],
            foregroundColor: Colors.white,
            title: _isSelectionMode 
                ? Text('${_selectedDocs.length} Terpilih', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                : const Text('Riwayat Transaksi', style: TextStyle(fontSize: 16)),
            centerTitle: !_isSelectionMode,
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
                : null,
            actions: _isSelectionMode
                ? [
                    IconButton(
                      icon: Icon(
                        _selectedDocs.length == filteredDocIds.length ? Icons.deselect : Icons.select_all,
                      ),
                      tooltip: 'Pilih Semua',
                      onPressed: () {
                        setState(() {
                          if (_selectedDocs.length == filteredDocIds.length) {
                            _selectedDocs.clear();
                            _isSelectionMode = false;
                          } else {
                            _selectedDocs.addAll(filteredDocIds);
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
          body: Column(
            children: [
              // KOTAK PENCARIAN (SEARCH BAR)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari barang, pengaju, atau status...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red.shade800, width: 1.5),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              // DAFTAR RIWAYAT
              Expanded(
                child: () {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                  }

                  if (riwayatList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty ? Icons.search_off : Icons.history, 
                            size: 70, 
                            color: Colors.grey[400]
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _searchQuery.isNotEmpty 
                                ? 'Tidak ada riwayat yang cocok.' 
                                : 'Belum ada riwayat transaksi.',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: riwayatList.length,
                    itemBuilder: (context, index) {
                      final doc = riwayatList[index];
                      final docId = doc.id;
                      final data = doc.data() as Map<String, dynamic>;

                      String namaBarang = data['namaBarang'] ?? 'Tanpa Nama';
                      String jumlah = data['jumlah']?.toString() ?? '0';
                      String tingkatKerusakan = data['tingkatKerusakan'] ?? 'Sedang';
                      String status = data['status'] ?? '-';
                      String keterangan = data['keterangan'] ?? 'Tidak ada keterangan';
                      String namaPelanggan = data['namaPelanggan'] ?? 'UPT / Pos';
                      
                      String fotoUrl = data['imageUrl'] ?? data['foto_bukti'] ?? '';
                      Color statusColor = status == 'Disetujui' ? Colors.green : Colors.red;
                      
                      bool isSelected = _selectedDocs.contains(docId);

                      return Card(
                        elevation: isSelected ? 6 : 3,
                        shadowColor: Colors.grey.withOpacity(0.3),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? Colors.red.shade800 : Colors.transparent, 
                            width: 2
                          ),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              setState(() {
                                _isSelectionMode = true;
                                _selectedDocs.add(docId);
                              });
                            }
                          },
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
                                      
                                      _buildImageWidget(fotoUrl, context),
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
              ),
            ],
          ),
        );
      },
    );
  }
}