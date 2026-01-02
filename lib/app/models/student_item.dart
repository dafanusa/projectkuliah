class StudentItem {
  final String id;
  final String name;
  final String? email;

  StudentItem({
    required this.id,
    required this.name,
    this.email,
  });

  factory StudentItem.fromMap(Map<String, dynamic> map) {
    return StudentItem(
      id: map['id'] as String,
      name: (map['name'] ?? '') as String,
      email: map['email'] as String?,
    );
  }
}
