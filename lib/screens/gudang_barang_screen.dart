import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'edit_barang_screen.dart';

class GudangBarangScreen extends StatefulWidget {
  const GudangBarangScreen({super.key});

  @override
  State<GudangBarangScreen> createState() => _GudangBarangScreenState();
}

class _GudangBarangScreenState extends State<GudangBarangScreen> {
  String _searchQuery = '';
  final Set<String> _selectedDocIds = {};
  bool _isSelectionMode = false;

  void _toggleSelectAll(List<QueryDocumentSnapshot> currentDocs) {
    setState(() {
      if (_selectedDocIds.length == currentDocs.length) {
        _selectedDocIds.clear();
        _isSelectionMode = false;
      } else {
        for (var doc in currentDocs) {
          _selectedDocIds.add(doc.id);
        }
        _isSelectionMode = true;
      }
    });
  }

  void _tampilkanDialog(String pesan, {bool isBerhasil = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(isBerhasil ? Icons.check_circle : Icons.error, color: isBerhasil ? Colors.green : Colors.red[800]),
            const SizedBox(width: 8),
            Text(isBerhasil ? 'Berhasil' : 'Peringatan', style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(pesan, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _konfirmasiHapusTerpilih() {
    if (_selectedDocIds.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Barang', style: TextStyle(fontSize: 16)),
        content: Text('Hapus ${_selectedDocIds.length} barang terpilih?', style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              WriteBatch batch = FirebaseFirestore.instance.batch();
              for (String docId in _selectedDocIds) {
                batch.delete(FirebaseFirestore.instance.collection('gudang_barang').doc(docId));
              }
              await batch.commit();
              setState(() { _selectedDocIds.clear(); _isSelectionMode = false; });
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk Mencetak PDF Seluruh Barang beserta Detail Penempatannya
  Future<void> _cetakPdfSemuaBarang(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();

    Set<String> dynamicKeys = {};
    List<Map<String, dynamic>> parsedDataList = [];
    List<String> excludeKeys = ['nama', 'kategori', 'jumlah', 'harga', 'status', 'imageUrl', 'createdAt', 'updatedAt', 'detail', 'Merk / Tipe', 'Nomor Kendaraan'];

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      parsedDataList.add(data);
      data.forEach((key, value) {
        if (!excludeKeys.contains(key) && value != null && value.toString().isNotEmpty && value.toString() != '-') {
          dynamicKeys.add(key);
        }
      });
    }

    List<String> sortedKeys = dynamicKeys.toList()..sort();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('PEMADAM KEBAKARAN KABUPATEN GARUT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text('Laporan Keseluruhan Stok Gudang & Penempatan Prasarana', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (context) {
          List<pw.Widget> headers = [
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Nama Barang', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Kategori', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
          ];

          for (var key in sortedKeys) {
            headers.add(pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(key, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))));
          }

          List<List<pw.Widget>> rows = [];
          for (int i = 0; i < parsedDataList.length; i++) {
            var data = parsedDataList[i];
            List<pw.Widget> row = [
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(data['nama']?.toString() ?? '-', style: const pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(data['kategori']?.toString() ?? '-', style: const pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${data['jumlah'] ?? 0}', style: const pw.TextStyle(fontSize: 8))),
            ];

            for (var key in sortedKeys) {
              String val = data[key]?.toString() ?? '-';
              row.add(pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(val, style: const pw.TextStyle(fontSize: 8))));
            }
            rows.add(row);
          }

          return [
            pw.Table.fromTextArray(
              headers: headers.map((e) => e is pw.Padding ? e.child : e).toList(),
              data: rows.map((row) => row.map((e) => e is pw.Padding ? e.child : e).map((w) => w is pw.Text ? w.text : '').toList()).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFB71C1C)),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Dicetak otomatis dari Sistem SIMA Damkar', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
            pw.Text('Halaman ${context.pageNumber} dari ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Gudang_Damkar_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  void _tampilkanDetailBarang(String docId, Map<String, dynamic> data) {
    String imageUrl = data['imageUrl'] ?? '';
    
    final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    double hargaVal = double.tryParse(data['harga']?.toString() ?? '0') ?? 0.0;
    String formattedHarga = formatRupiah.format(hargaVal);

    List<Widget> detailWidgets = [
      _buildDetailRow('Nama Barang', data['nama']?.toString() ?? '-'),
      const Divider(height: 12),
      _buildDetailRow('Kategori', data['kategori']?.toString() ?? '-'),
      const Divider(height: 12),
      _buildDetailRow('Jumlah Stok', '${data['jumlah'] ?? 0} Unit'),
      const Divider(height: 12),
    ];

    if (hargaVal > 0) {
      detailWidgets.addAll([
        _buildDetailRow('Harga Satuan', formattedHarga),
        const Divider(height: 12),
      ]);
    }

    detailWidgets.add(_buildDetailRow('Status', data['status']?.toString() ?? '-'));
    detailWidgets.add(const Divider(height: 12));

    List<String> excludeKeys = ['nama', 'kategori', 'jumlah', 'harga', 'status', 'imageUrl', 'createdAt', 'updatedAt', 'detail'];
    bool hasExtraDetails = false;

    data.forEach((key, value) {
      if (!excludeKeys.contains(key) && value != null && value.toString().isNotEmpty && value.toString() != '-') {
        if (!hasExtraDetails) {
          detailWidgets.add(const SizedBox(height: 6));
          detailWidgets.add(const Text('Detail / Penempatan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)));
          detailWidgets.add(const SizedBox(height: 4));
          hasExtraDetails = true;
        }
        
        String formattedKey = key[0].toUpperCase() + key.substring(1);
        detailWidgets.add(_buildDetailRow(formattedKey, value.toString()));
        detailWidgets.add(const Divider(thickness: 0.5, height: 10));
      }
    });

    if (imageUrl.isNotEmpty) {
      detailWidgets.add(const SizedBox(height: 8));
      detailWidgets.add(const Text('Foto Prasarana:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)));
      detailWidgets.add(const SizedBox(height: 4));
      detailWidgets.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl.startsWith('http')
              ? Image.network(imageUrl, height: 140, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Text('Gagal memuat gambar'))
              : Image.memory(base64Decode(imageUrl), height: 140, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Text('Gagal memuat gambar')),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blueAccent, size: 22),
            const SizedBox(width: 8),
            const Text('Detail Barang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: detailWidgets,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => EditBarangScreen(docId: docId, dataLama: data)));
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12.5))),
          const Text(': ', style: TextStyle(fontSize: 12.5)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('gudang_barang').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        List<QueryDocumentSnapshot> docs = [];
        if (snapshot.hasData) {
          docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final nama = (data['nama'] ?? '').toString().toLowerCase();
            final merk = (data['Merk / Tipe'] ?? '').toString().toLowerCase();
            final nopol = (data['Nomor Kendaraan'] ?? '').toString().toLowerCase();
            return nama.contains(_searchQuery) || merk.contains(_searchQuery) || nopol.contains(_searchQuery);
          }).toList();
        }

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: Text(_isSelectionMode ? '${_selectedDocIds.length} dipilih' : 'Gudang Barang Prasarana', style: const TextStyle(fontSize: 15)),
            centerTitle: true,
            backgroundColor: Colors.red[800],
            foregroundColor: Colors.white,
            elevation: 1,
            leading: _isSelectionMode ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _selectedDocIds.clear(); _isSelectionMode = false; })) : null,
            actions: [
              // Tombol Cetak PDF Seluruh Gudang Lengkap dengan Detail Penempatan
              if (!_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.print, size: 20),
                  tooltip: 'Cetak Laporan Lengkap',
                  onPressed: () => _cetakPdfSemuaBarang(docs),
                ),
              if (_isSelectionMode) ...[
                IconButton(
                  icon: Icon(_selectedDocIds.length == docs.length && docs.isNotEmpty ? Icons.deselect : Icons.select_all, size: 20),
                  onPressed: () => _toggleSelectAll(docs),
                ),
                IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: _konfirmasiHapusTerpilih),
              ]
            ],
          ),
          body: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Cari nama barang / nomor kendaraan...',
                    hintStyle: const TextStyle(fontSize: 12.5),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 80),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    String docId = doc.id;
                    bool isSelected = _selectedDocIds.contains(docId);
                    String imageUrl = data['imageUrl'] ?? '';
                    String kategori = data['kategori'] ?? 'Lainnya';
                    String namaAsli = data['nama'] ?? 'Tanpa Nama';
                    
                    String displayNama = namaAsli;
                    if (kategori == 'Kendaraan') {
                      String merk = data['Merk / Tipe'] ?? '';
                      String nopol = data['Nomor Kendaraan'] ?? '';
                      if (merk != '-' && merk.isNotEmpty) {
                        displayNama = '$namaAsli ($merk)';
                      }
                      if (nopol != '-' && nopol.isNotEmpty) {
                        displayNama += ' - $nopol';
                      }
                    }

                    return Card(
                      key: ValueKey(docId),
                      elevation: 1,
                      color: isSelected ? Colors.red[50] : Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: isSelected ? Colors.red : Colors.grey.shade300, width: isSelected ? 1.5 : 0.8),
                      ),
                      child: InkWell(
                        onTap: () {
                          if (_isSelectionMode) {
                            setState(() { isSelected ? _selectedDocIds.remove(docId) : _selectedDocIds.add(docId); if (_selectedDocIds.isEmpty) _isSelectionMode = false; });
                          } else {
                            _tampilkanDetailBarang(docId, data);
                          }
                        },
                        onLongPress: () => setState(() { _isSelectionMode = true; _selectedDocIds.add(docId); }),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            children: [
                              _isSelectionMode 
                                ? Checkbox(value: isSelected, activeColor: Colors.red[800], onChanged: (v) => setState(() { v == true ? _selectedDocIds.add(docId) : _selectedDocIds.remove(docId); if(_selectedDocIds.isEmpty) _isSelectionMode = false; }))
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(6), 
                                    child: Container(
                                      height: 40, 
                                      width: 40, 
                                      color: Colors.grey[200], 
                                      child: imageUrl.isNotEmpty 
                                          ? (imageUrl.startsWith('http') ? Image.network(imageUrl, fit: BoxFit.cover) : Image.memory(base64Decode(imageUrl), fit: BoxFit.cover)) 
                                          : const Icon(Icons.inventory, color: Colors.blueAccent, size: 20)
                                    ),
                                  ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayNama, 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text('Kategori: $kategori', style: TextStyle(color: Colors.grey[700], fontSize: 11)),
                                    const SizedBox(height: 1),
                                    Text('Jumlah Stok: ${data['jumlah'] ?? 0} Unit', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueAccent, fontSize: 11)),
                                  ],
                                ),
                              ),
                              if (!_isSelectionMode) const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}