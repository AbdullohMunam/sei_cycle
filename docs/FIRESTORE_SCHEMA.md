# Firestore Schema SeiCycle

Schema ini adalah kontrak MVP Flutter + Firebase langsung. Tidak ada Firebase Storage, Cloud Functions, atau backend server. Semua timestamp disimpan sebagai Firestore `Timestamp`; data operasional memakai UUID dari Flutter sebagai document ID dan field `id`.

Nama field canonical memakai camelCase. Model Dart masih membaca beberapa field snake_case lama sebagai fallback agar dokumen lama tidak langsung menyebabkan null error, tetapi write baru harus mengikuti schema di bawah.

## Collection Utama

| Collection | Status | Keterangan |
| --- | --- | --- |
| `users` | aktif | Profil Firebase Auth dan role aplikasi. |
| `logbooks` | aktif | Catatan aktivitas operasional per moduleType. |
| `inventory` | aktif | Stok dan kebutuhan operasional. |
| `schedules` | aktif | Jadwal operasional dan status pelaksanaan. |
| `notifications` | didukung | Notifikasi in-app ringan, tanpa FCM server/Cloud Functions. |
| `education_contents` | aktif | Artikel, video link, dan SOP tanpa Storage. |
| `finance_transactions` | aktif | Pemasukan/pengeluaran operasional. |
| `report_metadata` | didukung | Metadata laporan/export di sisi client. |
| `recommendations` | didukung | Rekomendasi/manual insight yang dibuat admin. |

## Field Umum Dokumen Operasional

Dokumen operasional memakai field berikut bila relevan:

```json
{
  "id": "uuid-or-document-id",
  "title": "Judul dokumen",
  "name": "Nama item jika bukan berbentuk judul",
  "description": "Deskripsi panjang jika relevan",
  "notes": "Catatan tambahan",
  "status": "pending",
  "date": "timestamp",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "createdBy": "uid",
  "updatedBy": "uid",
  "isDeleted": false
}
```

`isDeleted` digunakan untuk soft delete data operasional agar dashboard/laporan bisa mengabaikan data yang disembunyikan tanpa kehilangan audit trail.

## `users/{uid}`

```json
{
  "id": "firebase-auth-uid",
  "uid": "firebase-auth-uid",
  "name": "Nama Pengguna",
  "email": "user@example.com",
  "photoUrl": "",
  "role": "operator_lapangan",
  "isActive": true,
  "fcmToken": "optional-client-token",
  "fcmTokenUpdatedAt": "timestamp",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

Role valid: `admin`, `operator_lapangan`, `operator_keuangan`. Legacy role `operator`, `mitra`, dan `peserta_edukasi` masih dapat dibaca untuk kompatibilitas data lama.

## `farm_modules/{moduleType}`

Collection pendukung untuk daftar modul tetap.

Document ID: `ayam_kampung`, `maggot_bsf`, `cacing_tanah`, `lele`, `tanaman`.

```json
{
  "id": "ayam_kampung",
  "name": "Ayam Kampung",
  "type": "ayam",
  "description": "Pencatatan pakan, produksi telur, dan kesehatan ayam.",
  "icon": "egg_alt",
  "color": "#F59E0B",
  "isActive": true,
  "updatedAt": "timestamp"
}
```

## `logbooks/{id}`

```json
{
  "id": "uuid",
  "title": "Pemberian pakan",
  "moduleType": "ayam_kampung",
  "activityDate": "timestamp",
  "quantity": 10,
  "unit": "kg",
  "status": "Baik",
  "notes": "",
  "createdBy": "uid",
  "updatedBy": "uid",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "isDeleted": false
}
```

`moduleType` wajib salah satu dari `ayam_kampung`, `maggot_bsf`, `cacing_tanah`, `lele`, `tanaman`. Query aktif mengabaikan `isDeleted == true` dan mengurutkan `activityDate` terbaru lebih dulu.

## `inventory/{id}`

```json
{
  "id": "uuid",
  "name": "Pakan ayam",
  "category": "Pakan",
  "unit": "kg",
  "currentStock": 20,
  "minStock": 25,
  "isLowStock": true,
  "createdBy": "uid",
  "updatedBy": "uid",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "isDeleted": false
}
```

`isLowStock` dihitung saat save karena Firestore tidak dapat membandingkan dua field dalam query (`currentStock <= minStock`).

## `schedules/{id}`

```json
{
  "id": "uuid",
  "title": "Pakan lele sore",
  "moduleType": "lele",
  "type": "Pakan",
  "date": "timestamp",
  "status": "pending",
  "notes": "",
  "createdBy": "uid",
  "updatedBy": "uid",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "isDeleted": false
}
```

Status valid: `pending`, `done`, `skipped`.

## `notifications/{id}`

```json
{
  "id": "uuid-or-deterministic-id",
  "title": "Stok menipis",
  "body": "Pakan ayam berada di bawah batas minimum.",
  "type": "low_stock",
  "targetRole": "operator_lapangan",
  "userId": "uid-optional",
  "relatedCollection": "inventory",
  "relatedId": "inventory-id",
  "isRead": false,
  "createdAt": "timestamp",
  "scheduledAt": "timestamp-optional",
  "isDeleted": false
}
```

Tipe awal: `low_stock`, `schedule_overdue`, `production_reminder`, `system`. Collection ini dipakai untuk in-app notification yang dibuat client saat user membuka dashboard/inventory/schedule. Tidak ada Cloud Functions atau trigger server.

## `education_contents/{id}`

```json
{
  "id": "uuid",
  "title": "Budidaya Maggot BSF",
  "type": "artikel",
  "content": "Isi materi atau SOP...",
  "externalUrl": "https://example.com/video",
  "isPublished": true,
  "createdBy": "uid",
  "updatedBy": "uid",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "isDeleted": false
}
```

Tipe valid: `artikel`, `video`, `sop`. File media tidak diunggah ke Firebase Storage; gunakan URL eksternal bila perlu.

## `finance_transactions/{id}`

```json
{
  "id": "uuid",
  "type": "income",
  "category": "Penjualan telur",
  "amount": 500000,
  "date": "timestamp",
  "notes": "",
  "createdBy": "uid",
  "updatedBy": "uid",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "isDeleted": false
}
```

Tipe valid: `income`, `expense`. Admin dan operator keuangan dapat membuat/memperbarui transaksi; soft delete hanya dari peran admin.

## `report_metadata/{id}`

```json
{
  "id": "uuid",
  "title": "Laporan operasional Juni 2026",
  "type": "monthly_summary",
  "periodStart": "timestamp",
  "periodEnd": "timestamp",
  "filters": {
    "moduleType": "lele"
  },
  "status": "ready",
  "createdBy": "uid",
  "updatedBy": "uid",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "isDeleted": false
}
```

Gunakan collection ini hanya untuk metadata laporan yang dihasilkan/dikelola client. Jangan simpan file laporan besar di Firestore.

## `recommendations/{id}`

```json
{
  "id": "uuid",
  "title": "Kurangi pakan sore",
  "description": "FCR lele meningkat dalam 7 hari terakhir.",
  "moduleType": "lele",
  "priority": "medium",
  "status": "open",
  "source": "manual",
  "createdBy": "uid",
  "updatedBy": "uid",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "isDeleted": false
}
```

Rekomendasi MVP dibuat manual/admin-side. Tidak ada job backend untuk membuat rekomendasi otomatis.
