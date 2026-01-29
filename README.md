# my_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Tutorial: Mengganti SharedPreferences dengan Firebase Realtime Database

Panduan langkah demi langkah untuk mengubah aplikasi Flutter Todo List dari penyimpanan lokal (SharedPreferences) menjadi **Firebase Realtime Database**. Cocok untuk bahan mengajar atau dokumentasi project.

---

## Daftar Isi

1. [Tujuan dan Overview](#1-tujuan-dan-overview)
2. [Prasyarat](#2-prasyarat)
3. [Langkah 1: Setup Firebase Project & Realtime Database](#3-langkah-1-setup-firebase-project--realtime-database)
4. [Langkah 2: Konfigurasi Flutter Project](#4-langkah-2-konfigurasi-flutter-project)
5. [Langkah 3: Inisialisasi Firebase di `main.dart`](#5-langkah-3-inisialisasi-firebase-di-maindart)
6. [Langkah 4: Struktur Data di Realtime Database](#6-langkah-4-struktur-data-di-realtime-database)
7. [Langkah 5: Sign Up — Simpan User ke Firebase](#7-langkah-5-sign-up--simpan-user-ke-firebase)
8. [Langkah 6: Login — Baca User dari Firebase](#8-langkah-6-login--baca-user-dari-firebase)
9. [Langkah 7: Todo List — Baca/Tulis Todo dari Firebase](#9-langkah-7-todo-list--bacatulis-todo-dari-firebase)
10. [Langkah 8: Logout](#10-langkah-8-logout)
11. [Menjalankan Aplikasi](#11-menjalankan-aplikasi)
12. [Ringkasan: SharedPreferences vs Realtime Database](#12-ringkasan-sharedpreferences-vs-realtime-database)

---

## 1. Tujuan dan Overview

**Sebelum:** Aplikasi menyimpan data user (login/sign up) dan daftar todo di **SharedPreferences** (penyimpanan lokal di device).

**Sesudah:** Semua data disimpan di **Firebase Realtime Database** (cloud), sehingga:

- Data user dan todo tersedia di cloud.
- Bisa sinkron antar device (jika login dengan user yang sama).
- Data tetap ada meskipun app di-uninstall lalu di-install lagi.

**Yang diubah:**

| Fitur        | Sebelum (SharedPreferences) | Sesudah (Realtime Database)      |
|-------------|-----------------------------|-----------------------------------|
| Daftar user | Key `user_username`, `name_username` | Node `users/{username}` dengan `name`, `password` |
| Todo per user | Key `todos_username` (JSON string) | Node `todolistapps/{username}/{todoId}` |
| Status login | Key `isLoggedIn`, `currentUser`, `currentName` | Tidak disimpan; setelah login langsung kirim `username` & `displayName` ke halaman Todo |

---

## 2. Prasyarat

- **Flutter** terpasang dan bisa dijalankan (`flutter doctor`).
- **Akun Google** untuk Firebase Console.
- **Firebase CLI** (opsional): `npm install -g firebase-tools` bila belum terpasang.

**Urutan langkah setup Firebase & FlutterFire CLI:**

1. Login ke Firebase:
   ```bash
   firebase login
   ```

2. Aktifkan FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

3. Generate konfigurasi Firebase (dijalankan dari root project Flutter, lihat [Langkah 2](#4-langkah-2-konfigurasi-flutter-project)):
   ```bash
   dart pub global run flutterfire_cli:flutterfire configure
   ```

4. Tambah dependency di `pubspec.yaml` (lihat [Langkah 2](#4-langkah-2-konfigurasi-flutter-project)): `firebase_core: ^4.4.0`, lalu `flutter pub get`.

---

## 3. Langkah 1: Setup Firebase Project & Realtime Database

### 3.1 Buat/gunakan project Firebase

1. Buka [Firebase Console](https://console.firebase.google.com/).
2. Klik **Add project** atau pilih project yang sudah ada (misalnya `programming-mobile`).
3. Ikuti wizard (Google Analytics boleh diaktifkan atau tidak).

### 3.2 Aktifkan Realtime Database

1. Di sidebar kiri, pilih **Build** → **Realtime Database**.
2. Klik **Create Database**.
3. Pilih lokasi (misalnya **asia-southeast1**).
4. Pilih mode aturan:
   - **Test mode** untuk development (baca/tulis terbuka untuk sementara).
   - **Production** untuk production (wajib atur Rules).

5. Catat **Database URL**, contoh:
   ```
   https://programming-mobile-default-rtdb.asia-southeast1.firebasedatabase.app
   ```

### 3.3 Daftarkan aplikasi (Android / iOS / Web)

- **Android:** Tambah app Android, isi package name (misalnya `com.example.my_app`), download `google-services.json` ke `android/app/`.
- **Web:** Tambah app Web, dapatkan object konfigurasi (apiKey, authDomain, databaseURL, dll). Bisa dipakai nanti di `firebase_options.dart`.
- **iOS:** Jika perlu, tambah app iOS dan letakkan `GoogleService-Info.plist`.

Konfigurasi untuk Flutter akan digenerate oleh FlutterFire CLI di langkah berikutnya.

---

## 4. Langkah 2: Konfigurasi Flutter Project

### 4.1 Tambah dependency di `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^4.4.0
  firebase_database: ^12.1.2
  # Hapus atau biarkan shared_preferences jika tidak dipakai lagi
```

Lalu jalankan:

```bash
flutter pub get
```

### 4.2 Generate file konfigurasi Firebase (`firebase_options.dart`)

Dari **root folder project Flutter** (yang berisi `pubspec.yaml`):

```bash
dart pub global run flutterfire_cli:flutterfire configure
```

Atau jika `dart pub global run` sudah ada di PATH: `flutterfire configure`.

- Pilih project Firebase.
- Pilih platform (Android, iOS, Web, dll).
- CLI akan membuat/update file **`lib/firebase_options.dart`** berisi `DefaultFirebaseOptions` untuk tiap platform (apiKey, appId, databaseURL, dll).

Pastikan **databaseURL** di `firebase_options.dart` mengarah ke Realtime Database yang benar (misalnya region asia-southeast1).

---

## 5. Langkah 3: Inisialisasi Firebase di `main.dart`

Aplikasi harus menginisialisasi Firebase sebelum menjalankan UI.

**Contoh `lib/main.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'loginpage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List Apps',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
```

**Poin penting:**

- `main()` harus **async**.
- `WidgetsFlutterBinding.ensureInitialized()` dipanggil sebelum `Firebase.initializeApp`.
- `DefaultFirebaseOptions.currentPlatform` memilih konfigurasi yang sesuai (Android, iOS, Web, dll).

---

## 6. Langkah 4: Struktur Data di Realtime Database

Gunakan struktur berikut agar konsisten dengan kode di tutorial ini.

### 6.1 Data user (untuk login & sign up)

```
users/
  {username}/           ← key = username (huruf kecil, tanpa spasi)
    name: "Nama Lengkap"
    password: "password123"
```

- **Path:** `users/{username}`.
- **Field:** `name`, `password` (untuk demo; di production sebaiknya pakai Firebase Auth).

### 6.2 Data todo per user

```
todolistapps/
  {username}/
    {todoId}/            ← id unik, misalnya timestamp
      text: "Teks todo"
      isCompleted: true/false
      id: "todoId"       (opsional, bisa sama dengan key)
```

- **Path:** `todolistapps/{username}/{todoId}`.
- **Field:** `text`, `isCompleted`, (opsional) `id`.

Contoh di Firebase Console (Data tab):

```
users
  budi
    name: "Budi Santoso"
    password: "budi123"
todolistapps
  budi
    1
      text: "Bangun Tidur"
      isCompleted: true
    2
      text: "Absen Kerja"
      isCompleted: false
```

---

## 7. Langkah 5: Sign Up — Simpan User ke Firebase

Tujuan: saat user daftar, simpan **name** dan **password** ke Realtime Database di path `users/{username}`.

### 7.1 Import

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'loginpage.dart';
```

### 7.2 Dapatkan instance database (dengan databaseURL)

Agar Realtime Database memakai URL yang benar (penting untuk region selain default):

```dart
final String? dbUrl = Firebase.app().options.databaseURL;
final FirebaseDatabase database = dbUrl != null && dbUrl.isNotEmpty
    ? FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: dbUrl)
    : FirebaseDatabase.instance;
```

### 7.3 Reference ke node user

```dart
final DatabaseReference userRef = database.ref('users/$username');
```

### 7.4 Cek apakah username sudah dipakai

```dart
final DataSnapshot existingSnapshot = await userRef.get();
if (existingSnapshot.exists) {
  // Tampilkan SnackBar: "Username sudah digunakan"
  return;
}
```

### 7.5 Simpan data user

```dart
await userRef.set({
  'name': name,
  'password': password,
});
```

Lalu tampilkan SnackBar sukses dan pindah ke `LoginPage` (misalnya setelah 1 detik).

**Ringkasan alur Sign Up:**

1. Validasi input (nama, username, password, konfirmasi password).
2. Ambil reference `users/{username}`.
3. Cek `userRef.get()` → jika `exists`, username sudah terdaftar.
4. Jika belum ada, `userRef.set({ name, password })`.
5. Navigate ke `LoginPage`.

---

## 8. Langkah 6: Login — Baca User dari Firebase

Tujuan: baca data user dari `users/{username}`. Jika password cocok, pindah ke halaman Todo dan kirim **username** serta **displayName** (nama).

### 8.1 Import

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'signuppage.dart';
import 'todolistpage.dart';
```

### 8.2 Baca data user dari Firebase

```dart
final FirebaseDatabase database = ...; // sama seperti di Sign Up
final DatabaseReference userRef = database.ref('users/$username');
final DataSnapshot snapshot = await userRef.get();

String? savedPassword;
String? savedName;
if (snapshot.exists && snapshot.value is Map) {
  final data = snapshot.value as Map<Object?, Object?>;
  savedPassword = data['password']?.toString();
  savedName = data['name']?.toString();
}
```

### 8.3 Validasi

- Jika `savedPassword == null` → user tidak ditemukan → SnackBar error.
- Jika `savedPassword != password` → password salah → SnackBar error.

### 8.4 Navigasi ke Todo List dengan parameter

Tidak pakai SharedPreferences untuk simpan "siapa yang login". Langsung kirim ke halaman Todo:

```dart
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => TodoListPage(
      username: username,
      displayName: savedName ?? username,
    ),
  ),
);
```

**Ringkasan alur Login:**

1. Validasi username & password tidak kosong.
2. Baca `users/{username}` dengan `userRef.get()`.
3. Parse `name` dan `password` dari snapshot.
4. Cek user ada dan password cocok.
5. Navigate ke `TodoListPage(username: username, displayName: savedName ?? username)`.

---

## 9. Langkah 7: Todo List — Baca/Tulis Todo dari Firebase

Tujuan: data todo per user di path `todolistapps/{username}`; bisa dibaca sekali, dan lebih baik lagi **dengan listener realtime** agar UI selalu sinkron.

### 9.1 Constructor TodoListPage menerima user

Karena tidak lagi baca "current user" dari SharedPreferences, halaman Todo menerima parameter dari halaman Login:

```dart
class TodoListPage extends StatefulWidget {
  const TodoListPage({
    super.key,
    required this.username,
    required this.displayName,
  });

  final String username;
  final String displayName;
  // ...
}
```

### 9.2 Set state dari parameter

Di `initState` / `_loadData()`:

```dart
_currentUsername = widget.username;
_currentName = widget.displayName;
```

### 9.3 Reference ke todo user

```dart
final FirebaseDatabase database = ...; // pakai databaseURL seperti sebelumnya
_todosRef = database.ref('todolistapps/$_currentUsername');
```

### 9.4 Listener realtime (onValue)

Agar daftar todo otomatis update ketika data di Firebase berubah:

```dart
_todosRef!.onValue.listen((DatabaseEvent event) {
  final value = event.snapshot.value;

  if (!mounted) return;

  if (value == null) {
    // Belum ada data: bisa set todo default lalu simpan ke Firebase
    _todos = [ /* default list */ ];
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
```

### 9.5 Menyimpan todo ke Firebase

Setiap kali todo berubah (tambah, toggle selesai, hapus yang selesai), tulis ulang ke path user:

```dart
Future<void> _saveTodosToFirebase() async {
  if (_todosRef == null) return;
  final Map<String, dynamic> updates = {};
  for (final todo in _todos) {
    updates[todo.id] = {
      'text': todo.text,
      'isCompleted': todo.isCompleted,
      'id': todo.id,
    };
  }
  await _todosRef!.set(updates);
}
```

Panggil `_saveTodosToFirebase()` setelah:

- Menambah todo baru.
- Toggle completed.
- Menghapus todo yang selesai.

**Ringkasan alur Todo:**

1. `TodoListPage` dapat `username` dan `displayName` dari Login.
2. Reference = `todolistapps/{username}`.
3. Pasang `onValue.listen` untuk update `_todos` dan `setState`.
4. Tambah / ubah / hapus todo → panggil `_saveTodosToFirebase()`.

---

## 10. Langkah 8: Logout

Tidak ada lagi "session" yang disimpan di SharedPreferences. Logout cukup **kembali ke halaman Login** dan buang halaman Todo dari stack:

```dart
if (confirm == true) {
  if (mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}
```

Tidak perlu hapus key `isLoggedIn`, `currentUser`, atau `currentName` karena tidak dipakai lagi.

---

## 11. Menjalankan Aplikasi

### 11.1 Install dependency

```bash
cd path/ke/project/flutter
flutter pub get
```

### 11.2 Jalankan di Chrome (Web)

```bash
flutter run -d chrome
```

Pastikan konfigurasi Web sudah ditambahkan di Firebase dan `firebase_options.dart` punya konfigurasi untuk Web (termasuk `databaseURL`).

### 11.3 Jalankan di Android / iOS

```bash
flutter run
# atau
flutter run -d <device_id>
```

### 11.4 Aturan Realtime Database (penting)

Untuk development bisa pakai Rules sementara:

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

Untuk production, batasi baca/tulis per user (biasanya pakai Firebase Authentication dan `auth != null`).

---

## 12. Ringkasan: SharedPreferences vs Realtime Database

| Aspek | SharedPreferences | Firebase Realtime Database |
|-------|-------------------|-----------------------------|
| **Penyimpanan** | Lokal di device | Cloud (Firebase) |
| **Struktur** | Key-value (String, bool, dll) | Tree JSON (path & node) |
| **User** | Key `user_username`, `name_username` | Node `users/{username}` dengan `name`, `password` |
| **Todo** | Key `todos_username` (satu string JSON) | Node `todolistapps/{username}/{todoId}` |
| **Session login** | Key `isLoggedIn`, `currentUser`, `currentName` | Tidak disimpan; username/displayName dikirim lewat constructor |
| **Sinkron** | Tidak sinkron antar device | Bisa sinkron (realtime) |
| **Package** | `shared_preferences` | `firebase_core`, `firebase_database` |

Dengan mengikuti langkah di atas, **semua logika yang sebelumnya memakai SharedPreferences diganti ke Realtime Database**, dan aplikasi siap dipakai untuk mengajar atau dikembangkan lebih lanjut.

---

*Dokumen ini mengacu pada struktur project Todo List yang memakai Login, Sign Up, dan Todo List dengan Firebase Realtime Database.*
