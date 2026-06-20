const getFarmModules = (req, res) => {
  const farmModules = [
    {
      module_id: 'module_ayam',
      name: 'Ayam Kampung',
      type: 'ayam',
      is_active: true,
    },
    {
      module_id: 'module_maggot',
      name: 'Maggot BSF',
      type: 'maggot',
      is_active: true,
    },
    {
      module_id: 'module_cacing',
      name: 'Cacing Tanah',
      type: 'cacing',
      is_active: true,
    },
    {
      module_id: 'module_lele',
      name: 'Lele',
      type: 'lele',
      is_active: true,
    },
    {
      module_id: 'module_tanaman',
      name: 'Tanaman',
      type: 'tanaman',
      is_active: true,
    },
  ];

  res.json({
    success: true,
    message: 'Data modul berhasil diambil',
    data: farmModules,
  });
};

module.exports = { getFarmModules };
