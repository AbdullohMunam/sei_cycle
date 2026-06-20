# API Specification SeiCycle

## Deskripsi

API SeiCycle digunakan sebagai rancangan komunikasi antara aplikasi Flutter, Firebase, dan backend service. API ini dirancang untuk mendukung fitur utama aplikasi SeiCycle, yaitu autentikasi, dashboard, logbook operasional, inventaris, kalender, notifikasi, edukasi, laporan, keuangan, dan AI Recommendation tahap lanjutan.

API ini dapat diimplementasikan menggunakan Firebase Cloud Functions, Express.js, atau backend service lain yang terhubung dengan Firebase Authentication, Cloud Firestore, Firebase Storage, dan Firebase Cloud Messaging.

---

# 1. Base URL

Untuk development lokal:

```txt
http://localhost:5000/api/v1
```

Untuk production:

```txt
https://api.seicycle.id/api/v1
```

Catatan: URL production masih bersifat rancangan dan dapat diganti sesuai kebutuhan deployment.

---

# 2. Authentication

API menggunakan Firebase Authentication. Setelah user login melalui aplikasi Flutter, aplikasi akan mendapatkan Firebase ID Token. Token tersebut dikirim ke backend melalui header Authorization.

## Header Authorization

```http
Authorization: Bearer <firebase_id_token>
Content-Type: application/json
```

## Role Pengguna

```txt
admin
operator
mitra
```

## Hak Akses Umum

| Role     | Hak Akses                                                            |
| -------- | -------------------------------------------------------------------- |
| admin    | Mengelola semua data, user, laporan, edukasi, dan konfigurasi sistem |
| operator | Menginput logbook, stok, jadwal, dan aktivitas operasional           |
| mitra    | Melihat materi edukasi, SOP, artikel, dan video                      |

---

# 3. Standard Response Format

## Success Response

```json
{
  "success": true,
  "message": "Data berhasil diambil",
  "data": {}
}
```

## Error Response

```json
{
  "success": false,
  "message": "Terjadi kesalahan",
  "error": "Detail error"
}
```

## Pagination Response

```json
{
  "success": true,
  "message": "Data berhasil diambil",
  "data": [],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 100
  }
}
```

---

# 4. Health Check API

Endpoint ini digunakan untuk memastikan backend berjalan.

| Method | Endpoint  | Auth | Role   | Fungsi              |
| ------ | --------- | ---- | ------ | ------------------- |
| GET    | `/health` | No   | Public | Mengecek status API |

## Response

```json
{
  "success": true,
  "message": "SeiCycle API is running",
  "data": {
    "service": "SeiCycle Backend",
    "status": "healthy"
  }
}
```

---

# 5. Auth & Users API

## 5.1 Get Current User

| Method | Endpoint    | Auth | Role | Fungsi                      |
| ------ | ----------- | ---- | ---- | --------------------------- |
| GET    | `/users/me` | Yes  | All  | Mengambil profil user login |

### Response

```json
{
  "success": true,
  "message": "Profil user berhasil diambil",
  "data": {
    "user_id": "firebase_uid",
    "name": "Admin Kebun Sei",
    "email": "kebunsei@gmail.com",
    "role": "admin",
    "photo_url": "",
    "is_active": true
  }
}
```

---

## 5.2 Update Current User

| Method | Endpoint    | Auth | Role | Fungsi                     |
| ------ | ----------- | ---- | ---- | -------------------------- |
| PUT    | `/users/me` | Yes  | All  | Mengubah profil user login |

### Request Body

```json
{
  "name": "Admin Kebun Sei",
  "photo_url": "https://storage.firebase.com/photo.jpg"
}
```

---

## 5.3 Get All Users

| Method | Endpoint | Auth | Role  | Fungsi               |
| ------ | -------- | ---- | ----- | -------------------- |
| GET    | `/users` | Yes  | admin | Mengambil semua user |

### Query Parameters

| Parameter | Tipe    | Keterangan                      |
| --------- | ------- | ------------------------------- |
| role      | string  | Filter berdasarkan role         |
| is_active | boolean | Filter berdasarkan status aktif |
| page      | number  | Nomor halaman                   |
| limit     | number  | Jumlah data per halaman         |

---

## 5.4 Update User Role

| Method | Endpoint               | Auth | Role  | Fungsi             |
| ------ | ---------------------- | ---- | ----- | ------------------ |
| PUT    | `/users/{userId}/role` | Yes  | admin | Mengubah role user |

### Request Body

```json
{
  "role": "operator"
}
```

---

# 6. User Devices API

