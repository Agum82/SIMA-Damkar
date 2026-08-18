
class UserAccount {
  final String nama;
  final String username;
  final String password;
  final String role;

  UserAccount({
    required this.nama,
    required this.username,
    required this.password,
    required this.role,
  });
}

class UserDatabase {
  // Gunakan static agar data menetap di memori selama sesi aplikasi aktif
  static final List<UserAccount> accounts = [
    UserAccount(nama: 'Admin Kasi', username: 'admin', password: '123', role: 'Admin'),
    UserAccount(nama: 'Petugas UPT', username: 'upt', password: '123', role: 'Pelanggan'),
    UserAccount(nama: 'Petugas Pos', username: 'pos', password: '123', role: 'Pos'),
  ];

  // Fungsi untuk menambah akun baru ke database
  static void addAccount(UserAccount newAccount) {
    accounts.add(newAccount);
  }
}