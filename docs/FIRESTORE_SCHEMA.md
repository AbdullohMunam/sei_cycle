# Firestore Schema MVP SeiCycle

Semua timestamp menggunakan Firestore `Timestamp`. ID data operasional dibuat
di Flutter menggunakan UUID.

## `users/{uid}`

```json
{
  "uid": "firebase-auth-uid",
  "name": "Nama Pengguna",
  "email": "user@example.com",
  "photo_url": "",
  "role": "operator_lapangan",
  "is_active": true,
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

Role brief yang valid: `admin`, `operator_lapangan`, `operator_keuangan`. Akun
baru selalu dibuat sebagai `operator_lapangan`; admin atau operator keuangan MVP
diubah manual melalui Firebase Console. Legacy `operator` dipetakan sebagai
`operator_lapangan`, sedangkan legacy `mitra` dan `peserta_edukasi` tetap
read-only untuk dashboard/edukasi.

## `farm_modules/{module_id}`

Document ID: `ayam_kampung`, `maggot_bsf`, `cacing_tanah`, `lele`, `tanaman`.

```json
{
  "module_id": "ayam_kampung",
  "module_name": "Ayam Kampung",
  "module_type": "ayam",
  "description": "Pencatatan aktivitas ayam",
  "icon": "egg_alt",
  "color": "#F59E0B",
  "is_active": true,
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

## `logbooks/{id}`

```json
{
  "id": "uuid",
  "module_id": "ayam_kampung",
  "activity_type": "Pemberian pakan",
  "activity_date": "timestamp",
  "quantity": 10,
  "unit": "kg",
  "condition": "Baik",
  "note": "",
  "created_by": "uid",
  "created_at": "timestamp",
  "updated_at": "timestamp",
  "is_deleted": false
}
```

Penghapusan logbook dari UI admin dilakukan dengan mengubah `is_deleted` menjadi `true` agar catatan lama tetap menjadi arsip.

## `inventory_items/{id}`

```json
{
  "id": "uuid",
  "name": "Pakan ayam",
  "category": "Pakan",
  "unit": "kg",
  "current_stock": 20,
  "min_stock": 25,
  "is_low_stock": true,
  "created_by": "uid",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

`is_low_stock` dihitung saat simpan karena Firestore tidak membandingkan dua
field (`current_stock <= min_stock`) dalam query.

## `schedules/{id}`

```json
{
  "id": "uuid",
  "title": "Pakan lele sore",
  "module_id": "lele",
  "schedule_type": "Pakan",
  "scheduled_at": "timestamp",
  "status": "pending",
  "note": "",
  "created_by": "uid",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

Status yang valid: `pending`, `done`, `skipped`.

## `education_contents/{id}`

```json
{
  "id": "uuid",
  "title": "Budidaya Maggot BSF",
  "type": "artikel",
  "content": "Isi materi atau SOP...",
  "external_url": "https://example.com/video",
  "is_published": true,
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

Tipe yang valid: `artikel`, `video`, `sop`. MVP tidak mengunggah file ke
Storage.

## `finance_records/{id}`

```json
{
  "id": "uuid",
  "type": "income",
  "category": "Penjualan telur",
  "amount": 500000,
  "date": "timestamp",
  "note": "",
  "created_by": "uid",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

Tipe yang valid: `income`, `expense`. Collection ini dapat dibaca user aktif untuk tampilan. Admin dan operator keuangan dapat menambah atau mengubah transaksi, sedangkan hapus transaksi hanya untuk admin.
