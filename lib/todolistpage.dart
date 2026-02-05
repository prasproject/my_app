import 'package:flutter/material.dart';
// [DITAMBAH] Import Firebase untuk baca/tulis todo di Realtime Database
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'loginpage.dart';

// ============================================
// MODEL DATA TODO
// ============================================
class TodoItem {
  final String id;
  final String text;
  final bool isCompleted;

  TodoItem({required this.id, required this.text, this.isCompleted = false});

  // Dipakai untuk simpan ke Firebase maupun (dulu) ke SharedPreferences
  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'isCompleted': isCompleted};
  }

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
// [DITAMBAH] User identity dari parameter (dikirim dari LoginPage), todo dari Firebase
// [VERSI LAMA - COMMENT] Dulu: username/nama dibaca dari SharedPreferences (currentUser, currentName), todo dari key todos_username
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
  List<TodoItem> _todos = [];

  String _currentName = '';
  String _currentUsername = '';

  // [DITAMBAH] Reference ke path todolistapps/{username} di Realtime Database
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

  // ---------- [DITAMBAH] Load user dari parameter, todo dari Firebase Realtime Database ----------
  Future<void> _loadData() async {
    _currentUsername = widget.username;
    _currentName = widget.displayName;

    final String? dbUrl = Firebase.app().options.databaseURL;
    final FirebaseDatabase database = dbUrl != null && dbUrl.isNotEmpty
        ? FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: dbUrl)
        : FirebaseDatabase.instance;
    _todosRef = database.ref('todolistapps/$_currentUsername');

    _todosRef!.onValue.listen((DatabaseEvent event) {
      final snapshot = event.snapshot;
      final value = snapshot.value;

      if (!mounted) return;

      if (value == null) {
        _todos = [
          TodoItem(id: '1', text: 'Bangun Tidur', isCompleted: true),
          TodoItem(id: '2', text: 'Absen Kerja', isCompleted: false),
          TodoItem(id: '3', text: 'Bayar Arisan', isCompleted: false),
          TodoItem(id: '4', text: 'Mengerjakan PR Pak Deny', isCompleted: false),
          TodoItem(id: '5', text: 'Jemput Saudara', isCompleted: false),
        ];
        _saveTodosToFirebase();
      } else if (value is Map) {
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
  // ---------- akhir [DITAMBAH] ----------

  // [VERSI LAMA - COMMENT] Load user & todo dari SharedPreferences:
  // final prefs = await SharedPreferences.getInstance();
  // _currentUsername = prefs.getString('currentUser') ?? '';
  // _currentName = prefs.getString('currentName') ?? _currentUsername;
  // String? json = prefs.getString('todos_$_currentUsername');
  // if (json != null) { _todos = (jsonDecode(json) as List).map((e) => TodoItem.fromJson(e)).toList(); }

  // [DITAMBAH] Simpan todo ke Firebase Realtime Database (path: todolistapps/{username})
  Future<void> _saveTodosToFirebase() async {
    if (_todosRef == null) return;

    final Map<String, dynamic> updates = {};
    for (final todo in _todos) {
      updates[todo.id] = todo.toJson();
    }

    await _todosRef!.set(updates);
  }
  // [VERSI LAMA - COMMENT] Save todo ke SharedPreferences:
  // prefs.setString('todos_$_currentUsername', jsonEncode(_todos.map((e) => e.toJson()).toList()));

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

    // [DITAMBAH] Simpan ke Firebase (dulu: prefs.setString('todos_...', ...))
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

    // [DITAMBAH] Simpan ke Firebase
    _saveTodosToFirebase();
  }

  void _cleanCompletedTodos() {
    setState(() {
      _todos.removeWhere((todo) => todo.isCompleted);
    });

    _saveTodosToFirebase();

    // Tampilkan pesan konfirmasi
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todo yang sudah selesai telah dihapus'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // [DITAMBAH] Logout = pushReplacement ke LoginPage (tidak simpan session di device)
  // [VERSI LAMA - COMMENT] Dulu: prefs.setBool('isLoggedIn', false); prefs.remove('currentUser'); prefs.remove('currentName'); lalu pushReplacement ke LoginPage
  Future<void> _handleLogout() async {
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
