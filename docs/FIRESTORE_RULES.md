# Firestore Security Rules SeiCycle

Rules final ada di `firestore.rules` dan sudah direferensikan oleh
`firebase.json`. Aplikasi memakai mode gratis client-side: role dibaca dari
dokumen `users/{uid}`, bukan custom claims, Cloud Functions, backend server,
atau Firebase Storage.

## Prinsip Utama

- Semua data aplikasi mensyaratkan Firebase Auth.
- Semua collection tampilan utama bisa dibaca oleh user aktif.
- User aktif adalah user yang punya dokumen `users/{uid}` dan `isActive` tidak
  bernilai `false`; status ini tetap dipakai untuk izin mutasi sesuai role.
- Role valid utama: `admin`, `operator_lapangan`, `operator_keuangan`.
- Role legacy `operator`, `mitra`, dan `peserta_edukasi` masih dibaca untuk
  kompatibilitas data lama, tetapi role yang bisa diberikan admin tetap role
  utama.
- Tidak ada rule `allow read, write: if true`; collection yang tidak dikenal
  ditutup oleh fallback `allow read, write: if false`.

## Matriks Akses

| Collection | Read | Create | Update | Delete |
| --- | --- | --- | --- | --- |
| `users` | Semua user login | Owner membuat profil sendiri, admin membuat user valid | Owner update profil ringan; admin update role/status | Admin |
| `farm_modules` | User aktif | Admin | Admin | Admin |
| `logbooks` | User aktif | Admin, operator lapangan | Admin, operator lapangan tanpa soft delete | Admin |
| `inventory` | User aktif | Admin, operator lapangan | Admin, operator lapangan tanpa soft delete | Admin |
| `inventory_transactions` | User aktif | Admin, operator lapangan dari Logbook | Admin/operator lapangan untuk data asal tetap | Admin |
| `production_results` | User aktif | Admin, operator lapangan dari Logbook | Admin | Admin |
| `circular_flows` | User aktif | Admin, operator lapangan | Admin | Admin |
| `schedules` | User aktif | Admin, operator lapangan | Admin, operator lapangan tanpa soft delete | Admin |
| `finance_transactions` | User aktif | Admin, operator keuangan | Admin, operator keuangan | Admin, operator keuangan |
| `education_contents` | User aktif | Admin | Admin | Admin |
| `notifications` | User aktif | User aktif untuk alert client miliknya; admin untuk seed/system/demo alert | Penerima boleh set `isRead/readAt`; owner boleh refresh alert client miliknya | Admin |
| `report_metadata` | User aktif | Admin, operator keuangan | Admin, operator keuangan tanpa soft delete | Admin |
| `recommendations` | User aktif | Admin | Admin | Admin |

Catatan "user aktif" dipakai agar semua role tetap bisa membuka semua
tampilan utama. Pembatasan aksi mutasi tetap dilakukan di rules sesuai role.

## Detail Penting

- `users/{uid}`: user hanya dapat mengubah field profil ringan seperti `name`,
  `photoUrl`, `fcmToken`, dan `updatedAt`. Field `role` dan `isActive` hanya
  boleh diubah admin.
- `finance_transactions`: operator lapangan tetap dapat membaca untuk dashboard
  dan laporan, tetapi tidak dapat menulis.
- `education_contents`: semua user login bisa melihat konten untuk kebutuhan
  tampilan, sedangkan create/update/delete tetap hanya admin.
- `notifications`: semua user login bisa membaca koleksi untuk kebutuhan
  tampilan/badge. Alert otomatis dari client tetap dibatasi ke `userId` user
  login dan `targetRole` role user tersebut. Alert sistem global/role dibuat
  admin. Refresh alert client hanya boleh untuk notifikasi milik user yang sama.
- `recommendations`: rekomendasi default dibuat on-demand di Flutter. Collection
  disiapkan hanya bila admin nanti perlu menyimpan snapshot manual.

## Deploy

```powershell
firebase deploy --only firestore:rules,firestore:indexes
```

Jika Firebase Console meminta index tambahan saat app berjalan, buat dari link
error `FAILED_PRECONDITION`, lalu salin definisinya ke `firestore.indexes.json`
dan update `docs/FIRESTORE_INDEXES.md`.
