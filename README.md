# SeiCycle - MVP Flutter + Firebase

SeiCycle adalah aplikasi operasional Kebun Sei untuk mencatat aktivitas Ayam
Kampung, Maggot BSF, Cacing Tanah, Lele, Tanaman, inventaris, jadwal, edukasi,
dan keuangan sederhana.

## Arsitektur MVP

MVP menggunakan arsitektur **full Firebase direct dari Flutter**:

```text
Flutter app
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Cloud Messaging untuk permission/token/client readiness
  - Flutter local notification boleh dipakai untuk reminder lokal client-side
```

Backend Express lama sudah dihapus dan tidak digunakan pada MVP. Aplikasi tidak
memerlukan hosting API Node.js, server Express, seeders Node.js, Firebase Admin
SDK, atau `serviceAccountKey.json`. Seluruh akses data dilakukan melalui Firebase
SDK dari Flutter dan diamankan oleh `firestore.rules`.

Mode ini dibuat **Spark-compatible**. Repo tidak menggunakan Firebase
Storage, Cloud Functions, atau konfigurasi backend yang membutuhkan billing
Firebase Blaze. Materi video, SOP, atau artikel menggunakan field `external_url`
dan FCM dibatasi untuk request permission serta token readiness dari client.

Dokumentasi backend Firebase client-side tersedia di [docs/BACKEND.md](docs/BACKEND.md).

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

## Checklist Brief SeiCycle

### Selesai pada MVP saat ini

- [x] Firebase Authentication email/password.
- [x] Google Sign-In melalui Firebase Authentication.
- [x] Pembuatan dan pembacaan profil `users/{uid}`.
- [x] Role dasar `admin`, `operator`, dan `mitra`.
- [x] Dashboard ringkasan dari Cloud Firestore.
- [x] Logbook operasional dengan tambah, edit, soft delete, dan filter.
- [x] Inventaris dengan tambah, edit, dan indikator stok rendah.
- [x] Jadwal dengan tambah, edit, filter tanggal, dan update status.
- [x] Edukasi artikel/video/SOP berbasis teks dan URL eksternal.
- [x] Keuangan admin untuk income, expense, total, dan laba/rugi sederhana.
- [x] Seed `farm_modules` dari UI Profil admin, bukan seeder Node.js.
- [x] Firestore schema, ERD, rules, dan konfigurasi deploy rules.
- [x] FCM client readiness untuk request permission dan ambil token.
- [x] Secret hygiene untuk `.env`, service account, key, dan `node_modules/`.

### Belum selesai atau sengaja ditunda

- [ ] Firebase Web, iOS, macOS, Windows, atau Linux options dari FlutterFire.
- [ ] Pengiriman push notification terjadwal atau server-side.
- [ ] Local notification reminder client-side bila dibutuhkan.
- [ ] Upload file atau gambar dengan Firebase Storage.
- [ ] Cloud Functions atau backend job server-side.
- [ ] Backend Express/API/server hosting.
- [ ] PDF/Excel report.
- [ ] AI recommendation.
- [ ] App Check dan hardening produksi lanjutan.

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

Seeder ini berjalan dari Flutter client menggunakan akun admin dan Firestore
Rules. Tidak ada script seeder Node.js atau Firebase Admin SDK.

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
docs/
  BACKEND.md
  ERD.md
  FIRESTORE_SCHEMA.md
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
- Cloud Functions dan backend scheduler.
- PDF/Excel report.
- AI recommendation.
- Upload Firebase Storage sampai billing siap.
- Pengiriman FCM push notification server-side jika belum diperlukan.
