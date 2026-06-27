# Notification Free Mode SeiCycle

Sistem notifikasi SeiCycle dibuat untuk berjalan di Firebase free mode tanpa Cloud Functions, tanpa Firebase Storage, dan tanpa backend Express.

## Komponen

1. In-app notification
   - Data disimpan di collection `notifications`.
   - User membaca inbox dari aplikasi Flutter.
   - Notifikasi dibuat oleh client saat user membuka fitur yang relevan, misalnya dashboard, inventory, atau schedule.

2. Local reminder
   - Menggunakan `flutter_local_notifications` dan `timezone`.
   - Reminder jadwal dibuat lokal di device setelah user membuat atau mengubah schedule.
   - Reminder dibatalkan saat schedule selesai, dilewati, atau dihapus.
   - Android memakai mode inexact agar tidak membutuhkan permission exact alarm.

3. FCM token
   - Aplikasi meminta permission Firebase Messaging dan menyimpan `fcmToken` di dokumen `users/{uid}` jika tersedia.
   - Tidak ada push otomatis dari server karena tidak ada Cloud Functions atau backend berbayar.
   - Push otomatis FCM menjadi tahap lanjutan jika project upgrade ke Blaze dan menambahkan worker/server tepercaya.

## Schema `notifications/{id}`

```json
{
  "id": "uuid-or-deterministic-id",
  "title": "Stok Pakan rendah",
  "body": "Stok tersisa 5 kg, batas minimum 10 kg.",
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

Tipe yang dipakai saat ini:

- `low_stock`: alert stok rendah saat inventory/dashboard mendeteksi item low stock.
- `schedule_overdue`: alert jadwal pending yang sudah lewat.
- `production_reminder`: pengingat produksi/kegiatan dari schedule.
- `system`: alert sistem sederhana untuk admin/client.

## Guard Anti Spam Write

Low stock notification memakai ID deterministik:

```text
low_stock_{userId}_{inventoryId}
```

Sebelum membuat alert, client membaca dokumen tersebut. Jika dokumen masih ada dan belum dibaca, client tidak menulis ulang. Jika user sudah menandai dibaca dan stok masih rendah pada pembukaan berikutnya, client boleh membuat ulang alert dengan ID yang sama.

Overdue dan production reminder juga memakai ID deterministik per user + schedule agar tidak membuat dokumen duplikat untuk jadwal yang sama.

## Query dan Akses

Notification inbox mengambil dokumen yang cocok dengan salah satu kondisi:

- `userId == currentUser.uid`
- `targetRole == currentUser.role`
- `targetRole == "all"`

User dapat:

- membaca notifikasi personal/role/global yang relevan,
- membuat notifikasi client-side yang relevan untuk dirinya/role-nya,
- menandai satu notifikasi sebagai dibaca,
- menandai batch notifikasi sebagai dibaca.

Admin tetap dapat menghapus notifikasi bila perlu lewat console/admin flow.

## Batasan Free Mode

- Reminder lokal hanya aktif di device yang membuat jadwal/menyalakan permission.
- Jika user uninstall app, clear data, atau pindah device, local reminder harus dibuat ulang dari aplikasi.
- FCM token hanya disimpan sebagai persiapan. Tidak ada pengiriman push otomatis tanpa server tepercaya.
- Hindari membuat alert dari loop real-time yang menulis setiap snapshot; gunakan helper guard seperti `NotificationService.createLowStockAlert`.
