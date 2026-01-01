import 'package:get/get.dart';

class MateriController extends GetxController {
  final materi = <MateriItem>[
    MateriItem(
      title: 'Pengantar Rekayasa Perangkat Lunak',
      pertemuan: 'Pertemuan 1',
      deskripsi: 'Scope, lifecycle, dan workflow tim.',
      tanggal: '12 Jan 2026',
    ),
    MateriItem(
      title: 'Analisis Kebutuhan',
      pertemuan: 'Pertemuan 2',
      deskripsi: 'User story dan acceptance criteria.',
      tanggal: '19 Jan 2026',
    ),
    MateriItem(
      title: 'Desain UI/UX Mobile',
      pertemuan: 'Pertemuan 3',
      deskripsi: 'Wireframe, prototyping, dan heuristic.',
      tanggal: '26 Jan 2026',
    ),
  ].obs;
}

class MateriItem {
  final String title;
  final String pertemuan;
  final String deskripsi;
  final String tanggal;

  MateriItem({
    required this.title,
    required this.pertemuan,
    required this.deskripsi,
    required this.tanggal,
  });
}
