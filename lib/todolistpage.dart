import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'loginpage.dart';

// ============================================
// MODEL DATA TODO
// ============================================
// Class untuk merepresentasikan satu item todo
// Menggunakan class ini membuat kode lebih terorganisir
class TodoItem {
  final String id; // Unique identifier untuk setiap todo
  final String text; // Teks dari todo item
  final bool isCompleted; // Status apakah todo sudah selesai atau belum

  TodoItem({required this.id, required this.text, this.isCompleted = false});

  // Method untuk mengubah TodoItem menjadi Map (untuk disimpan ke SharedPreferences)
  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'isCompleted': isCompleted};
  }

  // Method untuk membuat TodoItem dari Map (untuk membaca dari SharedPreferences)
  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      text: json['text'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  // Method untuk membuat copy dari TodoItem dengan perubahan tertentu
  // Berguna ketika ingin mengubah status completed tanpa mengubah yang lain
  TodoItem copyWith({String? id, String? text, bool? isCompleted}) {
    return TodoItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

// ============================================
// HALAMAN TODO LIST
// ============================================
// Halaman utama setelah login, menampilkan list todo user
class TodoListPage extends StatefulWidget {
  const TodoListPage({
    super.key,
    required this.username,
    required this.displayName,
  });

  final String username;
  final String displayName;

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  // List untuk menyimpan semua todo items
  List<TodoItem> _todos = [];

  // Variabel untuk menyimpan nama user yang sedang login
  String _currentName = '';
  String _currentUsername = '';

  // Reference ke Firebase Realtime Database untuk todo user ini
  DatabaseReference? _todosRef;

  // Controller untuk input field menambah todo baru
  final TextEditingController _todoController = TextEditingController();

  // ============================================
  // FUNGSI YANG DIPANGGIL SAAT HALAMAN DIMUAT
  // ============================================
  @override
  void initState() {
    super.initState();
    // Load data user dari parameter lalu hubungkan ke Realtime Database
    _loadData();
  }

  // Fungsi untuk memuat data user dan menghubungkan todo list ke Realtime Database
  Future<void> _loadData() async {
    // Ambil data user dari parameter yang dikirim dari halaman login
    _currentUsername = widget.username;
    _currentName = widget.displayName;

    // Buat reference ke path Realtime Database untuk todo user ini
    // Struktur: todolistapps/{username}/{todoId}
    // Pakai databaseURL dari options agar region asia-southeast1 dipakai (penting untuk web)
    final String? dbUrl = Firebase.app().options.databaseURL;
    final FirebaseDatabase database = dbUrl != null && dbUrl.isNotEmpty
        ? FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: dbUrl)
        : FirebaseDatabase.instance;
    _todosRef = database.ref('todolistapps/$_currentUsername');

    // Dengarkan perubahan data secara realtime
    _todosRef!.onValue.listen((DatabaseEvent event) {
      final snapshot = event.snapshot;
      final value = snapshot.value;

      if (!mounted) return;

      if (value == null) {
        // Jika belum ada data di Realtime Database, gunakan todo default lalu simpan ke Firebase
        _todos = [
          TodoItem(id: '1', text: 'Bangun Tidur', isCompleted: true),
          TodoItem(id: '2', text: 'Absen Kerja', isCompleted: false),
          TodoItem(id: '3', text: 'Bayar Arisan', isCompleted: false),
          TodoItem(id: '4', text: 'Mengerjakan PR Pak Deny', isCompleted: false),
          TodoItem(id: '5', text: 'Jemput Saudara', isCompleted: false),
        ];
        _saveTodosToFirebase();
      } else if (value is Map) {
        // Parse map dari Firebase menjadi list TodoItem
        final List<TodoItem> loaded = [];
        value.forEach((key, dynamic v) {
          if (v is Map) {
            loaded.add(TodoItem(
              id: key.toString(),
              text: (v['text'] ?? '').toString(),
              isCompleted: (v['isCompleted'] ?? false) == true,
            ));
          }
        });
        _todos = loaded;
      }

      setState(() {});
    });
  }

  // ============================================
  // FUNGSI UNTUK MENYIMPAN TODO KE FIREBASE REALTIME DATABASE
  // ============================================
  Future<void> _saveTodosToFirebase() async {
    if (_todosRef == null) return;

    // Ubah list todo menjadi map {todoId: data}
    final Map<String, dynamic> updates = {};
    for (final todo in _todos) {
      updates[todo.id] = todo.toJson();
    }

    await _todosRef!.set(updates);
  }

  // ============================================
  // FUNGSI UNTUK MENAMBAH TODO BARU
  // ============================================
  void _addTodo() {
    String todoText = _todoController.text.trim();

    // Validasi: pastikan todo tidak kosong
    if (todoText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todo tidak boleh kosong!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Buat todo item baru dengan ID unik (menggunakan timestamp)
    TodoItem newTodo = TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: todoText,
      isCompleted: false,
    );

    // Tambahkan ke list
    setState(() {
      _todos.add(newTodo);
    });

    // Simpan ke Firebase Realtime Database
    _saveTodosToFirebase();

    // Clear input field
    _todoController.clear();
  }

  // ============================================
  // FUNGSI UNTUK MENGUBAH STATUS TODO (COMPLETED/UNCOMPLETED)
  // ============================================
  void _toggleTodo(String id) {
    setState(() {
      // Cari todo dengan ID yang sesuai
      int index = _todos.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        // Toggle status completed
        _todos[index] = _todos[index].copyWith(
          isCompleted: !_todos[index].isCompleted,
        );
      }
    });

    // Simpan perubahan ke Firebase Realtime Database
    _saveTodosToFirebase();
  }

  // ============================================
  // FUNGSI UNTUK MENGHAPUS TODO YANG SUDAH SELESAI
  // ============================================
  void _cleanCompletedTodos() {
    setState(() {
      // Hapus semua todo yang sudah completed
      _todos.removeWhere((todo) => todo.isCompleted);
    });

    // Simpan perubahan ke Firebase Realtime Database
    _saveTodosToFirebase();

    // Tampilkan pesan konfirmasi
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todo yang sudah selesai telah dihapus'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ============================================
  // FUNGSI UNTUK LOGOUT
  // ============================================
  Future<void> _handleLogout() async {
    // Tampilkan dialog konfirmasi
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Redirect ke halaman login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _todoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar adalah header/navbar di bagian atas halaman
      appBar: AppBar(
        title: const Text(
          'Todo List Apps',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true, // Title di tengah
        backgroundColor: Colors.blue.shade700, // Warna biru untuk header
        elevation: 2, // Shadow untuk memberikan efek depth
        // Icon logout di sebelah kanan AppBar
        actions: [
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
      ),
      backgroundColor:
          Colors.grey.shade50, // Background abu-abu muda yang lebih soft
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================
            // WELCOME MESSAGE SECTION
            // ============================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat Datang',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // ============================================
            // INPUT FIELD UNTUK MENAMBAH TODO BARU
            // ============================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _todoController,
                      decoration: InputDecoration(
                        hintText: 'Tambahkan todo baru...',
                        prefixIcon: const Icon(Icons.add_task),
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
                      onSubmitted: (_) => _addTodo(), // Enter untuk submit
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol add dengan styling yang lebih menarik
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _addTodo,
                      icon: const Icon(Icons.add, color: Colors.white),
                      iconSize: 28,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ============================================
            // HEADER LIST TODO
            // ============================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Daftar Todo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_todos.where((todo) => !todo.isCompleted).length} tersisa',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ============================================
            // LIST TODO ITEMS
            // ============================================
            Expanded(
              child: _todos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada todo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tambahkan todo baru untuk memulai',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      // ListView.builder digunakan untuk menampilkan list yang efisien
                      // Hanya widget yang terlihat yang akan di-render
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _todos.length,
                      itemBuilder: (context, index) {
                        TodoItem todo = _todos[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2, // Shadow untuk efek depth
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            // Checkbox untuk menandai todo sebagai completed/uncompleted
                            leading: Checkbox(
                              value: todo.isCompleted,
                              onChanged: (_) => _toggleTodo(todo.id),
                              activeColor: Colors.green.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            // Teks todo dengan strikethrough jika sudah completed
                            title: Text(
                              todo.text,
                              style: TextStyle(
                                fontSize: 16,
                                decoration: todo.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: todo.isCompleted
                                    ? Colors.grey.shade500
                                    : Colors.black87,
                                fontWeight: todo.isCompleted
                                    ? FontWeight.normal
                                    : FontWeight.w500,
                              ),
                            ),
                            // Icon untuk indikator visual
                            trailing: todo.isCompleted
                                ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade600,
                                  )
                                : Icon(
                                    Icons.radio_button_unchecked,
                                    color: Colors.grey.shade400,
                                  ),
                          ),
                        );
                      },
                    ),
            ),

            // ============================================
            // TOMBOL CLEAN (Hapus todo yang sudah selesai)
            // ============================================
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _cleanCompletedTodos,
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text(
                    'Hapus Todo Selesai',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
