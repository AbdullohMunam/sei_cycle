# SeiCycle Backend

REST API Express untuk aplikasi Flutter SeiCycle. Data operasional disimpan di
Cloud Firestore dan response API menggunakan format JSON yang konsisten.

## Persyaratan

- Node.js 18 atau lebih baru
- Project Firebase dengan Firestore dan Firebase Authentication
- Firebase Admin service account untuk backend

## Instalasi

```bash
cd backend
npm install
```

## Konfigurasi Firebase

Salin `.env.example` menjadi `.env`:

```env
PORT=5000
FIREBASE_PROJECT_ID=seicycle-kebun-sei
FIREBASE_STORAGE_BUCKET=seicycle-kebun-sei.appspot.com
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
```

Unduh Firebase Admin service account dari Firebase Console, lalu simpan hanya
secara lokal sebagai:

```text
backend/serviceAccountKey.json
```

Konfigurasi Android Flutter menggunakan file yang berbeda:

```text
android/app/google-services.json
```

Jangan menukar kedua file tersebut. `.env`, `serviceAccountKey.json`, dan
credential Firebase Admin lain sudah diabaikan oleh Git.

## Menjalankan Backend

Seed lima farm module terlebih dahulu:

```bash
npm run seed:farm-modules
```

Jalankan development server:

```bash
npm run dev
```

Server tersedia di `http://localhost:5000`.

## Format Response

Response sukses:

```json
{
  "success": true,
  "message": "Data berhasil diambil",
  "data": []
}
```

Response error:

```json
{
  "success": false,
  "message": "Firestore belum terkoneksi",
  "data": null
}
```

Timestamp Firestore dikirim sebagai string ISO-8601 agar mudah diubah menjadi
`DateTime` di Flutter.

## Endpoint

| Method | Endpoint | Keterangan |
| --- | --- | --- |
| GET | `/api/v1/health` | Health check API |
| GET | `/api/v1/users/me` | Profil user dari Firebase Auth dan Firestore |
| GET | `/api/v1/farm-modules` | Daftar farm module |
| GET | `/api/v1/farm-modules/:id` | Detail farm module |
| GET | `/api/v1/dashboard/summary` | Ringkasan dashboard |
| GET | `/api/v1/logbooks` | Daftar logbook |
| POST | `/api/v1/logbooks` | Tambah logbook |
| GET | `/api/v1/inventory` | Daftar inventory |
| POST | `/api/v1/inventory` | Tambah item inventory |

`GET /api/v1/users/me` membutuhkan header:

```http
Authorization: Bearer <firebase-id-token>
```

### Farm Module

```bash
curl http://localhost:5000/api/v1/farm-modules
curl http://localhost:5000/api/v1/farm-modules/module_ayam
```

Field response:

```json
{
  "module_id": "module_ayam",
  "module_name": "Ayam Kampung",
  "module_type": "ayam",
  "description": "Modul pencatatan ayam kampung",
  "is_active": true,
  "created_at": "2026-06-20T08:00:00.000Z",
  "updated_at": "2026-06-20T08:00:00.000Z"
}
```

### Dashboard

```bash
curl http://localhost:5000/api/v1/dashboard/summary
```

```json
{
  "success": true,
  "message": "Ringkasan dashboard berhasil diambil",
  "data": {
    "total_modules": 5,
    "active_modules": 5,
    "total_logbooks": 0,
    "total_inventory_items": 0
  }
}
```

### Logbook

Field wajib: `module_id`, `activity_type`, `description`, dan `created_by`.

```bash
curl -X POST http://localhost:5000/api/v1/logbooks \
  -H "Content-Type: application/json" \
  -d '{"module_id":"module_ayam","activity_type":"pemberian_pakan","description":"Pakan pagi","quantity":5,"unit":"kg","notes":"","created_by":"firebase_uid"}'
```

### Inventory

`is_low_stock` dihitung otomatis menjadi `true` jika
`stock <= minimum_stock`.

```bash
curl -X POST http://localhost:5000/api/v1/inventory \
  -H "Content-Type: application/json" \
  -d '{"item_name":"Pakan Ayam","category":"pakan","stock":20,"unit":"kg","minimum_stock":5}'
```

## Testing

Browser dapat digunakan untuk seluruh endpoint `GET`. Untuk `POST`, gunakan
Postman atau `curl`.

```bash
curl http://localhost:5000/api/v1/health
curl http://localhost:5000/api/v1/farm-modules
curl http://localhost:5000/api/v1/farm-modules/module_ayam
curl http://localhost:5000/api/v1/dashboard/summary
curl http://localhost:5000/api/v1/logbooks
curl http://localhost:5000/api/v1/inventory
```

## URL untuk Flutter

- Android Emulator: `http://10.0.2.2:5000/api/v1`
- Flutter Web atau desktop lokal: `http://localhost:5000/api/v1`
- Perangkat Android fisik: `http://<IP-LAN-komputer>:5000/api/v1`

Untuk perangkat fisik, komputer dan ponsel harus berada pada jaringan yang sama
dan port `5000` harus diizinkan oleh firewall.

## Keamanan

Jangan commit atau upload:

- `.env`
- `serviceAccountKey.json`
- file `*-firebase-adminsdk-*.json`
- `node_modules`

Simpan credential Admin hanya pada backend atau secret manager deployment.