API ini digunakan untuk menyimpan FCM token dari perangkat user agar sistem dapat mengirim notifikasi.

## 6.1 Register Device

| Method | Endpoint        | Auth | Role | Fungsi                         |
| ------ | --------------- | ---- | ---- | ------------------------------ |
| POST   | `/user-devices` | Yes  | All  | Menyimpan token perangkat user |

### Request Body

```json
{
  "fcm_token": "firebase_cloud_messaging_token",
  "platform": "android",
  "device_name": "Samsung A52"
}
```

---

## 6.2 Delete Device

| Method | Endpoint                   | Auth | Role | Fungsi                    |
| ------ | -------------------------- | ---- | ---- | ------------------------- |
| DELETE | `/user-devices/{deviceId}` | Yes  | All  | Menghapus token perangkat |

---

# 7. Farm Modules API

Farm Modules digunakan untuk modul Ayam Kampung, Maggot BSF, Cacing Tanah, Lele, dan Tanaman.

## 7.1 Get Farm Modules

| Method | Endpoint        | Auth | Role | Fungsi                 |
| ------ | --------------- | ---- | ---- | ---------------------- |
| GET    | `/farm-modules` | Yes  | All  | Mengambil daftar modul |

### Response

```json
{
  "success": true,
  "message": "Data modul berhasil diambil",
  "data": [
    {
      "module_id": "module_ayam",
      "module_name": "Ayam Kampung",
      "module_type": "ayam",
      "description": "Modul pencatatan ayam kampung",
      "is_active": true
    }
  ]
}
```

---

## 7.2 Create Farm Module

| Method | Endpoint        | Auth | Role  | Fungsi              |
| ------ | --------------- | ---- | ----- | ------------------- |
| POST   | `/farm-modules` | Yes  | admin | Menambah modul baru |

### Request Body

```json
{
  "module_name": "Lele",
  "module_type": "lele",
  "description": "Modul pencatatan budidaya lele"
}
```

---

## 7.3 Get Farm Module Detail

| Method | Endpoint                   | Auth | Role | Fungsi                 |
| ------ | -------------------------- | ---- | ---- | ---------------------- |
| GET    | `/farm-modules/{moduleId}` | Yes  | All  | Mengambil detail modul |

---

## 7.4 Update Farm Module

| Method | Endpoint                   | Auth | Role  | Fungsi              |
| ------ | -------------------------- | ---- | ----- | ------------------- |
| PUT    | `/farm-modules/{moduleId}` | Yes  | admin | Mengubah data modul |

---

## 7.5 Delete Farm Module

| Method | Endpoint                   | Auth | Role  | Fungsi                             |
| ------ | -------------------------- | ---- | ----- | ---------------------------------- |
| DELETE | `/farm-modules/{moduleId}` | Yes  | admin | Menonaktifkan atau menghapus modul |

---

# 8. Production Cycles API

Production Cycles digunakan untuk mencatat siklus produksi setiap modul.

## 8.1 Get Production Cycles

| Method | Endpoint             | Auth | Role            | Fungsi                           |
| ------ | -------------------- | ---- | --------------- | -------------------------------- |
| GET    | `/production-cycles` | Yes  | admin, operator | Mengambil daftar siklus produksi |

### Query Parameters

| Parameter  | Tipe   | Keterangan                   |
| ---------- | ------ | ---------------------------- |
| module_id  | string | Filter berdasarkan modul     |
| status     | string | active, completed, cancelled |
| start_date | date   | Filter tanggal mulai         |
| end_date   | date   | Filter tanggal akhir         |

---

## 8.2 Create Production Cycle

| Method | Endpoint             | Auth | Role            | Fungsi                  |
| ------ | -------------------- | ---- | --------------- | ----------------------- |
| POST   | `/production-cycles` | Yes  | admin, operator | Membuat siklus produksi |

### Request Body

```json
{
  "module_id": "module_lele",
  "cycle_name": "Siklus Lele Kolam 1",
  "location": "Kolam 1",
  "start_date": "2026-06-20",
  "status": "active",
  "notes": "Siklus awal budidaya lele"
}
```

---

## 8.3 Get Production Cycle Detail

| Method | Endpoint                       | Auth | Role            | Fungsi                           |
| ------ | ------------------------------ | ---- | --------------- | -------------------------------- |
| GET    | `/production-cycles/{cycleId}` | Yes  | admin, operator | Mengambil detail siklus produksi |

---

## 8.4 Update Production Cycle

