import 'package:get/get.dart';

class NilaiController extends GetxController {
  final nilai = <NilaiItem>[
    NilaiItem(nama: 'Alya Putri', nilai: 88, kelas: 'RPL A'),
    NilaiItem(nama: 'Bima Pratama', nilai: 92, kelas: 'RPL A'),
    NilaiItem(nama: 'Chandra Wijaya', nilai: 79, kelas: 'RPL B'),
    NilaiItem(nama: 'Dina Larasati', nilai: 85, kelas: 'RPL B'),
  ].obs;
}

class NilaiItem {
  final String nama;
  final int nilai;
  final String kelas;

  NilaiItem({
    required this.nama,
    required this.nilai,
    required this.kelas,
  });
}
