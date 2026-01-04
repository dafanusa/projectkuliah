import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assignment_item.dart';
import '../models/assignment_submission.dart';
import '../models/class_item.dart';
import '../models/exam_item.dart';
import '../models/exam_grade_item.dart';
import '../models/exam_submission_item.dart';
import '../models/exam_question.dart';
import '../models/exam_choice.dart';
import '../models/exam_attempt.dart';
import '../models/exam_answer.dart';
import '../models/grade_item.dart';
import '../models/lecturer_work_item.dart';
import '../models/material_item.dart';
import '../models/student_item.dart';

class DataService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ClassItem>> fetchClasses() async {
    final data =
        await _client.from('classes').select('id,name,join_code').order('name');
    return (data as List<dynamic>)
        .map((item) => ClassItem.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addClass(String name, {String? joinCode}) async {
    await _client.from('classes').insert({
      'name': name,
      'join_code': joinCode?.trim().isEmpty == true ? null : joinCode?.trim(),
    });
  }

  Future<void> updateClass(String id, String name, {String? joinCode}) async {
    await _client.from('classes').update({
      'name': name,
      'join_code': joinCode?.trim().isEmpty == true ? null : joinCode?.trim(),
    }).eq('id', id);
  }

  Future<void> deleteClass(String id) async {
    await _client.from('classes').delete().eq('id', id);
  }

  Future<List<String>> fetchEnrolledClassIds({
    required String userId,
  }) async {
    final data = await _client
        .from('class_enrollments')
        .select('class_id')
        .eq('user_id', userId);
    return (data as List<dynamic>)
        .map((item) => (item as Map<String, dynamic>)['class_id'] as String)
        .toList();
  }

  Future<void> joinClassWithCode({
    required String classId,
    required String userId,
    required String code,
  }) async {
    final normalizedCode = code.trim();
    if (normalizedCode.isEmpty) {
      throw Exception('Kode kelas wajib diisi.');
    }
    final result = await _client
        .from('classes')
        .select('id')
        .eq('id', classId)
        .eq('join_code', normalizedCode)
        .maybeSingle();
    if (result == null) {
      throw Exception('Kode kelas tidak sesuai.');
    }
    await _client.from('class_enrollments').upsert(
      {
        'class_id': classId,
        'user_id': userId,
      },
      onConflict: 'class_id,user_id',
    );
  }

  Future<List<MaterialItem>> fetchMaterials() async {
    final data = await _client
        .from('materials')
        .select('id,title,description,meeting,date,file_path,class_id,classes(name)')
        .order('created_at', ascending: false);
    return (data as List<dynamic>)
        .map((item) => MaterialItem.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<LecturerWorkItem>> fetchLecturerWorks() async {
    final data = await _client
        .from('lecturer_works')
        .select('id,title,description,category,date,file_path')
        .order('date', ascending: false);
    return (data as List<dynamic>)
        .map((item) => LecturerWorkItem.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertMaterial(Map<String, dynamic> payload) async {
    await _client.from('materials').insert(payload);
  }

  Future<void> insertLecturerWork(Map<String, dynamic> payload) async {
    await _client.from('lecturer_works').insert(payload);
  }

  Future<void> updateMaterial(String id, Map<String, dynamic> payload) async {
    await _client.from('materials').update(payload).eq('id', id);
  }

  Future<void> updateLecturerWork(String id, Map<String, dynamic> payload) async {
    await _client.from('lecturer_works').update(payload).eq('id', id);
  }

  Future<void> deleteMaterial(String id) async {
    await _client.from('materials').delete().eq('id', id);
  }

  Future<void> deleteLecturerWork(String id) async {
    await _client.from('lecturer_works').delete().eq('id', id);
  }

  Future<List<AssignmentItem>> fetchAssignments({bool includeExpired = true}) async {
    final data = await _client
        .from('assignments')
        .select('id,title,instructions,deadline,file_path,class_id,classes(name)')
        .order('deadline', ascending: true);
    return (data as List<dynamic>)
        .map((item) => AssignmentItem.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ExamItem>> fetchExams() async {
    final data = await _client
        .from('exams')
        .select(
            'id,title,description,start_at,end_at,duration_minutes,max_attempts,file_path,class_id,classes(name)')
        .order('start_at', ascending: true);
    return (data as List<dynamic>)
        .map((item) => ExamItem.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertAssignment(Map<String, dynamic> payload) async {
    await _client.from('assignments').insert(payload);
  }

  Future<void> insertExam(Map<String, dynamic> payload) async {
    await _client.from('exams').insert(payload);
  }

  Future<void> updateAssignment(String id, Map<String, dynamic> payload) async {
    await _client.from('assignments').update(payload).eq('id', id);
  }

  Future<void> updateExam(String id, Map<String, dynamic> payload) async {
    await _client.from('exams').update(payload).eq('id', id);
  }

  Future<void> deleteAssignment(String id) async {
    await _client.from('assignments').delete().eq('id', id);
  }

  Future<void> deleteExam(String id) async {
    await _client.from('exams').delete().eq('id', id);
  }

  Future<List<ExamQuestion>> fetchExamQuestions(String examId) async {
    final data = await _client
        .from('exam_questions')
        .select('id,exam_id,type,prompt,points,order_index')
        .eq('exam_id', examId)
        .order('order_index', ascending: true);
    return (data as List<dynamic>)
        .map((item) => ExamQuestion.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ExamChoice>> fetchExamChoices(String questionId) async {
    final data = await _client
        .from('exam_choices')
        .select('id,question_id,text,is_correct')
        .eq('question_id', questionId)
        .order('created_at', ascending: true);
    return (data as List<dynamic>)
        .map((item) => ExamChoice.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<ExamQuestion> insertExamQuestion(Map<String, dynamic> payload) async {
    final data = await _client
        .from('exam_questions')
        .insert(payload)
        .select('id,exam_id,type,prompt,points,order_index')
        .single();
    return ExamQuestion.fromMap(data as Map<String, dynamic>);
  }

  Future<void> updateExamQuestion(String id, Map<String, dynamic> payload) async {
    await _client.from('exam_questions').update(payload).eq('id', id);
  }

  Future<void> deleteExamQuestion(String id) async {
    await _client.from('exam_questions').delete().eq('id', id);
  }

  Future<void> insertExamChoice(Map<String, dynamic> payload) async {
    await _client.from('exam_choices').insert(payload);
  }

  Future<void> deleteExamChoicesForQuestion(String questionId) async {
    await _client.from('exam_choices').delete().eq('question_id', questionId);
  }

  Future<List<ExamAttempt>> fetchExamAttempts({
    required String examId,
    required String userId,
  }) async {
    final data = await _client
        .from('exam_attempts')
        .select('id,exam_id,user_id,started_at,submitted_at,attempt_number,status,mcq_score')
        .eq('exam_id', examId)
        .eq('user_id', userId)
        .order('attempt_number', ascending: true);
    return (data as List<dynamic>)
        .map((item) => ExamAttempt.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ExamAttempt>> fetchExamAttemptsForExam(String examId) async {
    final data = await _client
        .from('exam_attempts')
        .select('id,exam_id,user_id,started_at,submitted_at,attempt_number,status,mcq_score')
        .eq('exam_id', examId)
        .order('attempt_number', ascending: true);
    return (data as List<dynamic>)
        .map((item) => ExamAttempt.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<ExamAttempt> insertExamAttempt(Map<String, dynamic> payload) async {
    final data = await _client
        .from('exam_attempts')
        .insert(payload)
        .select(
            'id,exam_id,user_id,started_at,submitted_at,attempt_number,status,mcq_score')
        .single();
    return ExamAttempt.fromMap(data as Map<String, dynamic>);
  }

  Future<void> updateExamAttempt(String id, Map<String, dynamic> payload) async {
    await _client.from('exam_attempts').update(payload).eq('id', id);
  }

  Future<List<ExamAnswer>> fetchExamAnswers(String attemptId) async {
    final data = await _client
        .from('exam_answers')
        .select('id,attempt_id,question_id,choice_id,answer_text,is_correct,score')
        .eq('attempt_id', attemptId);
    return (data as List<dynamic>)
        .map((item) => ExamAnswer.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertExamAnswer(Map<String, dynamic> payload) async {
    await _client
        .from('exam_answers')
        .upsert(payload, onConflict: 'attempt_id,question_id');
  }

  Future<List<ExamAttempt>> fetchMyExamAttemptsForClass({
    required String userId,
    required String? classId,
  }) async {
    var query = _client
        .from('exam_attempts')
        .select('id,exam_id,user_id,started_at,submitted_at,attempt_number,status,mcq_score,exams(class_id)')
        .eq('user_id', userId);
    if (classId != null && classId.isNotEmpty) {
      query = query.eq('exams.class_id', classId);
    }
    final data = await query.order('started_at', ascending: false);
    return (data as List<dynamic>)
        .map((item) => ExamAttempt.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateExamAnswer(String id, Map<String, dynamic> payload) async {
    await _client.from('exam_answers').update(payload).eq('id', id);
  }

  Future<List<AssignmentSubmission>> fetchAssignmentSubmissions(
    String assignmentId,
  ) async {
    final data = await _client
        .from('assignment_submissions')
        .select(
            'id,assignment_id,user_id,content,file_path,submitted_at,status,profiles(name,email,nim),assignments(title,class_id)')
        .eq('assignment_id', assignmentId)
        .order('submitted_at', ascending: false);
    return (data as List<dynamic>)
        .map(
          (item) => AssignmentSubmission.fromMap(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<AssignmentSubmission?> fetchMySubmission(
    String assignmentId,
    String userId,
  ) async {
    final data = await _client
        .from('assignment_submissions')
        .select(
            'id,assignment_id,user_id,content,file_path,submitted_at,status,profiles(name,email,nim),assignments(title,class_id)')
        .eq('assignment_id', assignmentId)
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) {
      return null;
    }
    return AssignmentSubmission.fromMap(data as Map<String, dynamic>);
  }

  Future<void> upsertAssignmentSubmission(Map<String, dynamic> payload) async {
    await _client
        .from('assignment_submissions')
        .upsert(payload, onConflict: 'assignment_id,user_id');
  }

  Future<List<AssignmentSubmission>> fetchClassSubmissions(String classId) async {
    final data = await _client
        .from('assignment_submissions')
        .select(
            'id,assignment_id,user_id,content,file_path,submitted_at,status,profiles(name,email,nim),assignments(title,class_id)')
        .eq('assignments.class_id', classId)
        .order('submitted_at', ascending: false);
    return (data as List<dynamic>)
        .map(
          (item) => AssignmentSubmission.fromMap(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<AssignmentSubmission>> fetchAllSubmissions() async {
    List<dynamic> data;
    try {
      data = await _client
          .from('assignment_submissions')
          .select(
              'id,assignment_id,user_id,content,file_path,submitted_at,status,profiles(name,email,nim),assignments(title,class_id)')
          .order('submitted_at', ascending: false);
    } on PostgrestException {
      data = await _client
          .from('assignment_submissions')
          .select(
              'id,assignment_id,user_id,content,file_path,submitted_at,status')
          .order('submitted_at', ascending: false);
    }
    data = await _ensureSubmissionEnrichment(data);
    return (data as List<dynamic>)
        .map(
          (item) => AssignmentSubmission.fromMap(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<AssignmentSubmission>> fetchMySubmissionsForClass({
    required String userId,
    required String? classId,
  }) async {
    List<dynamic> data;
    try {
      var query = _client
          .from('assignment_submissions')
          .select(
              'id,assignment_id,user_id,content,file_path,submitted_at,status,profiles(name,email,nim),assignments(title,class_id)')
          .eq('user_id', userId);
      if (classId != null && classId.isNotEmpty) {
        query = query.eq('assignments.class_id', classId);
      }
      data = await query.order('submitted_at', ascending: false);
    } on PostgrestException {
      var query = _client
          .from('assignment_submissions')
          .select(
              'id,assignment_id,user_id,content,file_path,submitted_at,status')
          .eq('user_id', userId);
      data = await query.order('submitted_at', ascending: false);
    }
    data = await _ensureSubmissionEnrichment(data);
    if (classId != null && classId.isNotEmpty) {
      data = data.where((item) {
        final map = item as Map<String, dynamic>;
        final assignment = map['assignments'];
        if (assignment is Map<String, dynamic>) {
          return assignment['class_id'] == classId;
        }
        return false;
      }).toList();
    }
    return (data as List<dynamic>)
        .map(
          (item) => AssignmentSubmission.fromMap(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<StudentItem>> fetchClassStudents(String classId) async {
    try {
      final data = await _client
          .from('profiles')
          .select('id,name,email')
          .eq('class_id', classId)
          .eq('role', 'user')
          .order('name');
      return (data as List<dynamic>)
          .map((item) => StudentItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> _enrichSubmissionsWithAssignments(
    List<dynamic> data,
  ) async {
    final assignmentIds = data
        .map((item) => (item as Map<String, dynamic>)['assignment_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final userIds = data
        .map((item) => (item as Map<String, dynamic>)['user_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    if (assignmentIds.isEmpty && userIds.isEmpty) {
      return data;
    }
    final assignmentMap = <String, Map<String, dynamic>>{};
    if (assignmentIds.isNotEmpty) {
      try {
        final assignments = await _client
            .from('assignments')
            .select('id,title,class_id')
            .inFilter('id', assignmentIds);
        for (final item in (assignments as List<dynamic>)) {
          final map = item as Map<String, dynamic>;
          assignmentMap[map['id'] as String] = map;
        }
      } catch (_) {}
    }
    final profileMap = <String, Map<String, dynamic>>{};
    if (userIds.isNotEmpty) {
      try {
        final profiles = await _client
            .from('profiles')
            .select('id,name,nim')
            .inFilter('id', userIds);
        for (final item in (profiles as List<dynamic>)) {
          final map = item as Map<String, dynamic>;
          profileMap[map['id'] as String] = map;
        }
      } catch (_) {}
    }
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map<String, dynamic>);
      final assignmentId = map['assignment_id'] as String?;
      if (assignmentId != null && assignmentMap.containsKey(assignmentId)) {
        map['assignments'] = assignmentMap[assignmentId];
      }
      final userId = map['user_id'] as String?;
      if (userId != null && profileMap.containsKey(userId)) {
        map['profiles'] = profileMap[userId];
      }
      return map;
    }).toList();
  }

  Future<List<dynamic>> _ensureSubmissionEnrichment(
    List<dynamic> data,
  ) async {
    if (data.isEmpty) {
      return data;
    }
    final needsEnrich = data.any((item) {
      final map = item as Map<String, dynamic>;
      return map['profiles'] == null || map['assignments'] == null;
    });
    if (!needsEnrich) {
      return data;
    }
    return _enrichSubmissionsWithAssignments(data);
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> payload) async {
    await _client.from('profiles').update(payload).eq('id', userId);
  }

  Future<String?> uploadAvatar({required XFile file}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('Sesi login tidak ditemukan.');
    }
    final name = file.name;
    final extension = name.contains('.')
        ? name.split('.').last.toLowerCase()
        : '';
    const allowed = ['png', 'jpg', 'jpeg'];
    if (!allowed.contains(extension)) {
      throw Exception('Format gambar harus png, jpg, atau jpeg.');
    }

    final size = await file.length();
    if (size > 5242880) {
      throw Exception('Ukuran gambar maksimal 5MB.');
    }

    final safeName = name.replaceAll(' ', '_');
    final path =
        'profiles/$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      await _client.storage.from('avatars').uploadBinary(path, bytes);
    } else {
      if (file.path.isNotEmpty) {
        await _client.storage.from('avatars').upload(path, File(file.path));
      } else {
        final bytes = await file.readAsBytes();
        await _client.storage.from('avatars').uploadBinary(path, bytes);
      }
    }

    return path;
  }

  Future<List<GradeItem>> fetchGrades() async {
    final data = await _client
        .from('grades')
        .select(
            'id,student_name,score,class_id,assignment_id,classes(name),assignments(title)')
        .order('created_at', ascending: false);
    return (data as List<dynamic>)
        .map((item) => GradeItem.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ExamGradeItem>> fetchExamGrades() async {
    final data = await _client
        .from('exam_grades')
        .select(
            'id,student_id,student_name,score,class_id,exam_id,classes(name),exams(title)')
        .order('created_at', ascending: false);
    return (data as List<dynamic>)
        .map((item) => ExamGradeItem.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ExamSubmissionItem>> fetchExamSubmissions(
    String examId,
  ) async {
    try {
      final data = await _client
          .from('exam_submissions')
          .select(
              'id,exam_id,user_id,submitted_at,profiles(name,email,nim),exams(title,class_id)')
          .eq('exam_id', examId)
          .order('submitted_at', ascending: false);
      return (data as List<dynamic>)
          .map(
            (item) => ExamSubmissionItem.fromMap(item as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException {
      final data = await _client
          .from('exam_submissions')
          .select('id,exam_id,user_id,submitted_at')
          .eq('exam_id', examId)
          .order('submitted_at', ascending: false);
      return (data as List<dynamic>)
          .map(
            (item) => ExamSubmissionItem.fromMap(item as Map<String, dynamic>),
          )
          .toList();
    }
  }

  Future<void> upsertExamSubmission(Map<String, dynamic> payload) async {
    await _client
        .from('exam_submissions')
        .upsert(payload, onConflict: 'exam_id,user_id');
  }

  Future<List<ExamSubmissionItem>> fetchMyExamSubmissionsForClass({
    required String userId,
    required String? classId,
  }) async {
    List<dynamic> data;
    try {
      var query = _client
          .from('exam_submissions')
          .select(
              'id,exam_id,user_id,submitted_at,profiles(name,email,nim),exams(title,class_id)')
          .eq('user_id', userId);
      if (classId != null && classId.isNotEmpty) {
        query = query.eq('exams.class_id', classId);
      }
      data = await query.order('submitted_at', ascending: false);
    } on PostgrestException {
      var query = _client
          .from('exam_submissions')
          .select('id,exam_id,user_id,submitted_at')
          .eq('user_id', userId);
      data = await query.order('submitted_at', ascending: false);
    }
    return (data as List<dynamic>)
        .map(
          (item) => ExamSubmissionItem.fromMap(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> insertGrade(Map<String, dynamic> payload) async {
    await _client.from('grades').insert(payload);
  }

  Future<void> insertExamGrade(Map<String, dynamic> payload) async {
    await _client.from('exam_grades').insert(payload);
  }

  Future<void> upsertExamGrade(Map<String, dynamic> payload) async {
    await _client
        .from('exam_grades')
        .upsert(payload, onConflict: 'exam_id,student_id');
  }

  Future<void> updateGrade(String id, Map<String, dynamic> payload) async {
    await _client.from('grades').update(payload).eq('id', id);
  }

  Future<void> updateExamGrade(String id, Map<String, dynamic> payload) async {
    await _client.from('exam_grades').update(payload).eq('id', id);
  }

  Future<void> deleteGrade(String id) async {
    await _client.from('grades').delete().eq('id', id);
  }

  Future<void> deleteExamGrade(String id) async {
    await _client.from('exam_grades').delete().eq('id', id);
  }

  Future<String?> uploadFile({
    required XFile file,
    required String bucket,
    required String folder,
  }) async {
    final name = file.name;
    final extension = name.contains('.')
        ? name.split('.').last.toLowerCase()
        : '';
    const allowed = ['pdf', 'docx', 'zip'];
    if (!allowed.contains(extension)) {
      throw Exception('Format file harus pdf, docx, atau zip.');
    }

    final size = await file.length();
    if (size > 104857600) {
      throw Exception('Ukuran file maksimal 100MB.');
    }

    final safeName = name.replaceAll(' ', '_');
    final path = '$folder/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      await _client.storage.from(bucket).uploadBinary(path, bytes);
    } else {
      if (file.path.isNotEmpty) {
        await _client.storage.from(bucket).upload(path, File(file.path));
      } else {
        final bytes = await file.readAsBytes();
        await _client.storage.from(bucket).uploadBinary(path, bytes);
      }
    }

    return path;
  }

  String getPublicUrl({required String bucket, required String path}) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }
}
