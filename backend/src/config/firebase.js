const fs = require('fs');
const path = require('path');

const admin = require('firebase-admin');
const dotenv = require('dotenv');

let db = null;

dotenv.config({
  path: path.resolve(__dirname, '../../.env'),
});

const serviceAccountPath = path.resolve(
  process.cwd(),
  process.env.GOOGLE_APPLICATION_CREDENTIALS || 'serviceAccountKey.json',
);

if (!fs.existsSync(serviceAccountPath)) {
  console.warn(
    `Firebase Admin belum terhubung: file service account tidak ditemukan di ${serviceAccountPath}. Endpoint mock tetap dapat digunakan.`,
  );
} else {
  try {
    const serviceAccount = JSON.parse(
      fs.readFileSync(serviceAccountPath, 'utf8'),
    );

    const requiredFields = ['project_id', 'client_email', 'private_key'];
    const isServiceAccount = requiredFields.every(
      (field) => typeof serviceAccount[field] === 'string',
    );

    if (!isServiceAccount) {
      throw new Error(
        'File kredensial bukan Firebase Admin service account JSON. Unduh key dari Firebase Console > Project settings > Service accounts.',
      );
    }

    if (admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId:
          process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id,
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
      });
    }

    db = admin.firestore();
  } catch (error) {
    console.warn(
      `Firebase Admin gagal diinisialisasi. Endpoint mock tetap dapat digunakan: ${error.message}`,
    );
    db = null;
  }
}

module.exports = { admin, db };