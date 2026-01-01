import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final summary = <SummaryItem>[
    SummaryItem(
      title: 'Materi Aktif',
      value: '8',
      icon: Icons.menu_book_rounded,
    ),
    SummaryItem(
      title: 'Tugas Aktif',
      value: '3',
      icon: Icons.assignment_rounded,
    ),
    SummaryItem(
      title: 'Perlu Penilaian',
      value: '12',
      icon: Icons.fact_check_rounded,
    ),
    SummaryItem(
      title: 'Mahasiswa',
      value: '32',
      icon: Icons.group_rounded,
    ),
  ].obs;

  final activities = <ActivityItem>[
    ActivityItem(
      title: 'Materi Pertemuan 5 dipublikasikan',
      subtitle: 'Algoritma & Struktur Data',
      time: 'Hari ini',
    ),
    ActivityItem(
      title: '12 tugas menunggu penilaian',
      subtitle: 'Pemrograman Mobile',
      time: '2 hari lalu',
    ),
    ActivityItem(
      title: 'Rekap nilai UTS siap dibagikan',
      subtitle: 'Basis Data',
      time: '3 hari lalu',
    ),
  ].obs;
}

class SummaryItem {
  final String title;
  final String value;
  final IconData icon;

  SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
  });
}

class ActivityItem {
  final String title;
  final String subtitle;
  final String time;

  ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
  });
}
