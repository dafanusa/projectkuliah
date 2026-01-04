class ClassItem {
  final String id;
  final String name;
  final String joinCode;

  ClassItem({
    required this.id,
    required this.name,
    this.joinCode = '',
  });

  factory ClassItem.fromMap(Map<String, dynamic> map) {
    return ClassItem(
      id: map['id'] as String,
      name: (map['name'] ?? '') as String,
      joinCode: (map['join_code'] ?? '') as String,
    );
  }
}
