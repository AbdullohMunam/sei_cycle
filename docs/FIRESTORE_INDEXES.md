# Firestore Composite Indexes SeiCycle

Daftar ini mengikuti query Flutter saat ini. Buat index lewat Firebase Console bila app menampilkan error `FAILED_PRECONDITION` berisi link pembuatan index. Tidak ada seed data besar yang diperlukan untuk index ini.

## Aktif Dipakai App

| Collection | Query | Field index yang disarankan |
| --- | --- | --- |
| `logbooks` | daftar semua logbook aktif terbaru | `isDeleted ASC`, `activityDate DESC` |
| `logbooks` | filter moduleType + logbook aktif terbaru | `isDeleted ASC`, `moduleType ASC`, `activityDate DESC` |
| `logbooks` | filter tanggal + logbook aktif terbaru | `isDeleted ASC`, `activityDate DESC` |
| `logbooks` | filter moduleType + tanggal + logbook aktif terbaru | `isDeleted ASC`, `moduleType ASC`, `activityDate DESC` |
| `logbooks` | AI recommendation logbook 45 hari terakhir | `isDeleted ASC`, `activityDate DESC` |
| `inventory` | item aktif, stok menipis di atas, urut nama | `isDeleted ASC`, `isLowStock DESC`, `name ASC` |
| `inventory` | dashboard stok rendah maksimal 5 item | `isDeleted ASC`, `isLowStock ASC`, `name ASC` |
| `schedules` | jadwal aktif urut tanggal | `isDeleted ASC`, `date ASC` |
| `schedules` | dashboard jadwal pending | `isDeleted ASC`, `status ASC` |
| `schedules` | dashboard jadwal overdue | `isDeleted ASC`, `status ASC`, `date ASC` |
| `schedules` | AI recommendation jadwal overdue | `isDeleted ASC`, `status ASC`, `date ASC` |
| `education_contents` | konten aktif terbaru untuk admin | `isDeleted ASC`, `updatedAt DESC` |
| `education_contents` | konten published aktif terbaru untuk user | `isDeleted ASC`, `isPublished ASC`, `updatedAt DESC` |
| `finance_transactions` | transaksi aktif terbaru | `isDeleted ASC`, `date DESC` |
| `finance_transactions` | AI recommendation finance bulan berjalan | `isDeleted ASC`, `date DESC` |
| `farm_modules` | modul aktif urut nama | `isActive ASC`, `name ASC` |
| `users` | daftar user urut nama | `name ASC` |
| `notifications` | notifikasi personal aktif terbaru | `isDeleted ASC`, `userId ASC`, `createdAt DESC` |
| `notifications` | notifikasi role/global aktif terbaru | `isDeleted ASC`, `targetRole ASC`, `createdAt DESC` |
| `notifications` | filter tipe notifikasi personal | `isDeleted ASC`, `type ASC`, `userId ASC`, `createdAt DESC` |
| `notifications` | filter tipe notifikasi role/global | `isDeleted ASC`, `type ASC`, `targetRole ASC`, `createdAt DESC` |
| `notifications` | mark all unread personal | `isDeleted ASC`, `isRead ASC`, `userId ASC` |
| `notifications` | mark all unread role/global | `isDeleted ASC`, `isRead ASC`, `targetRole ASC` |

## Disiapkan Untuk Collection Pendukung

| Collection | Query yang mungkin dibutuhkan | Field index yang disarankan |
| --- | --- | --- |
| `report_metadata` | laporan per tipe/periode | `type ASC`, `isDeleted ASC`, `periodStart DESC` |
| `recommendations` | snapshot rekomendasi opsional per modul | `moduleType ASC`, `isResolved ASC`, `priority ASC`, `createdAt DESC` |

## Catatan

- Equality filter seperti `where('isDeleted', isEqualTo: false)` sering tetap perlu composite index ketika digabung dengan `orderBy` field lain.
- Untuk range tanggal, Firestore mengharuskan field range menjadi urutan pertama yang relevan pada `orderBy`; service sudah memakai `activityDate` dan `date` sesuai query.
- Query notifikasi memakai OR untuk personal dan role/global. Jika Firebase Console meminta index tambahan, buat dari link error dan update file ini.
- Jangan membuat collection tambahan untuk file laporan atau media; batasan MVP tetap tanpa Storage dan tanpa backend server.
