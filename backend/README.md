# SeiCycle Backend

REST API Express untuk aplikasi SeiCycle. Data operasional disimpan di Cloud
Firestore dan seluruh response menggunakan struktur JSON yang konsisten.

## Persyaratan

- Node.js 18 atau lebih baru
- Project Firebase dengan Firestore dan Firebase Authentication
- Firebase Admin service account

## Instalasi dan environment

```bash
cd backend
npm install
```

Salin `.env.example` menjadi `.env`, lalu sesuaikan nilainya:

```env
PORT=5000
FIREBASE_PROJECT_ID=seicycle-kebun-sei
FIREBASE_STORAGE_BUCKET=seicycle-kebun-sei.appspot.com
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
```

`GOOGLE_APPLICATION_CREDENTIALS` dibaca relatif terhadap folder tempat perintah
Node dijalankan. Jalankan backend dari folder `backend` bila memakai nilai
contoh di atas.

### Setup serviceAccountKey.json

1. Buka Firebase Console.
2. Pilih **Project settings > Service accounts**.
3. Klik **Generate new private key**.
4. Simpan file hanya secara lokal sebagai
   `backend/serviceAccountKey.json`.

File tersebut berbeda dari `android/app/google-services.json`. Jangan commit
`.env`, service account, private key, atau credential Firebase Admin lainnya.

## Menjalankan backend

Seed data farm module:

```bash
npm run seed:farm-modules
```

Development server:

```bash
npm run dev
```

Production-style local server:

```bash
npm start
```

Default server URL: `http://localhost:5000`.

## Format response

Sukses:

```json
{
  "success": true,
  "message": "Data berhasil diambil",
  "data": []
}
```

Error validasi:

```json
{
  "success": false,
  "message": "Field title wajib diisi",
  "data": null
}
```

Jika Firebase Admin belum siap:

```json
{
  "success": false,
  "message": "Firestore belum terkoneksi",
  "data": []
}
```

Timestamp Firestore dikirim sebagai ISO-8601 agar mudah diparse menjadi
`DateTime` di Flutter.

## Endpoint

### Sistem dan user

| Method | Endpoint | Keterangan |
| --- | --- | --- |
| GET | `/api/v1/health` | Health check |
| GET | `/api/v1/users/me` | Profil user terautentikasi |
| GET | `/api/v1/farm-modules` | Daftar modul |
| GET | `/api/v1/farm-modules/:id` | Detail modul |
| GET | `/api/v1/dashboard/summary` | Ringkasan dashboard terintegrasi |

`GET /api/v1/users/me` membutuhkan header
`Authorization: Bearer <firebase-id-token>`.

### Logbook

| Method | Endpoint | Keterangan |
| --- | --- | --- |
| GET | `/api/v1/logbooks` | Daftar logbook |
| GET | `/api/v1/logbooks?module_id=module_ayam` | Filter modul |
| GET | `/api/v1/logbooks?date=2026-06-20` | Filter tanggal |
| GET | `/api/v1/logbooks?activity_type=pemberian_pakan` | Filter aktivitas |
| GET | `/api/v1/logbooks/:id` | Detail logbook |
| POST | `/api/v1/logbooks` | Tambah logbook |
| PATCH | `/api/v1/logbooks/:id` | Ubah field yang dikirim |
| DELETE | `/api/v1/logbooks/:id` | Hapus logbook |

Field wajib POST: `module_id`, `activity_type`, `description`, `created_by`.
Filter `date` menggunakan tanggal `created_at` atau field tanggal dari data
logbook lama. Field PATCH yang diizinkan: `module_id`, `activity_type`,
`description`, `quantity`, `unit`, dan `notes`.

```bash
curl -X POST http://localhost:5000/api/v1/logbooks \
  -H "Content-Type: application/json" \
  -d '{"module_id":"module_ayam","activity_type":"pemberian_pakan","description":"Pakan pagi","quantity":5,"unit":"kg","created_by":"firebase_uid"}'

curl http://localhost:5000/api/v1/logbooks/LOGBOOK_ID
curl "http://localhost:5000/api/v1/logbooks?module_id=module_ayam"
curl "http://localhost:5000/api/v1/logbooks?date=2026-06-20"

curl -X PATCH http://localhost:5000/api/v1/logbooks/LOGBOOK_ID \
  -H "Content-Type: application/json" \
  -d '{"description":"Pakan pagi diperbarui","quantity":6}'

curl -X DELETE http://localhost:5000/api/v1/logbooks/LOGBOOK_ID
```

### Inventory

| Method | Endpoint | Keterangan |
| --- | --- | --- |
| GET | `/api/v1/inventory` | Daftar item |
| GET | `/api/v1/inventory/:id` | Detail item |
| POST | `/api/v1/inventory` | Tambah item |
| PATCH | `/api/v1/inventory/:id` | Ubah item |
| DELETE | `/api/v1/inventory/:id` | Hapus item |

Field wajib POST: `item_name`, `category`, `stock`, `unit`, `minimum_stock`.
`is_low_stock` selalu dihitung ulang dari `stock <= minimum_stock`.
Field PATCH yang diizinkan: `item_name`, `category`, `stock`, `unit`, dan
`minimum_stock`.

