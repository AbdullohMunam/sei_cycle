# Sample Data Firestore

Dokumen ini menjelaskan data sampel kecil untuk demo dan testing SeiCycle.
Seeder berjalan dari Flutter client dengan akun admin, tetap ramah Firebase
Spark/free mode, dan tidak memakai Firebase Storage, Cloud Functions, backend
Express, service account, atau seeder Node.js.

## Tujuan

Data sampel membantu menguji dashboard, logbook, inventory, schedule, inbox
notifikasi, edukasi, finance, dan rekomendasi tanpa mengisi data manual satu per
satu. Semua document ID dibuat stabil agar seed ulang tidak membuat duplikat.

## Cara Menjalankan Seed

1. Login ke aplikasi dengan akun yang role Firestore-nya `admin` dan aktif.
2. Buka menu **Profil**.
3. Pada kartu **Data sampel demo**, tekan **Seed sampel**.

Seeder juga tersedia dari kode:

```dart
await SampleDataService().seedSampleData();
```

Method pendukung:

```dart
final sudahAda = await SampleDataService().hasSampleData();
await SampleDataService().clearSampleData();
```

`clearSampleData()` hanya menghapus dokumen dengan:

```text
isSampleData == true
sampleVersion == "v1"
```

Data user asli atau data operasional asli tidak dihapus.

## Collection Yang Diisi

| Collection | Jumlah | Catatan |
|---|---:|---|
| `users` | 3 | Admin Kebun Sei, Operator Lapangan, Operator Keuangan |
| `logbooks` | 15 | Ayam kampung, maggot BSF, cacing tanah, lele, tanaman |
| `inventory` | 10 | Pakan, media, kompos, bibit, suplemen, alat kebun |
| `schedules` | 10 | Pakan, panen, pemupukan, pengecekan kandang/kolam |
| `notifications` | 5 | Stok rendah, jadwal hari ini, overdue, reminder, sistem |
| `education_contents` | 9 | 3 artikel, 3 video URL eksternal, 3 SOP steps array |
| `finance_transactions` | 12 | Pemasukan panen dan pengeluaran operasional |
| `recommendations` | 5 | Restock, logbook, panen, biaya, jadwal overdue |

## Field Sample

Semua dokumen sample memiliki metadata berikut:

```json
{
  "isSampleData": true,
  "createdAt": "server timestamp",
  "updatedAt": "server timestamp",
  "createdBy": "sample_seed",
  "sampleVersion": "v1"
}
```

Sebagian collection juga memiliki `updatedBy: "sample_seed"` karena field itu
dipakai oleh model operasional SeiCycle.

## Idempotent

Seeder memakai document ID stabil seperti:

- `sample_user_admin`
- `sample_logbook_ayam_001`
- `sample_inventory_pakan_lele`
- `sample_schedule_panen_lele`
- `sample_education_sop_lele`
- `sample_finance_income_panen_001`

Karena ID stabil, seed ulang melewati dokumen yang sudah ada dan hanya membuat
sample yang belum tersedia. Jadi tidak ada dokumen baru terus-menerus.

## Catatan Firebase Free Mode

- Total data kecil, sekitar 69 dokumen.
- Tidak ada upload file atau Firebase Storage.
- Tidak ada Cloud Functions, scheduler, backend Express, Firebase Admin SDK,
  service account, atau script Node.js.
- Video edukasi memakai `externalVideoUrl` dummy.
- SOP memakai `steps` array, bukan PDF.
