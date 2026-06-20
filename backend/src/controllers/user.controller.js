const getCurrentUser = (req, res) => {
  const user = {
    user_id: 'admin_kebun_sei',
    name: 'Admin Kebun Sei',
    email: 'kebunsei@gmail.com',
    role: 'admin',
    photo_url: '',
    is_active: true,
  };

  res.json({
    success: true,
    message: 'Profil user berhasil diambil',
    data: user,
  });
};

module.exports = { getCurrentUser };