```bash
curl -X POST http://localhost:5000/api/v1/inventory \
  -H "Content-Type: application/json" \
  -d '{"item_name":"Pakan Ayam","category":"pakan","stock":20,"unit":"kg","minimum_stock":5}'

curl http://localhost:5000/api/v1/inventory/ITEM_ID

curl -X PATCH http://localhost:5000/api/v1/inventory/ITEM_ID \
  -H "Content-Type: application/json" \
  -d '{"stock":4,"minimum_stock":5}'

curl -X DELETE http://localhost:5000/api/v1/inventory/ITEM_ID
```

### Kalender operasional

| Method | Endpoint |
| --- | --- |
| GET | `/api/v1/calendar` |
| GET | `/api/v1/calendar/:id` |
| POST | `/api/v1/calendar` |
| PATCH | `/api/v1/calendar/:id` |
| DELETE | `/api/v1/calendar/:id` |

GET mendukung query `date`, `module_id`, dan `status`. Field wajib POST:
`title`, `module_id`, `activity_type`, `schedule_date`, `created_by`.

```bash
curl -X POST http://localhost:5000/api/v1/calendar \
  -H "Content-Type: application/json" \
  -d '{"title":"Pakan ayam pagi","module_id":"module_ayam","activity_type":"pemberian_pakan","schedule_date":"2026-06-20","schedule_time":"08:00","created_by":"firebase_uid"}'
```

### Keuangan

| Method | Endpoint |
| --- | --- |
| GET | `/api/v1/finance/transactions` |
| GET | `/api/v1/finance/transactions/:id` |
| POST | `/api/v1/finance/transactions` |
| PATCH | `/api/v1/finance/transactions/:id` |
| DELETE | `/api/v1/finance/transactions/:id` |
| GET | `/api/v1/finance/summary` |

GET transaksi mendukung query `type`, `category`, `module_id`, `start_date`,
dan `end_date`. Summary juga menerima `start_date` dan `end_date`.
`type` hanya boleh `income` atau `expense`.

```bash
curl -X POST http://localhost:5000/api/v1/finance/transactions \
  -H "Content-Type: application/json" \
  -d '{"type":"expense","category":"pakan","amount":150000,"description":"Pembelian pakan","transaction_date":"2026-06-20","module_id":"module_ayam","created_by":"firebase_uid"}'
```

### Edukasi/SOP

| Method | Endpoint |
| --- | --- |
| GET | `/api/v1/education` |
| GET | `/api/v1/education/:id` |
| POST | `/api/v1/education` |
| PATCH | `/api/v1/education/:id` |
| DELETE | `/api/v1/education/:id` |

GET mendukung query `type`, `category`, `module_id`, dan `is_published`.
Field wajib POST: `title`, `type`, `category`, `description`. `type` hanya
boleh `article`, `video`, atau `sop`.

```bash
curl -X POST http://localhost:5000/api/v1/education \
  -H "Content-Type: application/json" \
  -d '{"title":"SOP Pakan Ayam","type":"sop","category":"ayam","description":"Langkah pemberian pakan","module_id":"module_ayam","is_published":true}'
```

### Reports

| Method | Endpoint | Keterangan |
| --- | --- | --- |
| GET | `/api/v1/reports/summary` | Summary operasional dan keuangan |

### Contoh dashboard/report summary

```json
{
  "success": true,
  "message": "Ringkasan dashboard berhasil diambil",
  "data": {
    "total_modules": 5,
    "total_logbooks": 12,
    "total_inventory_items": 8,
    "low_stock_items": 2,
    "total_schedules": 4,
    "total_income": 5000000,
    "total_expense": 2500000,
    "profit": 2500000,
    "active_modules": 5
  }
}
```

## Testing dengan browser, Postman, atau curl

Endpoint GET dapat dibuka langsung di browser. Untuk POST, PATCH, dan DELETE,
gunakan Postman atau curl dengan header `Content-Type: application/json`.

Smoke test GET:

```bash
curl http://localhost:5000/api/v1/health
curl http://localhost:5000/api/v1/farm-modules
curl http://localhost:5000/api/v1/logbooks
curl "http://localhost:5000/api/v1/logbooks?module_id=module_ayam&date=2026-06-20"
curl http://localhost:5000/api/v1/inventory
curl http://localhost:5000/api/v1/calendar
curl http://localhost:5000/api/v1/finance/summary
curl http://localhost:5000/api/v1/education
curl http://localhost:5000/api/v1/reports/summary
curl http://localhost:5000/api/v1/dashboard/summary
```

Contoh PATCH dan DELETE:

```bash
curl -X PATCH http://localhost:5000/api/v1/logbooks/LOGBOOK_ID \
  -H "Content-Type: application/json" \
  -d '{"notes":"Catatan diperbarui"}'

curl -X DELETE http://localhost:5000/api/v1/logbooks/LOGBOOK_ID
```

## Base URL untuk Flutter

- Android emulator: `http://10.0.2.2:5000/api/v1`
- Browser/desktop lokal: `http://localhost:5000/api/v1`
- HP fisik: `http://<IP-LAN-laptop>:5000/api/v1`

Untuk HP fisik, laptop dan HP harus berada pada jaringan yang sama. Pastikan
port `5000` diizinkan firewall dan server mendengarkan koneksi jaringan lokal.

## Keamanan Git

Root `.gitignore` dan `backend/.gitignore` mengabaikan:

- `.env`
- `serviceAccountKey.json`
- `*-firebase-adminsdk-*.json`
- `google-services.json` di folder backend
- `node_modules`
- folder `credentials` dan `secrets`

Sebelum commit, periksa dengan:

```bash
git status
git ls-files | grep -E '(\.env|serviceAccountKey|firebase-adminsdk|node_modules)'
```