| Method | Endpoint                       | Auth | Role            | Fungsi                        |
| ------ | ------------------------------ | ---- | --------------- | ----------------------------- |
| PUT    | `/production-cycles/{cycleId}` | Yes  | admin, operator | Mengubah data siklus produksi |

---

## 8.5 Complete Production Cycle

| Method | Endpoint                                | Auth | Role            | Fungsi                  |
| ------ | --------------------------------------- | ---- | --------------- | ----------------------- |
| PUT    | `/production-cycles/{cycleId}/complete` | Yes  | admin, operator | Menandai siklus selesai |

### Request Body

```json
{
  "end_date": "2026-07-20",
  "notes": "Siklus selesai dan sudah dilakukan panen"
}
```

---

## 8.6 Delete Production Cycle

| Method | Endpoint                       | Auth | Role  | Fungsi                    |
| ------ | ------------------------------ | ---- | ----- | ------------------------- |
| DELETE | `/production-cycles/{cycleId}` | Yes  | admin | Menghapus siklus produksi |

---

# 9. Operational Logs API

Operational Logs digunakan untuk logbook harian kegiatan pertanian dan peternakan.

## 9.1 Get Operational Logs

| Method | Endpoint            | Auth | Role            | Fungsi                 |
| ------ | ------------------- | ---- | --------------- | ---------------------- |
| GET    | `/operational-logs` | Yes  | admin, operator | Mengambil data logbook |

### Query Parameters

| Parameter     | Tipe   | Keterangan                |
| ------------- | ------ | ------------------------- |
| cycle_id      | string | Filter berdasarkan siklus |
| user_id       | string | Filter berdasarkan user   |
| activity_type | string | Filter jenis kegiatan     |
| start_date    | date   | Tanggal awal              |
| end_date      | date   | Tanggal akhir             |

---

## 9.2 Create Operational Log

| Method | Endpoint            | Auth | Role            | Fungsi                    |
| ------ | ------------------- | ---- | --------------- | ------------------------- |
| POST   | `/operational-logs` | Yes  | admin, operator | Menambah logbook kegiatan |

### Request Body

```json
{
  "cycle_id": "cycle_001",
  "activity_type": "pemberian_pakan",
  "activity_date": "2026-06-20",
  "description": "Pemberian pakan pagi",
  "quantity": 5,
  "unit": "kg",
  "photo_url": ""
}
```

---

## 9.3 Get Operational Log Detail

| Method | Endpoint                    | Auth | Role            | Fungsi                   |
| ------ | --------------------------- | ---- | --------------- | ------------------------ |
| GET    | `/operational-logs/{logId}` | Yes  | admin, operator | Mengambil detail logbook |

---

## 9.4 Update Operational Log

| Method | Endpoint                    | Auth | Role            | Fungsi           |
| ------ | --------------------------- | ---- | --------------- | ---------------- |
| PUT    | `/operational-logs/{logId}` | Yes  | admin, operator | Mengubah logbook |

---

## 9.5 Delete Operational Log

| Method | Endpoint                    | Auth | Role  | Fungsi            |
| ------ | --------------------------- | ---- | ----- | ----------------- |
| DELETE | `/operational-logs/{logId}` | Yes  | admin | Menghapus logbook |

---

# 10. Production Results API

Production Results digunakan untuk mencatat hasil panen atau produksi.

## 10.1 Get Production Results

| Method | Endpoint              | Auth | Role            | Fungsi                   |
| ------ | --------------------- | ---- | --------------- | ------------------------ |
| GET    | `/production-results` | Yes  | admin, operator | Mengambil hasil produksi |

### Query Parameters

| Parameter    | Tipe   | Keterangan                |
| ------------ | ------ | ------------------------- |
| cycle_id     | string | Filter berdasarkan siklus |
| product_name | string | Filter produk             |
| start_date   | date   | Tanggal awal              |
| end_date     | date   | Tanggal akhir             |

---

## 10.2 Create Production Result

| Method | Endpoint              | Auth | Role            | Fungsi                  |
| ------ | --------------------- | ---- | --------------- | ----------------------- |
| POST   | `/production-results` | Yes  | admin, operator | Menambah hasil produksi |

### Request Body

```json
{
  "cycle_id": "cycle_001",
  "harvest_date": "2026-07-10",
  "product_name": "Lele",
  "quantity": 25,
  "unit": "kg",
  "quality_status": "baik",
  "notes": "Panen pertama"
}
```

---

## 10.3 Update Production Result

| Method | Endpoint                         | Auth | Role            | Fungsi                  |
| ------ | -------------------------------- | ---- | --------------- | ----------------------- |
| PUT    | `/production-results/{resultId}` | Yes  | admin, operator | Mengubah hasil produksi |

