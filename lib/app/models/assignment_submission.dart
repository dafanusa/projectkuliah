class AssignmentSubmission {
  final String id;
  final String assignmentId;
  final String? assignmentTitle;
  final String? classId;
  final String userId;
  final String? studentName;
  final String? studentEmail;
  final String? studentNim;
  final String? content;
  final String? filePath;
  final DateTime submittedAt;
  final String status;

  AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    this.assignmentTitle,
    this.classId,
    required this.userId,
    required this.submittedAt,
    required this.status,
    this.studentName,
    this.studentEmail,
    this.studentNim,
    this.content,
    this.filePath,
  });

  factory AssignmentSubmission.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'];
    final assignment = map['assignments'];
    return AssignmentSubmission(
      id: map['id'] as String,
      assignmentId: map['assignment_id'] as String,
      assignmentTitle: assignment is Map<String, dynamic>
          ? (assignment['title'] ?? '') as String
          : null,
      classId: assignment is Map<String, dynamic>
          ? assignment['class_id'] as String?
          : null,
      userId: map['user_id'] as String,
      content: map['content'] as String?,
      filePath: map['file_path'] as String?,
      submittedAt: DateTime.parse(map['submitted_at'] as String),
      status: (map['status'] ?? 'tepat_waktu') as String,
      studentName: profile is Map<String, dynamic>
          ? (profile['name'] ?? '') as String
          : null,
      studentEmail: profile is Map<String, dynamic>
          ? (profile['email'] ?? '') as String
          : null,
      studentNim: profile is Map<String, dynamic>
          ? (profile['nim'] ?? '') as String
          : null,
    );
  }
}
