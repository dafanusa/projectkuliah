class SemesterItem {
  final String id;
  final String name;

  SemesterItem({
    required this.id,
    required this.name,
  });

  factory SemesterItem.fromMap(Map<String, dynamic> map) {
    return SemesterItem(
      id: map['id'] as String,
      name: (map['name'] ?? '') as String,
    );
  }
}