---

## 10.4 Delete Production Result

| Method | Endpoint                         | Auth | Role  | Fungsi                   |
| ------ | -------------------------------- | ---- | ----- | ------------------------ |
| DELETE | `/production-results/{resultId}` | Yes  | admin | Menghapus hasil produksi |

---

# 11. Inventory API

Inventory digunakan untuk mengelola stok pakan, bahan produksi, pupuk, alat, obat, dan stok lainnya.

## 11.1 Get Inventory Items

| Method | Endpoint           | Auth | Role            | Fungsi                     |
| ------ | ------------------ | ---- | --------------- | -------------------------- |
| GET    | `/inventory/items` | Yes  | admin, operator | Mengambil daftar item stok |

### Query Parameters

| Parameter    | Tipe   | Keterangan         |
| ------------ | ------ | ------------------ |
| category     | string | Filter kategori    |
| module_id    | string | Filter modul       |
| stock_status | string | normal, low, empty |

---

## 11.2 Create Inventory Item

| Method | Endpoint           | Auth | Role            | Fungsi             |
| ------ | ------------------ | ---- | --------------- | ------------------ |
| POST   | `/inventory/items` | Yes  | admin, operator | Menambah item stok |

### Request Body

```json
{
  "module_id": "module_ayam",
  "item_name": "Pakan Ayam",
  "category": "pakan",
  "current_stock": 20,
  "unit": "kg",
  "minimum_stock": 5,
  "location": "Gudang Utama"
}
```

---

## 11.3 Update Inventory Item

| Method | Endpoint                    | Auth | Role            | Fungsi                  |
| ------ | --------------------------- | ---- | --------------- | ----------------------- |
| PUT    | `/inventory/items/{itemId}` | Yes  | admin, operator | Mengubah data item stok |

---

## 11.4 Delete Inventory Item

| Method | Endpoint                    | Auth | Role  | Fungsi              |
| ------ | --------------------------- | ---- | ----- | ------------------- |
| DELETE | `/inventory/items/{itemId}` | Yes  | admin | Menghapus item stok |

---

## 11.5 Get Inventory Transactions

| Method | Endpoint                  | Auth | Role            | Fungsi                           |
| ------ | ------------------------- | ---- | --------------- | -------------------------------- |
| GET    | `/inventory/transactions` | Yes  | admin, operator | Mengambil riwayat transaksi stok |

---

## 11.6 Create Inventory Transaction

| Method | Endpoint                  | Auth | Role            | Fungsi                               |
| ------ | ------------------------- | ---- | --------------- | ------------------------------------ |
| POST   | `/inventory/transactions` | Yes  | admin, operator | Menambah transaksi stok masuk/keluar |

### Request Body

```json
{
  "item_id": "item_pakan_ayam",
  "transaction_type": "out",
  "quantity": 2,
  "unit": "kg",
  "notes": "Dipakai untuk pakan ayam pagi"
}
```

---

## 11.7 Get Low Stock Items

| Method | Endpoint               | Auth | Role            | Fungsi                       |
| ------ | ---------------------- | ---- | --------------- | ---------------------------- |
| GET    | `/inventory/low-stock` | Yes  | admin, operator | Mengambil daftar stok rendah |

---

# 12. Stock Alerts API

Stock Alerts digunakan untuk mengelola peringatan stok rendah atau stok habis.

## 12.1 Get Stock Alerts

| Method | Endpoint        | Auth | Role            | Fungsi                           |
| ------ | --------------- | ---- | --------------- | -------------------------------- |
| GET    | `/stock-alerts` | Yes  | admin, operator | Mengambil daftar peringatan stok |

---

## 12.2 Mark Stock Alert as Read

| Method | Endpoint                       | Auth | Role            | Fungsi                      |
| ------ | ------------------------------ | ---- | --------------- | --------------------------- |
| PUT    | `/stock-alerts/{alertId}/read` | Yes  | admin, operator | Menandai alert sudah dibaca |

---

# 13. Schedules API

Schedules digunakan untuk mengelola jadwal operasional seperti pakan, panen, pemupukan, dan kegiatan lainnya.

## 13.1 Get Schedules

| Method | Endpoint     | Auth | Role            | Fungsi                  |
| ------ | ------------ | ---- | --------------- | ----------------------- |
| GET    | `/schedules` | Yes  | admin, operator | Mengambil daftar jadwal |

### Query Parameters

