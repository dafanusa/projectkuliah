class ClassItem {
  final String id;
  final String name;

  ClassItem({required this.id, required this.name});

  factory ClassItem.fromMap(Map<String, dynamic> map) {
    return ClassItem(
      id: map['id'] as String,
      name: (map['name'] ?? '') as String,
    );
  }
}
