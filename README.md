# 🚒 SIMA Damkar (Sistem Informasi Manajemen Aset Pemadam Kebakaran)

---

## 📑 Daftar Isi
1. [Pendahuluan](#-pendahuluan)
2. [Latar Belakang](#-latar-belakang)
3. [Tampilan Aplikasi (Screenshots)](#-tampilan-aplikasi-screenshots)
4. [Fitur Utama (Main Features)](#-fitur-utama-main-features)
5. [Fitur Sampingan & Pendukung](#-fitur-sampingan--pendukung-side-features)
6. [Teknologi yang Digunakan](#-teknologi-yang-digunakan)
7. [Panduan Instalasi Lengkap](#-panduan-instalasi-lengkap-untuk-os-windows)
8. [Aturan Pengoperasian Fitur Notifikasi](#-aturan-pengoperasian-fitur-notifikasi-khusus-admin)
9. [Kendala yang Diketahui (Bugs) & Cara Penyelesaian](#-kendala-yang-diketahui-bugs--cara-penyelesaian)

---

## 📌 Pendahuluan
Selamat datang di repositori resmi **SIMA DAmkar**. 

Di era digitalisasi dan transformasi *e-Government*, integrasi teknologi informasi ke dalam sektor pelayanan publik bukan lagi sebuah pilihan, melainkan sebuah keharusan. **SIMA Damkar** hadir sebagai sebuah inovasi perangkat lunak (*software*) berbasis *desktop* Windows yang dirancang secara khusus dan komprehensif untuk mendigitalisasi ekosistem manajemen inventaris barang, pelaporan kerusakan armada, dan alur distribusi logistik di lingkungan Dinas Pemadam Kebakaran dan Penyelamatan.

Aplikasi ini tidak sekadar berfungsi sebagai alat pencatatan digital, melainkan sebuah jembatan komunikasi operasional dua arah yang menghubungkan Markas Komando (Admin Pusat) dengan seluruh jejaring Pos Sektor atau Unit Pelaksana Teknis (UPT) yang tersebar di berbagai wilayah. Dibangun di atas arsitektur *Cloud Computing* menggunakan Firebase dan *framework* Flutter, SIMA DAmkar mengeliminasi hambatan jarak dan waktu, memastikan setiap pengajuan barang dan pelaporan kerusakan darurat dari lapangan dapat diterima, divalidasi, dan ditindaklanjuti oleh Pusat secara *real-time*, terstruktur, dan transparan.

---

## 📖 Latar Belakang

**1. Urgensi Kesiapsiagaan dan Standar Pelayanan Minimal (SPM)**
Dinas Pemadam Kebakaran (Damkar) merupakan garda terdepan institusi pemerintah dalam penanganan kondisi gawat darurat yang menyangkut hajat hidup dan keselamatan masyarakat luas. Tugas pokok dan fungsi (Tupoksi) institusi ini mencakup pencegahan kebakaran, pemadaman api, operasi penyelamatan (*rescue*), evakuasi korban bencana alam, hingga penanganan insiden bahan berbahaya dan beracun (B3). Dalam menjalankan tugas yang berisiko sangat tinggi ini, Damkar dipacu oleh satu Indikator Kinerja Utama yang sangat krusial, yaitu **Response Time** (waktu tanggap maksimal 15 menit sejak laporan diterima hingga armada tiba di lokasi). 

Keberhasilan dalam mencapai *Response Time* yang ideal dan meminimalisir jatuhnya korban jiwa tidak hanya bergantung pada kecakapan, kesiapan fisik, dan keberanian personel, tetapi secara mutlak ditunjang oleh **kesiapan sarana, prasarana, dan kelengkapan logistik operasional**. Armada pemadam (mobil pompa, mobil tangki, *ladder truck*), kelengkapan mekanis seperti selang pemadam (*firehose*), *nozzle*, pompa portabel, peralatan ekstraksi, tabung pernapasan SCBA (*Self-Contained Breathing Apparatus*), hingga Alat Pelindung Diri (APD) harus selalu dipastikan dalam kondisi prima dan berstatus "Siaga 1".

**2. Kompleksitas Distribusi dan Tantangan Geografis**
Untuk mempercepat *Response Time* dan memperluas jangkauan perlindungan wilayah, kekuatan operasional Damkar didistribusikan ke berbagai Pos Sektor atau UPT yang tersebar di tingkat kecamatan. Tersebarnya personel dan aset logistik bernilai tinggi ini menimbulkan tantangan manajerial yang sangat besar bagi Markas Komando (Mako) selaku pusat komando dan administrasi. Mako dituntut untuk mampu melakukan pemantauan, pendataan, audit ketersediaan barang, serta menjamin kelayakan fungsi setiap alat di seluruh Pos secara akurat dan berkesinambungan. Mobilitas operasi yang tinggi menyebabkan peralatan-peralatan ini memiliki siklus keausan yang cepat dan sangat rentan mengalami kerusakan mendadak di lapangan.

**3. Kelemahan Sistem Konvensional (Status Quo)**
Selama ini, sistem pendataan inventaris gudang, mutasi alokasi barang, pelaporan kerusakan alat, hingga pengajuan pengadaan (*restock*) dari tiap Pos ke Pusat masih didominasi oleh metode konvensional. Pendataan stok sering kali hanya mengandalkan buku mutasi fisik, pencatatan di papan tulis, atau pengiriman formulir kertas yang rentan hilang. Lebih jauh lagi, laporan kerusakan armada atau permohonan penggantian alat vital sering kali hanya dikirimkan melalui grup aplikasi pesan instan komersial (seperti WhatsApp). 

Metode konvensional ini melahirkan berbagai disfungsi birokrasi dan celah operasional:
*   **Asimetri Informasi:** Mako kesulitan memantau sisa stok logistik dan sebaran alat secara *real-time*. Validasi data mengharuskan admin melakukan panggilan telepon satu per satu ke setiap Pos, yang mana sangat tidak efisien.
*   **Risiko Kehilangan Data (Human Error):** Laporan kerusakan darurat dari Pos yang dikirim via WhatsApp sangat mudah tertumpuk, tenggelam oleh pesan lain, atau terabaikan, sehingga memperlambat respons perbaikan.
*   **Birokrasi yang Pasif dan Lambat:** Tidak adanya *platform* pengajuan terpusat membuat alur persetujuan (*approval*) dari pimpinan menjadi panjang, berbelit, dan tidak memiliki standar baku.
*   **Kesulitan Audit dan Perencanaan Anggaran:** Ketiadaan basis data riwayat transaksi (*log history*) yang terstruktur menyulitkan pimpinan Mako dalam menyusun Laporan Pertanggungjawaban (LPJ) maupun menyusun Rencana Anggaran Biaya (RAB) pengadaan aset untuk tahun anggaran berikutnya.

**4. Risiko Fatalitas Akibat Kelalaian Administrasi**
Konsekuensi dari lambatnya sistem administrasi ini berdampak langsung pada keselamatan di lapangan. Jika sebuah Pos melaporkan kerusakan selang atau kebocoran tangki armada namun laporannya terhambat di meja administrasi, Pos tersebut terpaksa merespons panggilan kebakaran dengan peralatan seadanya. Kondisi ini secara langsung mempertaruhkan nyawa petugas di garis depan, membahayakan warga yang menanti pertolongan, serta berpotensi memperbesar kerugian materiil akibat api yang gagal dipadamkan tepat waktu.

**5. Solusi Digitalisasi: Implementasi SIMA DAmkar**
Menjawab kesenjangan (*gap*) antara tuntutan operasional yang sangat dinamis dan lambatnya sistem administrasi konvensional, **SIMA DAmkar** dikembangkan sebagai solusi *Enterprise Resource Planning* (ERP) skala spesifik untuk institusi Pemadam Kebakaran. 

Melalui aplikasi *desktop* ini, seluruh proses bisnis logistik didigitalisasi:
*   Admin Pusat memiliki panel kendali visual untuk memantau fluktuasi stok gudang, meninjau foto bukti kerusakan, dan memberikan persetujuan (*Approve/Reject*) hanya dengan satu klik.
*   Pos/UPT difasilitasi dengan sistem Triase Pelaporan, di mana mereka dapat mengklasifikasikan tingkat urgensi kerusakan (Sedang/Berat) agar Pusat dapat memprioritaskan penanganan.
*   Dilengkapi teknologi **Push Notification terintegrasi OS Windows**, sistem ini mengubah komputer Mako menjadi radar aktif. Setiap laporan darurat dari Pos akan langsung membunyikan notifikasi *pop-up* di layar komputer Admin pada detik yang sama, meminimalisir kemungkinan laporan terlewatkan.

Melalui modernisasi ekosistem informasi menggunakan SIMA DAmkar, institusi Pemadam Kebakaran dapat memangkas rantai birokrasi, meningkatkan transparansi dan akuntabilitas aset, serta memastikan seluruh satuan di setiap wilayah senantiasa didukung oleh peralatan operasional yang tangguh, terdata, dan siap digunakan demi menyelamatkan nyawa masyarakat.

---

## 📸 Tampilan Aplikasi (Screenshots)

| Halaman Login | Halaman Register |
| :---: | :---: |
| ![Login Screen](assets/images/login_screen.png) | ![Register Screen](assets/images/register_screen.png) |

| Dashboard Admin (Pusat) | Dashboard UPT / Pos |
| :---: | :---: |
| ![Admin Dashboard](assets/images/dashboard_admin.png) | ![UPT/Pos Dashboard](assets/images/dashboard_upt_pos.png) |

| Form Pengajuan Barang | Form Laporan Kerusakan |
| :---: | :---: |
| ![Form Pengajuan](assets/images/form_pengajuan.png) | ![Form Kerusakan](assets/images/form_kerusakan.png) |

---

## 🌟 Fitur Utama (Main Features)

Aplikasi ini memiliki sistem berbasis peran (*Role-Based Access*) yang membagi fitur berdasarkan jenis akun (Admin Pusat dan Pos/UPT):

### 👨‍💻 Hak Akses Admin (Pusat)
1. **Manajemen Gudang Terpusat:** Memantau, menambah, mengubah, dan menghapus data stok barang. Sistem dirancang agar barang dengan stok `0` (habis) tetap tercatat di database untuk mempermudah proses *restock*.
2. **Sistem Persetujuan (Approval):** Admin dapat meninjau, menyetujui (Approve), atau menolak (Reject) permintaan barang dan laporan kerusakan yang masuk dari setiap Pos/UPT.
3. **Notifikasi Desktop Real-Time:** Dilengkapi dengan sistem *push notification* Windows. Saat Admin sedang membuka aplikasi lain (seperti Word atau Browser), *pop-up* bersuara akan muncul di pojok kanan bawah layar (Action Center) setiap kali ada tiket permintaan atau laporan kerusakan baru.
4. **Log Riwayat Transaksi:** Seluruh aktivitas persetujuan dan penolakan terekam dengan jelas pada menu Riwayat.
5. **Klasifikasi Laporan:** Memisahkan data manajemen berdasarkan kategori: Permintaan UPT, Permintaan Pos, Kerusakan Sedang, dan Kerusakan Berat.

### 🚒 Hak Akses Pos / UPT
1. **Form Pengajuan Barang:** UPT/Pos dapat meminta pasokan logistik atau peralatan baru ke Pusat.
2. **Pelaporan Kerusakan (Triage):** Pos dapat melaporkan aset/armada yang rusak dengan melampirkan foto bukti, serta menentukan tingkat urgensi (Kerusakan Sedang / Berat).
3. **Tracking Status Tiket:** Pos dapat memantau apakah pengajuan mereka masih dalam status "Menunggu", "Disetujui", atau "Ditolak" secara langsung.

---

## 🛠️ Fitur Sampingan & Pendukung (Side Features)

1. **Import Data Massal (CSV Import):** Admin dapat memasukkan ribuan data master barang (termasuk alokasi distribusi per Pos/UPT) secara otomatis hanya dengan mengunggah file CSV. Sistem memiliki logika parsing cerdas untuk membaca kolom data Damkar.
2. **Pencarian Cerdas (Smart Search):** Tersedia kolom pencarian di halaman Riwayat Transaksi. Admin dapat memfilter data dengan mengetik nama barang, nama pengaju, keterangan, atau status dengan sangat cepat.
3. **Hapus Massal (Multi-Select Delete):** Admin dapat mencentang (ceklis) banyak riwayat transaksi sekaligus untuk dihapus (*Batch Delete*) agar database Firebase tetap bersih dan tidak melebihi kuota.
4. **Interactive Image Viewer:** Foto bukti kerusakan yang dikirim oleh Pos dapat diklik untuk diperbesar (*Zoom In/Out* dan *Pan*) agar Admin bisa melihat detail kerusakan dengan jelas.
5. **Autentikasi Aman:** Sistem *Login* dan *Register* menggunakan Firebase Authentication yang terenkripsi.

---

## 💻 Teknologi yang Digunakan
- **Framework:** Flutter (Dart)
- **Target OS:** Windows Desktop (`.exe`)
- **Backend & Database:** Firebase Cloud Firestore & Firebase Authentication
- **Storage:** Firebase Storage & Image Base64 Encoding
- **Notifikasi:** `local_notifier` (Windows Action Center Integration)
- **Installer Builder:** Inno Setup Compiler

---

## 📥 Panduan Instalasi Lengkap (Untuk OS Windows)

Aplikasi ini dikemas dalam bentuk *installer* mandiri bernama `SIMA_Damkar_Setup.exe`. Ikuti langkah-langkah di bawah ini untuk memasang aplikasi ke laptop/PC Anda:

### Tahap 1: Mengunduh File
1. Minta file `SIMA_Damkar_Setup.exe` versi terbaru dari pengembang atau unduh dari menu *Releases* di GitHub ini.
2. Simpan file tersebut di folder komputer Anda (misalnya di folder *Downloads*).

### Tahap 2: Menjalankan Installer & Melewati SmartScreen (PENTING)
Karena aplikasi ini dibuat secara independen dan tidak menggunakan sertifikat berbayar korporat, sistem keamanan Windows Defender mungkin akan memblokirnya di awal. Ini sangat normal dan **100% aman**.
1. Klik 2x pada file `SIMA_Damkar_Setup.exe`.
2. Jika muncul jendela peringatan berwarna biru terang bertuliskan **"Windows protected your PC"** (SmartScreen):
   - Jangan panik, klik teks kecil bertuliskan **"More info"** (Info lebih lanjut) di bawah paragraf peringatan.
   - Setelah diklik, nama aplikasi akan muncul, beserta tombol baru di kanan bawah.
   - Klik tombol **"Run anyway"** (Tetap jalankan).

### Tahap 3: Proses Instalasi
1. Setelah jendela instalasi (*Setup Wizard*) terbuka, klik **Next**.
2. Pilih lokasi penyimpanan folder (biarkan *default* jika tidak yakin), lalu klik **Next**.
3. Pastikan kotak **"Create a desktop shortcut"** dicentang agar ikon aplikasi muncul di layar depan laptop Anda, lalu klik **Next**.
4. Klik **Install** dan tunggu proses hingga garis hijau penuh.
5. Terakhir, klik **Finish**. Aplikasi SIMA DAmkar kini siap digunakan!

### 🔄 Catatan Saat Melakukan Update (Pembaruan) Aplikasi
Jika di laptop Anda sudah terinstal SIMA DAmkar versi lama, **Anda TIDAK PERLU menghapus (uninstall) versi lama tersebut.**
Cukup jalankan file `SIMA_Damkar_Setup.exe` versi baru dengan langkah yang sama seperti di atas. Sistem akan otomatis menimpa file lama dengan fitur terbaru. Data akun dan stok barang Anda **dijamin aman** karena tersimpan di *Cloud Database*.

---

## 🚨 Aturan Pengoperasian Fitur Notifikasi (Khusus Admin)
Agar Admin selalu menerima pemberitahuan/notifikasi darurat secara *real-time*:
- Buka aplikasi dan Login sebagai Admin.
- **DILARANG** menutup aplikasi menggunakan tanda Silang **( X )** di pojok kanan atas saat jam kerja operasional. Jika ditutup total, radar notifikasi akan mati.
- Cukup tekan tombol **Minimize ( - )** agar aplikasi bersembunyi di *Taskbar* bagian bawah. Selama aplikasi berada di *Taskbar*, *pop-up* notifikasi akan tetap masuk ke layar Windows Anda.

---

## 🐛 Kendala yang Diketahui (Bugs) & Cara Penyelesaian

Dalam pengoperasiannya, terdapat beberapa batasan teknis (bug) pada sistem operasi Windows yang mungkin terjadi. Berikut adalah cara untuk mengatasi kendala tersebut:

**1. Kendala: Notifikasi tidak muncul di layar komputer Admin (Tidak ada suara/pop-up).**
*   **Penyebab:** Arsitektur sistem operasi Windows akan memutus koneksi internet (*kill process*) pada aplikasi berformat `.exe` jika aplikasi ditutup total. Hal ini menyebabkan *listener* Firebase ikut mati.
*   **Penyelesaian:** Pastikan Anda **tidak mengeklik tanda silang (X)** di pojok kanan atas. Gunakan tombol **Minimize (-)** agar aplikasi turun ke *Taskbar* bawah. Selama aplikasi dalam kondisi *minimize*, notifikasi akan tetap masuk secara normal.

**2. Kendala: Gagal memasukkan (Import) data barang secara massal menggunakan file CSV.**
*   **Penyebab:** Format pemisah kolom (*delimiter*) pada aplikasi Excel tidak sesuai dengan standar pembacaan sistem, biasanya disebabkan oleh perbedaan pengaturan wilayah (*Region*) di komputer pengguna.
*   **Penyelesaian:** Pastikan file yang Anda unggah benar-benar berformat **.csv (Comma delimited)**. Buka file CSV tersebut menggunakan aplikasi *Notepad* untuk memastikan bahwa antar kata dipisahkan menggunakan tanda **koma ( , )**, bukan titik koma ( ; ).

**3. Kendala: Aplikasi tidak bisa melakukan proses *Login* atau tampilan data kosong/berputar terus (*loading*).**
*   **Penyebab:** Koneksi internet terputus atau *Firewall* bawaan Windows Defender memblokir akses internet untuk aplikasi ini.
*   **Penyelesaian:** Pastikan jaringan internet (WiFi/LAN) stabil. Jika koneksi lancar, buka pengaturan `Windows Defender Firewall` > pilih menu `Allow an app through firewall` > cari `SIMA_Damkar_Setup.exe` atau `sima_damkar.exe` > lalu **centang** pada kotak *Private* dan *Public*.

**4. Kendala: Tiba-tiba muncul peringatan Layar Biru (SmartScreen) saat membuka aplikasi.**
*   **Penyebab:** Ini bukan virus, melainkan proteksi *default* dari sistem Windows terhadap aplikasi yang dikembangkan secara mandiri tanpa sertifikat lisensi berbayar dari perusahaan besar.
*   **Penyelesaian:** Klik teks **"More info"**, lalu klik tombol **"Run anyway"** yang muncul di pojok kanan bawah.

---
**Pengembang:** Agum Aidil Saepul Rohman | Teknik Informatika, Institut Teknologi Garut.  
*Didedikasikan untuk meningkatkan kecepatan, efisiensi operasional, dan digitalisasi logistik Pemadam Kebakaran.*