| Parameter | Tipe   | Keterangan                       |
| --------- | ------ | -------------------------------- |
| date      | date   | Filter tanggal                   |
| status    | string | pending, done, cancelled, missed |
| module_id | string | Filter modul                     |
| cycle_id  | string | Filter siklus                    |

---

## 13.2 Get Today Schedules

| Method | Endpoint           | Auth | Role            | Fungsi                    |
| ------ | ------------------ | ---- | --------------- | ------------------------- |
| GET    | `/schedules/today` | Yes  | admin, operator | Mengambil jadwal hari ini |

---

## 13.3 Create Schedule

| Method | Endpoint     | Auth | Role            | Fungsi          |
| ------ | ------------ | ---- | --------------- | --------------- |
| POST   | `/schedules` | Yes  | admin, operator | Menambah jadwal |

### Request Body

```json
{
  "cycle_id": "cycle_001",
  "module_id": "module_lele",
  "title": "Pemberian Pakan Lele",
  "activity_type": "pemberian_pakan",
  "schedule_date": "2026-06-20T08:00:00",
  "notes": "Pakan pagi"
}
```

---

## 13.4 Update Schedule

| Method | Endpoint                  | Auth | Role            | Fungsi          |
| ------ | ------------------------- | ---- | --------------- | --------------- |
| PUT    | `/schedules/{scheduleId}` | Yes  | admin, operator | Mengubah jadwal |

---

## 13.5 Mark Schedule as Done

| Method | Endpoint                       | Auth | Role            | Fungsi                  |
| ------ | ------------------------------ | ---- | --------------- | ----------------------- |
| PUT    | `/schedules/{scheduleId}/done` | Yes  | admin, operator | Menandai jadwal selesai |

---

## 13.6 Delete Schedule

| Method | Endpoint                  | Auth | Role  | Fungsi           |
| ------ | ------------------------- | ---- | ----- | ---------------- |
| DELETE | `/schedules/{scheduleId}` | Yes  | admin | Menghapus jadwal |

---

# 14. Notifications API

Notifications digunakan untuk menampilkan dan mengirim notifikasi kepada user.

## 14.1 Get Notifications

| Method | Endpoint         | Auth | Role | Fungsi                          |
| ------ | ---------------- | ---- | ---- | ------------------------------- |
| GET    | `/notifications` | Yes  | All  | Mengambil notifikasi user login |

### Query Parameters

| Parameter | Tipe    | Keterangan            |
| --------- | ------- | --------------------- |
| is_read   | boolean | Filter status dibaca  |
| type      | string  | reminder, alert, info |

---

## 14.2 Mark Notification as Read

| Method | Endpoint                               | Auth | Role | Fungsi                           |
| ------ | -------------------------------------- | ---- | ---- | -------------------------------- |
| PUT    | `/notifications/{notificationId}/read` | Yes  | All  | Menandai notifikasi sudah dibaca |

---

## 14.3 Send Notification

| Method | Endpoint              | Auth | Role  | Fungsi                      |
| ------ | --------------------- | ---- | ----- | --------------------------- |
| POST   | `/notifications/send` | Yes  | admin | Mengirim notifikasi ke user |

### Request Body

```json
{
  "user_id": "firebase_uid",
  "title": "Pengingat Pakan",
  "message": "Saatnya memberi pakan lele",
  "type": "reminder"
}
```

---

# 15. Education Materials API

Education Materials digunakan untuk mengelola artikel, video tutorial, dan SOP operasional.

## 15.1 Get Education Materials

| Method | Endpoint               | Auth | Role | Fungsi                   |
| ------ | ---------------------- | ---- | ---- | ------------------------ |
| GET    | `/education-materials` | Yes  | All  | Mengambil materi edukasi |

### Query Parameters

| Parameter | Tipe   | Keterangan                          |
| --------- | ------ | ----------------------------------- |
| type      | string | artikel, video, sop                 |
| category  | string | ayam, maggot, cacing, lele, tanaman |

---

## 15.2 Create Education Material

| Method | Endpoint               | Auth | Role  | Fungsi                  |
| ------ | ---------------------- | ---- | ----- | ----------------------- |
| POST   | `/education-materials` | Yes  | admin | Menambah materi edukasi |

### Request Body

```json
{
  "title": "SOP Pemberian Pakan Maggot",
  "type": "sop",
  "content": "Isi SOP operasional...",
  "file_url": "firebase_storage_url",
  "category": "maggot"
}
```

---

## 15.3 Get Education Material Detail

| Method | Endpoint                            | Auth | Role | Fungsi                          |
| ------ | ----------------------------------- | ---- | ---- | ------------------------------- |
| GET    | `/education-materials/{materialId}` | Yes  | All  | Mengambil detail materi edukasi |

