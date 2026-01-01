import 'package:get/get.dart';

class HasilController extends GetxController {
  final hasil = <HasilItem>[
    HasilItem(
      title: 'Tugas 1 - Analisis Sistem',
      terkumpul: 28,
      belum: 4,
      dinilai: 10,
    ),
    HasilItem(
      title: 'Tugas 2 - Desain Antarmuka',
      terkumpul: 30,
      belum: 2,
      dinilai: 6,
    ),
  ].obs;
}

class HasilItem {
  final String title;
  final int terkumpul;
  final int belum;
  final int dinilai;

  HasilItem({
    required this.title,
    required this.terkumpul,
    required this.belum,
    required this.dinilai,
  });
}
