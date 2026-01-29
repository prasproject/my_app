import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'loginpage.dart';

// ============================================
// HALAMAN SIGN UP (DAFTAR)
// ============================================
// Halaman ini digunakan untuk mendaftarkan user baru
// Data user akan disimpan menggunakan Firebase Realtime Database
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Controller untuk semua input field
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Fungsi untuk validasi dan proses pendaftaran
  Future<void> _handleSignUp() async {
    // Ambil nilai dari semua input field
    String name = _nameController.text.trim();
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // ============================================
    // VALIDASI INPUT
    // ============================================
    // Validasi 1: Pastikan semua field tidak kosong
    if (name.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field harus diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi 2: Pastikan password dan konfirmasi password sama
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password dan Ulangi Password tidak sama!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi 3: Pastikan password minimal 4 karakter (opsional, bisa disesuaikan)
    if (password.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password minimal 4 karakter!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Dapatkan instance Realtime Database (menggunakan databaseURL dari konfigurasi Firebase)
    final String? dbUrl = Firebase.app().options.databaseURL;
    final FirebaseDatabase database = dbUrl != null && dbUrl.isNotEmpty
        ? FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: dbUrl)
        : FirebaseDatabase.instance;

    // Reference ke node user berdasarkan username
    final DatabaseReference userRef = database.ref('users/$username');

    // Cek apakah username sudah terdaftar
    final DataSnapshot existingSnapshot = await userRef.get();
    if (existingSnapshot.exists) {
      // Username sudah digunakan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username sudah digunakan! Silakan gunakan username lain.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ============================================
    // SIMPAN DATA USER KE FIREBASE REALTIME DATABASE
    // ============================================
    await userRef.set({
      'name': name,
      'password': password,
    });

    // Tampilkan pesan sukses
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran berhasil! Silakan login.'),
          backgroundColor: Colors.green,
        ),
      );

      // Kembali ke halaman login setelah 1 detik
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      });
    }
  }

  // Clean up: hapus semua controller
  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar adalah header/navbar di bagian atas halaman
      appBar: AppBar(
        title: const Text(
          'SIGN UP',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true, // Title di tengah
        backgroundColor: Colors.blue.shade700, // Warna biru untuk header
        elevation: 2, // Shadow untuk memberikan efek depth
      ),
      backgroundColor: Colors.grey.shade50, // Background abu-abu muda yang lebih soft
      body: SafeArea(
        child: SingleChildScrollView(
          // SingleChildScrollView memungkinkan halaman di-scroll jika konten terlalu panjang
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // ============================================
                // INPUT FIELD NAMA
                // ============================================
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama',
                    hintText: 'Masukkan nama lengkap Anda',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),

                const SizedBox(height: 20),

                // ============================================
                // INPUT FIELD USERNAME
                // ============================================
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Masukkan username Anda',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),

                const SizedBox(height: 20),

                // ============================================
                // INPUT FIELD PASSWORD
                // ============================================
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Masukkan password Anda',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),

                const SizedBox(height: 20),

                // ============================================
                // INPUT FIELD ULANGI PASSWORD
                // ============================================
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Ulangi Password',
                    hintText: 'Masukkan ulang password Anda',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),

                const SizedBox(height: 32),

                // ============================================
                // TOMBOL DAFTAR
                // ============================================
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'DAFTAR',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ============================================
                // LINK KE HALAMAN LOGIN
                // ============================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text(
                        'Login di sini',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

