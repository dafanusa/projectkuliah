import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assignment_item.dart';
import '../models/assignment_submission.dart';
import '../models/class_item.dart';
import '../models/grade_item.dart';
import '../models/lecturer_work_item.dart';
import '../models/material_item.dart';
import '../models/student_item.dart';

class DataService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ClassItem>> fetchClasses() async {
    final data = await _client.from('classes').select().order('name');
    return (data as List<dynamic>)
        .map((item) => ClassItem.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addClass(String name) async {
    await _client.from('classes').insert({'name': name});
  }

  Future<void> updateClass(String id, String name) async {
    await _client.from('classes').update({'name': name}).eq('id', id);
  }

  Future<void> deleteClass(String id) async {
    await _client.from('classes').delete().eq('id', id);
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

  Future<void> insertAssignment(Map<String, dynamic> payload) async {
    await _client.from('assignments').insert(payload);
  }

  Future<void> updateAssignment(String id, Map<String, dynamic> payload) async {
    await _client.from('assignments').update(payload).eq('id', id);
  }

  Future<void> deleteAssignment(String id) async {
    await _client.from('assignments').delete().eq('id', id);
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

  Future<void> insertGrade(Map<String, dynamic> payload) async {
    await _client.from('grades').insert(payload);
  }

  Future<void> updateGrade(String id, Map<String, dynamic> payload) async {
    await _client.from('grades').update(payload).eq('id', id);
  }

  Future<void> deleteGrade(String id) async {
    await _client.from('grades').delete().eq('id', id);
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