---

## 15.4 Update Education Material

| Method | Endpoint                            | Auth | Role  | Fungsi                  |
| ------ | ----------------------------------- | ---- | ----- | ----------------------- |
| PUT    | `/education-materials/{materialId}` | Yes  | admin | Mengubah materi edukasi |

---

## 15.5 Delete Education Material

| Method | Endpoint                            | Auth | Role  | Fungsi                   |
| ------ | ----------------------------------- | ---- | ----- | ------------------------ |
| DELETE | `/education-materials/{materialId}` | Yes  | admin | Menghapus materi edukasi |

---

# 16. Finance API

Finance digunakan untuk pencatatan pemasukan, pengeluaran, dan laba rugi sederhana.

## 16.1 Get Finance Transactions

| Method | Endpoint                | Auth | Role            | Fungsi                       |
| ------ | ----------------------- | ---- | --------------- | ---------------------------- |
| GET    | `/finance/transactions` | Yes  | admin, operator | Mengambil transaksi keuangan |

### Query Parameters

| Parameter        | Tipe   | Keterangan          |
| ---------------- | ------ | ------------------- |
| transaction_type | string | income atau expense |
| category         | string | Kategori transaksi  |
| start_date       | date   | Tanggal awal        |
| end_date         | date   | Tanggal akhir       |

---

## 16.2 Create Finance Transaction

| Method | Endpoint                | Auth | Role            | Fungsi                      |
| ------ | ----------------------- | ---- | --------------- | --------------------------- |
| POST   | `/finance/transactions` | Yes  | admin, operator | Menambah transaksi keuangan |

### Request Body

```json
{
  "transaction_type": "expense",
  "category": "pakan",
  "description": "Pembelian pakan ayam",
  "amount": 150000,
  "transaction_date": "2026-06-20"
}
```

---

## 16.3 Update Finance Transaction

| Method | Endpoint                            | Auth | Role            | Fungsi                      |
| ------ | ----------------------------------- | ---- | --------------- | --------------------------- |
| PUT    | `/finance/transactions/{financeId}` | Yes  | admin, operator | Mengubah transaksi keuangan |

---

## 16.4 Delete Finance Transaction

| Method | Endpoint                            | Auth | Role  | Fungsi                       |
| ------ | ----------------------------------- | ---- | ----- | ---------------------------- |
| DELETE | `/finance/transactions/{financeId}` | Yes  | admin | Menghapus transaksi keuangan |

---

## 16.5 Get Finance Summary

| Method | Endpoint           | Auth | Role  | Fungsi                                                    |
| ------ | ------------------ | ---- | ----- | --------------------------------------------------------- |
| GET    | `/finance/summary` | Yes  | admin | Mengambil ringkasan pemasukan, pengeluaran, dan laba rugi |

### Query Parameters

| Parameter  | Tipe | Keterangan    |
| ---------- | ---- | ------------- |
| start_date | date | Tanggal awal  |
| end_date   | date | Tanggal akhir |

### Response

```json
{
  "success": true,
  "message": "Ringkasan keuangan berhasil diambil",
  "data": {
    "total_income": 5000000,
    "total_expense": 2500000,
    "profit": 2500000
  }
}
```

---

# 17. Circular Flows API

Circular Flows digunakan untuk mencatat aliran material antar modul dalam sistem ekonomi sirkular.

## 17.1 Get Circular Flows

| Method | Endpoint          | Auth | Role            | Fungsi                         |
| ------ | ----------------- | ---- | --------------- | ------------------------------ |
| GET    | `/circular-flows` | Yes  | admin, operator | Mengambil data aliran sirkular |

---

## 17.2 Create Circular Flow

| Method | Endpoint          | Auth | Role            | Fungsi                        |
| ------ | ----------------- | ---- | --------------- | ----------------------------- |
| POST   | `/circular-flows` | Yes  | admin, operator | Menambah data aliran sirkular |

### Request Body

```json
{
  "source_module_id": "module_ayam",
  "destination_module_id": "module_tanaman",
  "material_name": "Kotoran Ayam",
  "quantity": 10,
  "unit": "kg",
  "flow_date": "2026-06-20",
  "notes": "Digunakan sebagai bahan kompos"
}
```

---

## 17.3 Update Circular Flow

| Method | Endpoint                   | Auth | Role            | Fungsi                        |
| ------ | -------------------------- | ---- | --------------- | ----------------------------- |
| PUT    | `/circular-flows/{flowId}` | Yes  | admin, operator | Mengubah data aliran sirkular |

---

