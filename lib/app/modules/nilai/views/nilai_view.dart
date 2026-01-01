import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/nilai_controller.dart';

class NilaiView extends GetView<NilaiController> {
  const NilaiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.nilai.toList();
      final average = items.isEmpty
          ? 0
          : (items.fold<int>(0, (sum, item) => sum + item.nilai) /
                  items.length)
              .round();
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _PageHeader(
            title: 'Nilai Mahasiswa',
            subtitle: 'Pantau performa kelas secara cepat.',
            stats: [
              _HeaderStat(label: 'Rata-rata', value: average.toString()),
              _HeaderStat(label: 'Jumlah', value: items.length.toString()),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFFE8ECF5),
                ),
                columns: const [
                  DataColumn(label: Text('Mahasiswa')),
                  DataColumn(label: Text('Kelas')),
                  DataColumn(label: Text('Nilai')),
                ],
                rows: items
                    .map(
                      (item) => DataRow(
                        cells: [
                          DataCell(Text(item.nama)),
                          DataCell(Text(item.kelas)),
                          DataCell(Text(item.nilai.toString())),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_HeaderStat> stats;

  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1E3B), Color(0xFF2C3E66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFFD6E0F5)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stats,
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
