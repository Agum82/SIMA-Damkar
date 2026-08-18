import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GudangBarangScreen extends StatefulWidget {
  const GudangBarangScreen({super.key});

  @override
  State<GudangBarangScreen> createState() => _GudangBarangScreenState();
}

class _GudangBarangScreenState extends State<GudangBarangScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final Set<String> _selectedIds = {}; // Menyimpan ID barang yang dicentang untuk hapus banyak
  bool _isSelectionMode = false;

  // Helper untuk merender gambar dari string Base64
  Widget _buildBase64Image(String base64String) {
    if (base64String.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Text('Tidak ada foto prasarana', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
      );
    }

    try {
      Uint8List decodedBytes = base64Decode(base64String);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          decodedBytes,
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 140,
            width: double.infinity,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          ),
        ),
      );
    } catch (e) {
      return Container(
        height: 140,
        width: double.infinity,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      );
    }
  }

  // Fungsi untuk menampilkan Dialog Edit / Update Data Barang
  void _tampilkanFormEdit(BuildContext context, String docId, Map<String, dynamic> currentData) {
    final TextEditingController namaController = TextEditingController(text: currentData['nama'] ?? '');
    final TextEditingController kategoriController = TextEditingController(text: currentData['kategori'] ?? '');
    final TextEditingController jumlahController = TextEditingController(text: currentData['jumlah']?.toString() ?? '0');
    final TextEditingController statusController = TextEditingController(text: currentData['status'] ?? 'Baik');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Edit / Update Barang Gudang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: 'Nama Barang', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: kategoriController,
                  decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: jumlahController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jumlah Stok', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: statusController,
                  decoration: const InputDecoration(labelText: 'Status (Contoh: Baik / Perlu Perawatan)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], foregroundColor: Colors.white),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('gudang_barang').doc(docId).update({
                    'nama': namaController.text.trim(),
                    'kategori': kategoriController.text.trim(),
                    'jumlah': int.tryParse(jumlahController.text.trim()) ?? 0,
                    'status': statusController.text.trim(),
                  });

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data barang berhasil diperbarui!'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal memperbarui: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Simpan Perubahan'),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menghapus banyak barang sekaligus
  Future<void> _deleteSelected() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus ${_selectedIds.length} barang terpilih?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      for (String id in _selectedIds) {
        await FirebaseFirestore.instance.collection('gudang_barang').doc(id).delete();
      }
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barang terpilih berhasil dihapus!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: _isSelectionMode 
            ? Text('${_selectedIds.length} barang dipilih', style: const TextStyle(fontSize: 16)) 
            : const Text('Gudang Barang Prasarana'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Hapus Terpilih',
              onPressed: _deleteSelected,
            ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              }),
            ),
        ],
      ),
      body: Column(
        children: [
          // Kolom Pencarian
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari nama barang prasarana...',
                prefixIcon: const Icon(Icons.search, color: Colors.red),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('gudang_barang').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Belum ada data barang di gudang.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  );
                }

                // Filter data berdasarkan input pencarian
                var docs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String nama = data['nama']?.toString().toLowerCase() ?? '';
                  return nama.contains(_searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Barang tidak ditemukan.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;

                    String nama = data['nama'] ?? 'Tanpa Nama';
                    String kategori = data['kategori'] ?? 'Lainnya';
                    String jumlah = data['jumlah']?.toString() ?? '0';
                    String status = data['status'] ?? 'Baik';
                    String base64Image = data['imageUrl'] ?? '';
                    bool isSelected = _selectedIds.contains(doc.id);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isSelected ? Colors.red : Colors.transparent, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Checkbox untuk mode pilihan banyak (multi-select)
                                Checkbox(
                                  value: isSelected,
                                  activeColor: Colors.red[800],
                                  onChanged: (val) {
                                    setState(() {
                                      if (val!) {
                                        _selectedIds.add(doc.id);
                                        _isSelectionMode = true;
                                      } else {
                                        _selectedIds.remove(doc.id);
                                        if (_selectedIds.isEmpty) _isSelectionMode = false;
                                      }
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    nama,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                // Tombol Edit / Update
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                  tooltip: 'Edit Barang',
                                  onPressed: () => _tampilkanFormEdit(context, doc.id, data),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Informasi Detail Stok & Kategori
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Kategori: $kategori', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                  Text('Jumlah Stok: $jumlah Unit', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500)),
                                  Text('Status: $status', style: TextStyle(color: status == 'Baik' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Tampilan Gambar Barang (Base64)
                            _buildBase64Image(base64Image),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}