## 17.4 Delete Circular Flow

| Method | Endpoint                   | Auth | Role  | Fungsi                         |
| ------ | -------------------------- | ---- | ----- | ------------------------------ |
| DELETE | `/circular-flows/{flowId}` | Yes  | admin | Menghapus data aliran sirkular |

---

# 18. Dashboard API

Dashboard API digunakan untuk menampilkan ringkasan operasional, ekonomi, aktivitas harian, dan siklus nutrisi.

## 18.1 Get Dashboard Summary

| Method | Endpoint             | Auth | Role            | Fungsi                              |
| ------ | -------------------- | ---- | --------------- | ----------------------------------- |
| GET    | `/dashboard/summary` | Yes  | admin, operator | Mengambil ringkasan utama dashboard |

### Response

```json
{
  "success": true,
  "message": "Dashboard summary berhasil diambil",
  "data": {
    "total_modules": 5,
    "active_cycles": 4,
    "today_logs": 8,
    "low_stock_count": 2,
    "today_schedules": 5,
    "total_income": 5000000,
    "total_expense": 2500000,
    "profit": 2500000
  }
}
```

---

## 18.2 Get Dashboard Activities

| Method | Endpoint                | Auth | Role            | Fungsi                      |
| ------ | ----------------------- | ---- | --------------- | --------------------------- |
| GET    | `/dashboard/activities` | Yes  | admin, operator | Mengambil aktivitas terbaru |

---

## 18.3 Get Dashboard Economy

| Method | Endpoint             | Auth | Role  | Fungsi                      |
| ------ | -------------------- | ---- | ----- | --------------------------- |
| GET    | `/dashboard/economy` | Yes  | admin | Mengambil ringkasan ekonomi |

---

## 18.4 Get Nutrient Cycle Visualization Data

| Method | Endpoint                    | Auth | Role            | Fungsi                                    |
| ------ | --------------------------- | ---- | --------------- | ----------------------------------------- |
| GET    | `/dashboard/nutrient-cycle` | Yes  | admin, operator | Mengambil data visualisasi siklus nutrisi |

---

# 19. Reports API

Reports digunakan untuk membuat dan mengambil laporan dalam bentuk PDF atau Excel.

## 19.1 Get Reports

| Method | Endpoint   | Auth | Role  | Fungsi                   |
| ------ | ---------- | ---- | ----- | ------------------------ |
| GET    | `/reports` | Yes  | admin | Mengambil daftar laporan |

---

## 19.2 Generate PDF Report

| Method | Endpoint                | Auth | Role  | Fungsi              |
| ------ | ----------------------- | ---- | ----- | ------------------- |
| POST   | `/reports/generate/pdf` | Yes  | admin | Membuat laporan PDF |

### Request Body

```json
{
  "report_type": "production",
  "start_date": "2026-06-01",
  "end_date": "2026-06-30"
}
```

---

## 19.3 Generate Excel Report

| Method | Endpoint                  | Auth | Role  | Fungsi                |
| ------ | ------------------------- | ---- | ----- | --------------------- |
| POST   | `/reports/generate/excel` | Yes  | admin | Membuat laporan Excel |

### Request Body

```json
{
  "report_type": "finance",
  "start_date": "2026-06-01",
  "end_date": "2026-06-30"
}
```

---

## 19.4 Get Report Detail

| Method | Endpoint              | Auth | Role  | Fungsi                   |
| ------ | --------------------- | ---- | ----- | ------------------------ |
| GET    | `/reports/{reportId}` | Yes  | admin | Mengambil detail laporan |

---

## 19.5 Delete Report

| Method | Endpoint              | Auth | Role  | Fungsi            |
| ------ | --------------------- | ---- | ----- | ----------------- |
| DELETE | `/reports/{reportId}` | Yes  | admin | Menghapus laporan |

---

# 20. File Upload API

File Upload API digunakan untuk mengunggah file ke Firebase Storage, seperti foto logbook, file SOP, gambar edukasi, dan file laporan.

## 20.1 Upload File

| Method | Endpoint   | Auth | Role            | Fungsi                              |
| ------ | ---------- | ---- | --------------- | ----------------------------------- |
| POST   | `/uploads` | Yes  | admin, operator | Mengunggah file ke Firebase Storage |

### Form Data

| Field  | Tipe   | Keterangan                |
| ------ | ------ | ------------------------- |
| file   | file   | File yang diunggah        |
| folder | string | Folder tujuan penyimpanan |

### Contoh Folder

```txt
logbook
education
reports
profiles
```

### Response

