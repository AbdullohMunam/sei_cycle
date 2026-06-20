const { admin, db } = require('../config/firebase');

const FIRESTORE_CONNECTION_ERROR =
  'Firestore belum terkoneksi. Pastikan backend/serviceAccountKey.json tersedia dan GOOGLE_APPLICATION_CREDENTIALS sudah benar.';

const farmModules = [
  {
    module_id: 'module_ayam',
    module_name: 'Ayam Kampung',
    module_type: 'ayam',
    description: 'Modul pencatatan ayam kampung',
    is_active: true,
  },
  {
    module_id: 'module_maggot',
    module_name: 'Maggot BSF',
    module_type: 'maggot',
    description: 'Modul pencatatan maggot BSF',
    is_active: true,
  },
  {
    module_id: 'module_cacing',
    module_name: 'Cacing Tanah',
    module_type: 'cacing',
    description: 'Modul pencatatan cacing tanah',
    is_active: true,
  },
  {
    module_id: 'module_lele',
    module_name: 'Lele',
    module_type: 'lele',
    description: 'Modul pencatatan budidaya lele',
    is_active: true,
  },
  {
    module_id: 'module_tanaman',
    module_name: 'Tanaman',
    module_type: 'tanaman',
    description: 'Modul pencatatan tanaman',
    is_active: true,
  },
];

async function seedFarmModules() {
  if (!db) {
    throw new Error(FIRESTORE_CONNECTION_ERROR);
  }

  await Promise.all(
    farmModules.map(({ module_id, ...moduleData }) =>
      db
        .collection('farm_modules')
        .doc(module_id)
        .set(
          {
            module_id,
            ...moduleData,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        ),
    ),
  );

  console.log(`Berhasil melakukan seed ${farmModules.length} farm modules.`);
}

seedFarmModules().catch((error) => {
  console.error(error.message || FIRESTORE_CONNECTION_ERROR);
  process.exitCode = 1;
});