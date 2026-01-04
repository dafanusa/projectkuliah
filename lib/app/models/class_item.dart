class ClassItem {
  final String id;
  final String name;
  final String joinCode;
  final String? semesterId;
  final String? semesterName;

  ClassItem({
    required this.id,
    required this.name,
    this.joinCode = '',
    this.semesterId,
    this.semesterName,
  });

  factory ClassItem.fromMap(Map<String, dynamic> map) {
    final semester = map['semesters'];
    return ClassItem(
      id: map['id'] as String,
      name: (map['name'] ?? '') as String,
      joinCode: (map['join_code'] ?? '') as String,
      semesterId: map['semester_id'] as String?,
      semesterName: semester is Map<String, dynamic>
          ? (semester['name'] ?? '') as String
          : null,
    );
  }
}
