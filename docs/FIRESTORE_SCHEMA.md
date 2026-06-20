# Firestore Database Schema SeiCycle

## Deskripsi

Database SeiCycle menggunakan Cloud Firestore sebagai database utama. Struktur ini dirancang untuk mendukung fitur operasional Kebun Sei, seperti autentikasi, logbook kegiatan, inventaris, kalender, notifikasi, edukasi, laporan, keuangan, dan AI Recommendation tahap lanjutan.

Firestore menggunakan konsep collection dan document, sehingga struktur database tidak sepenuhnya sama seperti database relasional. Namun, setiap collection tetap dirancang berdasarkan ERD agar data mudah dipahami dan dikembangkan.

---

# 1. Collection: users

Collection `users` menyimpan data profil pengguna aplikasi.

## Document ID

```txt
users/{user_id}
```

`user_id` menggunakan UID dari Firebase Authentication.

## Struktur Data

```json
{
  "name": "Admin Kebun Sei",
  "email": "kebunsei@gmail.com",
  "role": "admin",
  "photo_url": "",
  "is_active": true,
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

## Role Pengguna

```txt
admin
operator
mitra
```

## Keterangan

| Field      | Tipe Data | Keterangan              |
| ---------- | --------- | ----------------------- |
| name       | string    | Nama pengguna           |
| email      | string    | Email pengguna          |
| role       | string    | Hak akses pengguna      |
| photo_url  | string    | URL foto profil         |
| is_active  | boolean   | Status akun aktif/tidak |
| created_at | timestamp | Waktu akun dibuat       |
| updated_at | timestamp | Waktu akun diperbarui   |

---

# 2. Collection: user_devices

Collection `user_devices` digunakan untuk menyimpan token perangkat pengguna yang dipakai oleh Firebase Cloud Messaging.

## Document ID

```txt
user_devices/{device_id}
```

## Struktur Data

```json
{
  "user_id": "firebase_uid",
  "fcm_token": "token_firebase_cloud_messaging",
  "platform": "android",
  "device_name": "Samsung A52",
  "last_active_at": "timestamp",
  "created_at": "timestamp"
}
```

## Platform

```txt
android
ios
web
```

## Keterangan

| Field          | Tipe Data | Keterangan                 |
| -------------- | --------- | -------------------------- |
| user_id        | string    | ID user pemilik perangkat  |
| fcm_token      | string    | Token FCM untuk notifikasi |
| platform       | string    | Platform perangkat         |
| device_name    | string    | Nama perangkat             |
| last_active_at | timestamp | Waktu terakhir aktif       |
| created_at     | timestamp | Waktu data dibuat          |

---

# 3. Collection: farm_modules

Collection `farm_modules` menyimpan data modul pertanian dan peternakan.

## Document ID

```txt
farm_modules/{module_id}
```

## Struktur Data

```json
{
  "module_name": "Ayam Kampung",
  "module_type": "ayam",
  "description": "Modul pencatatan kegiatan ayam kampung",
  "is_active": true,
  "created_at": "timestamp"
}
```

## Module Type

```txt
ayam
maggot
cacing
lele
tanaman
```

## Keterangan

| Field       | Tipe Data | Keterangan         |
| ----------- | --------- | ------------------ |
| module_name | string    | Nama modul         |
| module_type | string    | Jenis modul        |
| description | string    | Deskripsi modul    |
| is_active   | boolean   | Status modul       |
| created_at  | timestamp | Waktu modul dibuat |

---

# 4. Collection: production_cycles

Collection `production_cycles` menyimpan data siklus produksi setiap modul.

## Document ID

```txt
production_cycles/{cycle_id}
```

## Struktur Data

```json
{
  "module_id": "farm_modules_id",
  "cycle_name": "Siklus Ayam Kampung Batch 1",
  "location": "Kandang A",
  "start_date": "2026-06-20",
  "end_date": null,
  "status": "active",
  "notes": "Siklus awal ayam kampung",
  "created_at": "timestamp"
}
```

## Status

```txt
active
completed
cancelled
```

## Keterangan

| Field      | Tipe Data | Keterangan                        |
| ---------- | --------- | --------------------------------- |
| module_id  | string    | ID modul terkait                  |
| cycle_name | string    | Nama siklus produksi              |
| location   | string    | Lokasi kandang, kolam, atau lahan |
| start_date | date      | Tanggal mulai siklus              |
| end_date   | date/null | Tanggal selesai siklus            |
| status     | string    | Status siklus                     |
| notes      | string    | Catatan tambahan                  |
| created_at | timestamp | Waktu data dibuat                 |

---

# 5. Collection: operational_logs

Collection `operational_logs` menyimpan catatan kegiatan harian.

## Document ID

```txt
operational_logs/{log_id}
```

## Struktur Data

```json
{
  "cycle_id": "production_cycles_id",
  "user_id": "firebase_uid",
  "activity_type": "pemberian_pakan",
  "activity_date": "2026-06-20",
  "description": "Pemberian pakan ayam pagi hari",
  "quantity": 5,
  "unit": "kg",
  "photo_url": "",
  "created_at": "timestamp"
}
```

## Activity Type

```txt
pemberian_pakan
penyiraman
pemupukan
panen
pembersihan
pengamatan
perawatan
kematian
penambahan_bibit
lainnya
```

## Keterangan

| Field         | Tipe Data | Keterangan            |
| ------------- | --------- | --------------------- |
| cycle_id      | string    | ID siklus produksi    |
| user_id       | string    | ID user yang mencatat |
| activity_type | string    | Jenis kegiatan        |
| activity_date | date      | Tanggal kegiatan      |
| description   | string    | Deskripsi kegiatan    |
| quantity      | number    | Jumlah kegiatan/bahan |
| unit          | string    | Satuan                |
| photo_url     | string    | URL foto dokumentasi  |
| created_at    | timestamp | Waktu log dibuat      |

---

# 6. Collection: production_results

Collection `production_results` menyimpan hasil panen atau hasil produksi.

## Document ID

```txt
production_results/{result_id}
```

## Struktur Data

```json
{
  "cycle_id": "production_cycles_id",
  "harvest_date": "2026-07-10",
  "product_name": "Lele",
  "quantity": 25,
  "unit": "kg",
  "quality_status": "baik",
  "notes": "Panen pertama"
}
```

## Quality Status

```txt
baik
cukup
kurang
gagal
```

---

# 7. Collection: inventory_items

Collection `inventory_items` menyimpan data stok barang.

## Document ID

```txt
inventory_items/{item_id}
```

## Struktur Data

```json
{
  "module_id": "farm_modules_id",
  "item_name": "Pakan Ayam",
  "category": "pakan",
  "current_stock": 20,
  "unit": "kg",
  "minimum_stock": 5,
  "location": "Gudang Utama",
  "created_at": "timestamp"
}
```

## Category

```txt
pakan
bibit
pupuk
alat
bahan_produksi
obat
lainnya
```

## Keterangan

| Field         | Tipe Data   | Keterangan                                    |
| ------------- | ----------- | --------------------------------------------- |
| module_id     | string/null | ID modul terkait, boleh kosong jika stok umum |
| item_name     | string      | Nama barang                                   |
| category      | string      | Kategori barang                               |
| current_stock | number      | Jumlah stok saat ini                          |
| unit          | string      | Satuan stok                                   |
| minimum_stock | number      | Batas minimum stok                            |
| location      | string      | Lokasi penyimpanan                            |
| created_at    | timestamp   | Waktu item dibuat                             |

---

# 8. Collection: inventory_transactions

Collection `inventory_transactions` menyimpan riwayat keluar-masuk stok.

## Document ID

```txt
inventory_transactions/{transaction_id}
```

## Struktur Data

```json
{
  "item_id": "inventory_items_id",
  "user_id": "firebase_uid",
  "transaction_type": "out",
  "quantity": 2,
  "unit": "kg",
  "notes": "Dipakai untuk pakan ayam pagi",
  "transaction_date": "timestamp"
}
```

## Transaction Type

```txt
in
out
adjustment
```

---

# 9. Collection: stock_alerts

Collection `stock_alerts` menyimpan peringatan stok rendah atau stok habis.

## Document ID

```txt
stock_alerts/{alert_id}
```

## Struktur Data

```json
{
  "item_id": "inventory_items_id",
  "user_id": "firebase_uid",
  "alert_type": "low_stock",
  "message": "Stok pakan ayam hampir habis",
  "is_read": false,
  "created_at": "timestamp"
}
```

## Alert Type

```txt
low_stock
out_of_stock
```

---

# 10. Collection: schedules

Collection `schedules` menyimpan jadwal kegiatan operasional.

## Document ID

```txt
schedules/{schedule_id}
```

## Struktur Data

```json
{
  "cycle_id": "production_cycles_id",
  "module_id": "farm_modules_id",
  "user_id": "firebase_uid",
  "title": "Pemberian Pakan Lele",
  "activity_type": "pemberian_pakan",
  "schedule_date": "timestamp",
  "status": "pending",
  "notes": "Pakan pagi pukul 08.00"
}
```

## Status

```txt
pending
done
cancelled
missed
```

---

# 11. Collection: notifications

Collection `notifications` menyimpan notifikasi untuk pengguna.

## Document ID

```txt
notifications/{notification_id}
```

## Struktur Data

```json
{
  "schedule_id": "schedules_id",
  "user_id": "firebase_uid",
  "title": "Pengingat Pakan",
  "message": "Saatnya memberi pakan lele",
  "type": "reminder",
  "is_read": false,
  "created_at": "timestamp"
}
```

## Notification Type

```txt
reminder
alert
info
```

---

# 12. Collection: education_materials

Collection `education_materials` menyimpan artikel, video tutorial, dan SOP.

## Document ID

```txt
education_materials/{material_id}
```

## Struktur Data

```json
{
  "user_id": "firebase_uid",
  "title": "SOP Pemberian Pakan Maggot",
  "type": "sop",
  "content": "Isi SOP operasional...",
  "file_url": "firebase_storage_url",
  "category": "maggot",
  "created_at": "timestamp"
}
```

## Material Type

```txt
artikel
video
sop
```

---

# 13. Collection: finance_transactions

Collection `finance_transactions` menyimpan pemasukan dan pengeluaran.

## Document ID

```txt
finance_transactions/{finance_id}
```

## Struktur Data

```json
{
  "user_id": "firebase_uid",
  "transaction_type": "expense",
  "category": "pakan",
  "description": "Pembelian pakan ayam",
  "amount": 150000,
  "transaction_date": "2026-06-20",
  "created_at": "timestamp"
}
```

## Transaction Type

```txt
income
expense
```

---

# 14. Collection: circular_flows

Collection `circular_flows` menyimpan aliran material antar modul untuk mendukung konsep ekonomi sirkular.

## Document ID

```txt
circular_flows/{flow_id}
```

## Struktur Data

```json
{
  "source_module_id": "farm_modules_id",
  "destination_module_id": "farm_modules_id",
  "material_name": "Kotoran Ayam",
  "quantity": 10,
  "unit": "kg",
  "flow_date": "2026-06-20",
  "notes": "Digunakan sebagai bahan kompos untuk tanaman"
}
```

## Contoh Alur

```txt
Ayam Kampung -> Tanaman
Maggot BSF -> Lele
Cacing Tanah -> Tanaman
Tanaman -> Ayam Kampung
```

---

# 15. Collection: reports

Collection `reports` menyimpan data laporan yang telah dibuat.

## Document ID

```txt
reports/{report_id}
```

## Struktur Data

```json
{
  "user_id": "firebase_uid",
  "report_type": "production",
  "file_url": "firebase_storage_url",
  "start_date": "2026-06-01",
  "end_date": "2026-06-30",
  "generated_at": "timestamp"
}
```

## Report Type

```txt
production
inventory
finance
operational
```

---

# 16. Collection: ai_recommendations

Collection `ai_recommendations` merupakan collection tahap lanjutan. Collection ini disiapkan untuk fitur AI Recommendation seperti prediksi panen, evaluasi produktivitas, dan rekomendasi berbasis data.

## Document ID

```txt
ai_recommendations/{recommendation_id}
```

## Struktur Data

```json
{
  "cycle_id": "production_cycles_id",
  "module_id": "farm_modules_id",
  "user_id": "firebase_uid",
  "recommendation_type": "prediksi_panen",
  "title": "Prediksi Panen Lele",
  "description": "Sistem memperkirakan panen lele dapat dilakukan dalam 14 hari.",
  "source_data": "Data logbook, stok pakan, dan hasil pengamatan siklus produksi.",
  "prediction_value": 25,
  "confidence_score": 0.85,
  "suggested_action": "Lakukan pemantauan bobot lele setiap 3 hari.",
  "status": "generated",
  "implementation_stage": "tahap_lanjutan",
  "notes": "Fitur ini dikembangkan setelah modul utama stabil.",
  "created_at": "timestamp"
}
```

## Recommendation Type

```txt
prediksi_panen
evaluasi_produktivitas
rekomendasi_tindakan
```

## Status

```txt
generated
reviewed
applied
ignored
```

## Catatan

Field `implementation_stage` diisi dengan:

```txt
tahap_lanjutan
```

Hal ini menunjukkan bahwa fitur AI Recommendation bukan prioritas utama pada pengembangan awal, tetapi tetap disiapkan agar sistem mudah dikembangkan di masa depan.

---

# Rekomendasi Index Firestore

Beberapa query kemungkinan membutuhkan index tambahan di Firestore.

## Query Logbook per Siklus

```txt
collection: operational_logs
where: cycle_id
orderBy: activity_date desc
```

## Query Jadwal Hari Ini

```txt
collection: schedules
where: schedule_date
where: status
orderBy: schedule_date asc
```

## Query Stok Rendah

```txt
collection: inventory_items
where: current_stock <= minimum_stock
```

Catatan: query perbandingan antar dua field seperti `current_stock <= minimum_stock` tidak bisa langsung dilakukan secara sederhana di Firestore. Untuk implementasi, sistem dapat membuat `stock_status` atau `is_low_stock`.

Contoh tambahan field pada `inventory_items`:

```json
{
  "is_low_stock": true,
  "stock_status": "low"
}
```

## Query Keuangan per Periode

```txt
collection: finance_transactions
where: transaction_date >= start_date
where: transaction_date <= end_date
orderBy: transaction_date desc
```

## Query Notifikasi User

```txt
collection: notifications
where: user_id
where: is_read
orderBy: created_at desc
```

---

# Catatan Implementasi Firestore

1. Semua document sebaiknya memiliki field `created_at`.
2. Data yang sering diperbarui sebaiknya memiliki field `updated_at`.
3. ID user menggunakan UID dari Firebase Authentication.
4. File seperti foto logbook, SOP, video, dan laporan disimpan di Firebase Storage.
5. URL file dari Firebase Storage disimpan ke Firestore melalui field `photo_url` atau `file_url`.
6. Collection `ai_recommendations` tidak wajib diimplementasikan pada tahap awal.
7. Untuk fitur dashboard, tidak perlu membuat collection khusus karena data dashboard dapat dihitung dari collection lain.
