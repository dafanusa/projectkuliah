import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assignment_item.dart';
import '../models/class_item.dart';
import '../models/grade_item.dart';
import '../models/material_item.dart';
import '../models/result_item.dart';

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

  Future<void> insertMaterial(Map<String, dynamic> payload) async {
    await _client.from('materials').insert(payload);
  }

  Future<void> updateMaterial(String id, Map<String, dynamic> payload) async {
    await _client.from('materials').update(payload).eq('id', id);
  }

  Future<void> deleteMaterial(String id) async {
    await _client.from('materials').delete().eq('id', id);
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

  Future<List<ResultItem>> fetchResults() async {
    final data = await _client
        .from('assignment_results')
        .select(
            'id,assignment_id,class_id,collected,missing,graded,classes(name),assignments(title)')
        .order('created_at', ascending: false);
    return (data as List<dynamic>)
        .map((item) => ResultItem.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertResult(Map<String, dynamic> payload) async {
    await _client.from('assignment_results').insert(payload);
  }

  Future<void> updateResult(String id, Map<String, dynamic> payload) async {
    await _client.from('assignment_results').update(payload).eq('id', id);
  }

  Future<void> deleteResult(String id) async {
    await _client.from('assignment_results').delete().eq('id', id);
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
