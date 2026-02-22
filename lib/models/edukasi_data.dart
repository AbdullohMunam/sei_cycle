import 'package:flutter/material.dart';

class EdukasiPost {
  final String id;
  final String title;
  final String snippet;
  final String category;
  final String tag;
  final bool isVideo;
  final String assetImage;
  final Color tagColor;

  const EdukasiPost({
    required this.id,
    required this.title,
    required this.snippet,
    required this.category,
    required this.tag,
    required this.isVideo,
    required this.assetImage,
    required this.tagColor,
  });
}

class EdukasiData {
  static const List<String> categories = [
    'Semua',
    'Maggot BSF',
    'Cacing Tanah',
    'Ayam Kampung',
    'Lele',
    'Tanaman',
  ];

  static const List<EdukasiPost> posts = [
    EdukasiPost(
      id: '1',
      title: 'Cara Budidaya Maggot BSF dari Telur',
      snippet:
          'Langkah-langkah menetaskan telur BSF hingga menjadi baby maggot siap produksi. Mulai dari persiapan kandang, suhu inkubasi optimal 28–30°C, hingga pemberian pakan awal.',
      category: 'Maggot BSF',
      tag: 'Video Tutorial',
      isVideo: true,
      assetImage: 'lib/assets/edukasi/maggot_bsf.png',
      tagColor: Color(0xFF7B4F00),
    ),
    EdukasiPost(
      id: '2',
      title: 'SOP Pemberian Pakan Ayam Kampung',
      snippet:
          'Panduan takaran pakan campuran maggot hidup dan dedak untuk hasil maksimal. Porsi 50 g/ekor/hari dengan komposisi dedak 60%, talas 30%, dan maggot segar 10%.',
      category: 'Ayam Kampung',
      tag: 'SOP',
      isVideo: false,
      assetImage: 'lib/assets/edukasi/ayam_pakan.png',
      tagColor: Color(0xFF2D6A27),
    ),
    EdukasiPost(
      id: '3',
      title: 'Menjaga Kelembaban Media Cacing ANC',
      snippet:
          'Suhu dan kelembaban sangat mempengaruhi produksi kascing. Berikut cara mengukur kelembaban media dengan metode peras tangan dan mempertahankannya di kisaran 70–80%.',
      category: 'Cacing Tanah',
      tag: 'Panduan',
      isVideo: false,
      assetImage: 'lib/assets/edukasi/cacing_media.png',
      tagColor: Color(0xFF5B6B3A),
    ),
    EdukasiPost(
      id: '4',
      title: 'Manajemen Kualitas Air Kolam Lele Bioflok',
      snippet:
          'Kapan waktu yang tepat untuk mengganti air dan menyiramkannya ke tanaman sebagai pupuk organik cair. Cek pH ideal 7–8, suhu 26–30°C, dan DO minimal 5 mg/L.',
      category: 'Lele',
      tag: 'Video Tutorial',
      isVideo: true,
      assetImage: 'lib/assets/edukasi/lele_bioflok.png',
      tagColor: Color(0xFF0057A8),
    ),
    EdukasiPost(
      id: '5',
      title: 'Tanam Kangkung Organik dengan Pupuk Kascing',
      snippet:
          'Teknik menanam kangkung di bedengan menggunakan kascing sebagai pupuk dasar. Kascing meningkatkan struktur tanah, menyediakan unsur hara N, P, K secara alami.',
      category: 'Tanaman',
      tag: 'Panduan',
      isVideo: false,
      assetImage: 'lib/assets/edukasi/tanaman_kangkung.png',
      tagColor: Color(0xFF2D6A27),
    ),
    EdukasiPost(
      id: '6',
      title: 'Proses Panen Kascing & Cacing Tanah',
      snippet:
          'Cara memisahkan kascing dari cacing dewasa menggunakan metode cahaya. Frekuensi panen kascing setiap 2–3 minggu sekali dengan yield rata-rata 320 kg/bulan.',
      category: 'Cacing Tanah',
      tag: 'Video Tutorial',
      isVideo: true,
      assetImage: 'lib/assets/edukasi/panen_kascing.png',
      tagColor: Color(0xFF7B4F00),
    ),
    EdukasiPost(
      id: '7',
      title: 'Menghitung Feed Conversion Ratio Lele',
      snippet:
          'FCR ideal lele bioflok di Kebun Sei adalah 0,8–1,0. Cara menghitung: total pakan ÷ pertambahan bobot. Dengan maggot segar, FCR bisa ditekan hingga 0,7.',
      category: 'Lele',
      tag: 'SOP',
      isVideo: false,
      assetImage: 'lib/assets/edukasi/lele_fcr.png',
      tagColor: Color(0xFF0057A8),
    ),
    EdukasiPost(
      id: '8',
      title: 'Siklus Nutrisi Tertutup Kebun Sei',
      snippet:
          'Memahami alur lengkap ekosistem sirkular: limbah dapur → maggot → pakan lele → air kolam → pupuk cacing → tanaman → pakan ayam. Zero waste, efisiensi pakan 60%.',
      category: 'Maggot BSF',
      tag: 'Artikel',
      isVideo: false,
      assetImage: 'lib/assets/edukasi/siklus_nutrisi.png',
      tagColor: Color(0xFF2D6A27),
    ),
  ];
}
