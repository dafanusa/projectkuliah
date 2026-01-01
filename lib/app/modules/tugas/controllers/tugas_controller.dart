import 'package:get/get.dart';

class TugasController extends GetxController {
  final tugas = <TugasItem>[
    TugasItem(
      title: 'Tugas 1 - Analisis Sistem',
      kelas: 'RPL A',
      deadline: '20 Jan 2026',
      status: 'Aktif',
    ),
    TugasItem(
      title: 'Tugas 2 - Desain Antarmuka',
      kelas: 'RPL B',
      deadline: '27 Jan 2026',
      status: 'Aktif',
    ),
    TugasItem(
      title: 'Mini Project Sprint 1',
      kelas: 'Pemrograman Mobile',
      deadline: '2 Feb 2026',
      status: 'Draft',
    ),
  ].obs;
}

class TugasItem {
  final String title;
  final String kelas;
  final String deadline;
  final String status;

  TugasItem({
    required this.title,
    required this.kelas,
    required this.deadline,
    required this.status,
  });
}
