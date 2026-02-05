import 'package:flutter/material.dart';
// [DITAMBAH] Import Firebase (Core + Realtime Database) untuk baca user dari cloud
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'signuppage.dart';
import 'todolistpage.dart';

// ============================================
// HALAMAN LOGIN (SIGN IN)
// ============================================
// Halaman ini digunakan untuk login user yang sudah terdaftar
// [DITAMBAH] Data user dibaca dari Firebase Realtime Database
// [VERSI LAMA - COMMENT] Dulu: data user & session disimpan/baca dari SharedPreferences (local)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controller untuk input field
  // TextEditingController digunakan untuk mengontrol nilai dari TextField
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Fungsi untuk validasi dan proses login
  // Fungsi ini akan dipanggil ketika tombol MASUK ditekan
  Future<void> _handleLogin() async {
    // Ambil nilai dari input field
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    // Validasi: pastikan username dan password tidak kosong
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username dan Password tidak boleh kosong!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ---------- [DITAMBAH] Baca user dari Firebase Realtime Database ----------
    final String? dbUrl = Firebase.app().options.databaseURL;
    final FirebaseDatabase database = dbUrl != null && dbUrl.isNotEmpty
        ? FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: dbUrl)
        : FirebaseDatabase.instance;

    final DatabaseReference userRef = database.ref('users/$username');
    final DataSnapshot snapshot = await userRef.get();

    String? savedPassword;
    String? savedName;
    if (snapshot.exists && snapshot.value is Map) {
      final data = snapshot.value as Map<Object?, Object?>;
      savedPassword = data['password']?.toString();
      savedName = data['name']?.toString();
    }
    // ---------- akhir [DITAMBAH] ----------

    // [VERSI LAMA - COMMENT] Logic login pakai SharedPreferences (local storage):
    // final prefs = await SharedPreferences.getInstance();
    // String? savedPassword = prefs.getString('user_$username');  // key: user_username
    // String? savedName = prefs.getString('name_$username');       // key: name_username
    // if (savedPassword == null) { ... user tidak ditemukan ... }
    // if (savedPassword != password) { ... password salah ... }
    // prefs.setBool('isLoggedIn', true);
    // prefs.setString('currentUser', username);
    // prefs.setString('currentName', savedName ?? username);
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TodoListPage()));
    // (TodoListPage dulu baca currentUser/currentName dari prefs di initState)

    if (savedPassword == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Username tidak ditemukan! Silakan daftar terlebih dahulu.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (savedPassword != password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password salah!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // [DITAMBAH] Navigasi ke Todo List dengan kirim username & displayName (tidak simpan session di local)
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TodoListPage(
            username: username,
            displayName: savedName ?? username,
          ),
        ),
      );
    }
  }

  // Fungsi untuk navigasi ke halaman Sign Up
  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpPage()),
    );
  }

  // Clean up: hapus controller ketika widget dihapus
  // Ini penting untuk mencegah memory leak
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar adalah header/navbar di bagian atas halaman
      // AppBar memberikan tampilan yang konsisten seperti aplikasi mobile pada umumnya
      appBar: AppBar(
        title: const Text(
          'SIGN IN',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true, // Title di tengah
        backgroundColor: Colors.blue.shade700, // Warna biru untuk header
        elevation: 2, // Shadow untuk memberikan efek depth
      ),
      backgroundColor:
          Colors.grey.shade50, // Background abu-abu muda yang lebih soft
      body: SafeArea(
        // SafeArea memastikan konten tidak tertutup oleh status bar atau notch
        child: SingleChildScrollView(
          // SingleChildScrollView memungkinkan halaman di-scroll jika konten terlalu panjang
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              // Column digunakan untuk menata widget secara vertikal
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // ============================================
                // IMAGE SLIDER / BANNER
                // ============================================
                // Container dengan gradient dan shadow untuk tampilan yang lebih menarik
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    // Gradient untuk memberikan efek warna yang lebih menarik
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 60,
                          color: Colors.white,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Todo List App',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Kelola tugas Anda dengan mudah',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ============================================
                // INPUT FIELD USERNAME
                // ============================================
                // TextField dengan styling yang lebih modern
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Masukkan username Anda',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                    ), // Icon di depan input
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
                      borderSide: BorderSide(
                        color: Colors.blue.shade700,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ============================================
                // INPUT FIELD PASSWORD
                // ============================================
                // TextField untuk password dengan obscureText untuk menyembunyikan karakter
                TextField(
                  controller: _passwordController,
                  obscureText: true, // Menyembunyikan karakter password
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Masukkan password Anda',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ), // Icon di depan input
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
                      borderSide: BorderSide(
                        color: Colors.blue.shade700,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ============================================
                // TOMBOL MASUK
                // ============================================
                // ElevatedButton dengan styling yang lebih menarik
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        _handleLogin, // Panggil fungsi login ketika tombol ditekan
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.green.shade600, // Warna hijau yang lebih solid
                      foregroundColor: Colors.white,
                      elevation: 4, // Shadow untuk efek depth
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'MASUK',
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
                // LINK KE HALAMAN SIGN UP
                // ============================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Belum punya akun? ',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: _navigateToSignUp,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text(
                        'Daftar di sini',
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