```json
{
  "success": true,
  "message": "File berhasil diunggah",
  "data": {
    "file_url": "https://firebase-storage-url/file.jpg",
    "file_path": "logbook/file.jpg"
  }
}
```

---

# 21. AI Recommendations API

AI Recommendations merupakan fitur tahap lanjutan. Endpoint ini disiapkan untuk prediksi panen, evaluasi produktivitas, dan rekomendasi berbasis data. Fitur ini belum menjadi prioritas implementasi awal.

## 21.1 Get AI Recommendations

| Method | Endpoint              | Auth | Role  | Fungsi                          |
| ------ | --------------------- | ---- | ----- | ------------------------------- |
| GET    | `/ai-recommendations` | Yes  | admin | Mengambil daftar rekomendasi AI |

### Query Parameters

| Parameter           | Tipe   | Keterangan                                                   |
| ------------------- | ------ | ------------------------------------------------------------ |
| module_id           | string | Filter berdasarkan modul                                     |
| cycle_id            | string | Filter berdasarkan siklus                                    |
| recommendation_type | string | prediksi_panen, evaluasi_produktivitas, rekomendasi_tindakan |
| status              | string | generated, reviewed, applied, ignored                        |

---

## 21.2 Generate AI Recommendation

| Method | Endpoint                       | Auth | Role  | Fungsi                                              |
| ------ | ------------------------------ | ---- | ----- | --------------------------------------------------- |
| POST   | `/ai-recommendations/generate` | Yes  | admin | Membuat rekomendasi AI berdasarkan data operasional |

### Request Body

```json
{
  "cycle_id": "cycle_001",
  "module_id": "module_lele",
  "recommendation_type": "prediksi_panen"
}
```

### Response

```json
{
  "success": true,
  "message": "Rekomendasi AI berhasil dibuat",
  "data": {
    "recommendation_id": "recommendation_001",
    "recommendation_type": "prediksi_panen",
    "title": "Prediksi Panen Lele",
    "description": "Sistem memperkirakan panen lele dapat dilakukan dalam 14 hari.",
    "prediction_value": 25,
    "confidence_score": 0.85,
    "suggested_action": "Lakukan pemantauan bobot lele setiap 3 hari.",
    "status": "generated",
    "implementation_stage": "tahap_lanjutan"
  }
}
```

---

## 21.3 Update AI Recommendation Status

| Method | Endpoint                                        | Auth | Role  | Fungsi                         |
| ------ | ----------------------------------------------- | ---- | ----- | ------------------------------ |
| PUT    | `/ai-recommendations/{recommendationId}/status` | Yes  | admin | Mengubah status rekomendasi AI |

### Request Body

```json
{
  "status": "reviewed"
}
```

---

# 22. Error Code

| Status Code | Keterangan                              |
| ----------- | --------------------------------------- |
| 200         | Request berhasil                        |
| 201         | Data berhasil dibuat                    |
| 400         | Request tidak valid                     |
| 401         | User belum login atau token tidak valid |
| 403         | User tidak memiliki akses               |
| 404         | Data tidak ditemukan                    |
| 409         | Data konflik atau duplikat              |
| 500         | Kesalahan server                        |

---

# 23. Prioritas Implementasi API

## Tahap 1: Core System

```txt
/users/me
/farm-modules
/production-cycles
/operational-logs
/inventory/items
/inventory/transactions
/schedules
/dashboard/summary
```

## Tahap 2: Supporting Features

```txt
/notifications
/user-devices
/education-materials
/finance/transactions
/finance/summary
/production-results
/stock-alerts
/circular-flows
```

## Tahap 3: Reports

```txt
/reports
/reports/generate/pdf
/reports/generate/excel
/uploads
```

## Tahap 4: AI Recommendation Tahap Lanjutan

```txt
/ai-recommendations
/ai-recommendations/generate
/ai-recommendations/{recommendationId}/status
```

---

# 24. Catatan Keamanan

1. Semua endpoint selain `/health` wajib menggunakan Firebase ID Token.
2. Role user harus dicek di backend sebelum mengakses endpoint tertentu.
3. File `.env`, service account Firebase, private key, dan token rahasia tidak boleh di-upload ke GitHub.
4. Firebase Admin SDK hanya digunakan di backend, bukan di aplikasi Flutter.
5. Data sensitif seperti password tidak disimpan di Firestore.
6. Password dikelola oleh Firebase Authentication.
7. Endpoint admin hanya dapat diakses oleh user dengan role `admin`.
8. Endpoint AI Recommendation masih tahap lanjutan dan tidak wajib diimplementasikan pada MVP.
