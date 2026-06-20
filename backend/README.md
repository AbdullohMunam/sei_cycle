# SeiCycle Backend

Backend API awal untuk aplikasi SeiCycle Kebun Sei, dibangun dengan Express dan
disiapkan agar dapat terhubung ke Firebase Admin SDK.

## Instalasi

```bash
cd backend
npm install
```

Salin `.env.example` menjadi `.env` untuk konfigurasi lokal. Endpoint mock tetap
dapat dijalankan tanpa kredensial Firebase.

## Menjalankan Backend

Mode development:

```bash
npm run dev
```

Mode biasa:

```bash
npm start
```

Server berjalan di `http://localhost:5000` secara default.

## Seed Farm Modules

Simpan `serviceAccountKey.json` hanya secara lokal di folder `backend`. File
tersebut berisi kredensial rahasia dan tidak boleh di-commit atau di-upload ke
GitHub.

Atur Application Default Credentials lalu jalankan seed dari folder `backend`.

PowerShell:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="./serviceAccountKey.json"
npm run seed:farm-modules
```

Command Prompt:

```bat
set GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
npm run seed:farm-modules
```

Script membuat atau memperbarui lima dokumen di collection `farm_modules`.
Penulisan menggunakan `merge: true`, sehingga script aman dijalankan kembali
tanpa menghapus field lain yang sudah tersimpan.

## Endpoint Awal

- `GET /api/v1/health`
- `GET /api/v1/users/me`
- `GET /api/v1/farm-modules`

## Keamanan

Jangan upload `.env`, `serviceAccountKey.json`, atau file kredensial Firebase
lainnya ke GitHub. Gunakan Application Default Credentials melalui
`GOOGLE_APPLICATION_CREDENTIALS` hanya pada lingkungan lokal atau deployment
yang aman.
