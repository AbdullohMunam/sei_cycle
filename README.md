# SeiCycle - MVP Flutter + Firebase

SeiCycle adalah aplikasi operasional Kebun Sei untuk mencatat aktivitas Ayam
Kampung, Maggot BSF, Cacing Tanah, Lele, Tanaman, inventaris, jadwal, edukasi,
dan keuangan sederhana.

## Arsitektur MVP

MVP menggunakan arsitektur **full Firebase direct dari Flutter**:

```text
Flutter
  ├─ Firebase Authentication
  ├─ Cloud Firestore
  └─ Firebase Cloud Messaging (opsional)
```

Backend Express lama sudah dihapus dan tidak digunakan pada MVP. Aplikasi tidak
memerlukan hosting API Node.js. Seluruh akses data dilakukan melalui Firebase
SDK dan diamankan oleh `firestore.rules`.

Firebase Storage belum digunakan agar MVP tidak bergantung pada Blaze/billing.
Materi video, SOP, atau artikel menggunakan field `external_url`.

## Fitur yang Disiapkan

- Login email/password dan Google.
- Registrasi akun dan pembuatan otomatis `users/{uid}`.
- Profil pengguna dan role `admin`, `operator`, atau `mitra`.
- Dashboard dari Firestore: logbook hari ini, stok rendah, jadwal pending,
  keuangan admin, laba/rugi, dan grafik aktivitas 7 hari.
- Logbook CRUD dengan soft delete serta filter modul dan tanggal.
- Inventaris CRUD dan indikator `current_stock <= min_stock`.
- Jadwal CRUD, filter tanggal, serta status `pending`, `done`, dan `skipped`.
- Edukasi artikel/video/SOP dengan teks atau URL eksternal.
- Keuangan pemasukan, pengeluaran, total, dan laba/rugi sederhana.
- Seed lima dokumen `farm_modules` dari menu Profil admin.
- Firestore Security Rules berbasis autentikasi dan role.
- Permintaan izin FCM tersedia di Profil, tetapi pengiriman push ditunda.

## Prasyarat

- Flutter stable dan Dart yang kompatibel dengan `pubspec.yaml`.
- Project Firebase.
- Firebase CLI untuk deploy rules.
- FlutterFire CLI untuk menghasilkan konfigurasi platform.

## Setup Firebase

### 1. Buat dan daftarkan aplikasi Firebase

1. Buat atau buka project di [Firebase Console](https://console.firebase.google.com/).
2. Daftarkan aplikasi Android dengan package name `id.seicycle.app`.
3. Unduh `google-services.json` dan simpan lokal di:

   ```text
   android/app/google-services.json
   ```

File tersebut di-ignore agar konfigurasi lokal tidak ikut commit.

### 2. Konfigurasi FlutterFire

Install FlutterFire CLI lalu jalankan konfigurasi dari root project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Perintah ini menghasilkan atau memperbarui `lib/firebase_options.dart`.
Konfigurasi yang tersimpan saat ini hanya mencakup Android dari
`google-services.json`. Jalankan `flutterfire configure` sebelum menjalankan
Web, iOS, macOS, atau desktop.

`main.dart` sudah menjalankan:

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 3. Aktifkan Authentication

Di Firebase Console buka **Authentication > Sign-in method**:

1. Aktifkan **Email/Password**.
2. Aktifkan **Google** dan pilih support email.
3. Untuk Google Sign-In Android, tambahkan fingerprint SHA-1 dan SHA-256 pada
   Firebase project settings, lalu unduh ulang `google-services.json`.

### 4. Buat Cloud Firestore

Di Firebase Console buka **Firestore Database**, buat database, lalu pilih
region yang sesuai. Deploy rules dari repo:

```bash
firebase login
firebase use --add
firebase deploy --only firestore:rules
```

Rules MVP berada di `firestore.rules`.

### 5. Buat farm modules

Login menggunakan akun admin, buka **Profil**, lalu tekan **Seed** pada bagian
`farm_modules`. Dokumen yang dibuat:

- `ayam_kampung`
- `maggot_bsf`
- `cacing_tanah`
- `lele`
- `tanaman`

## Collection Firestore

| Collection | Document ID | Fungsi |
|---|---|---|
| `users` | UID Firebase Auth | Profil dan role pengguna |
| `farm_modules` | ID modul tetap | Master lima modul Kebun Sei |
| `logbooks` | UUID | Catatan aktivitas operasional |
| `inventory_items` | UUID | Stok dan batas minimum |
| `schedules` | UUID | Kalender dan status pekerjaan |
| `education_contents` | UUID | Artikel, video URL, dan SOP |
| `finance_records` | UUID | Pemasukan dan pengeluaran admin |

Detail field tersedia di [docs/FIRESTORE_SCHEMA.md](docs/FIRESTORE_SCHEMA.md).

## Role dan Akses

| Role | Akses |
|---|---|
| `admin` | Semua fitur dan seluruh data |
| `operator` | Baca data utama; tambah/edit logbook, inventaris, dan jadwal |
| `mitra` | Read-only untuk dashboard dan edukasi pada UI |

Semua akun baru memiliki role `mitra`. Untuk MVP, ubah admin secara manual:

1. Buka **Firestore Database > users**.
2. Pilih dokumen dengan ID UID pengguna.
3. Ubah field `role` menjadi `admin`.
4. Pastikan `is_active` bernilai `true`.

UI role hanya membantu pengalaman pengguna. Otorisasi final tetap dilakukan
oleh Firestore Security Rules. `finance_records` hanya dapat dibaca/ditulis
admin, sehingga kartu keuangan pada dashboard non-admin menampilkan
`Khusus admin`.

## Menjalankan Aplikasi

```bash
flutter pub get
flutter analyze
flutter run
```

Untuk Android, pastikan `android/app/google-services.json` tersedia. Untuk Web
atau platform lain, jalankan `flutterfire configure` terlebih dahulu.

## Struktur Utama

```text
lib/
  app/
    app.dart
    app_shell.dart
  core/
    constants/
    services/
    utils/
    widgets/
  features/
    auth/
    dashboard/
    farm_modules/
    logbook/
    inventory/
    schedule/
    education/
    finance/
    profile/
```

## Keamanan Credential

Jangan commit credential admin Firebase atau private key. `.gitignore`
mencakup:

```text
serviceAccountKey.json
.env
*.pem
*.key
node_modules/
```

Firebase Web/Android API key pada file konfigurasi client bukan private admin
credential; keamanan data tetap harus bergantung pada Authentication,
authorized domains, App Check bila diperlukan, dan Firestore Rules.

## Ditunda Setelah MVP

- Backend Express/API sendiri.
- PDF/Excel report.
- AI recommendation.
- Upload Firebase Storage sampai billing siap.
- Pengiriman FCM push notification jika belum diperlukan.
