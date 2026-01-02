import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../modules/navigation/controllers/navigation_controller.dart';
import '../routes/app_routes.dart';

class AuthService extends GetxService {
  final SupabaseClient _client = Supabase.instance.client;
  final Rxn<User> user = Rxn<User>();
  final RxString role = ''.obs;
  final RxString name = ''.obs;
  final RxBool suspendRedirect = false.obs;
  StreamSubscription<AuthState>? _subscription;

  bool get isLoggedIn => user.value != null;

  @override
  void onInit() {
    super.onInit();
    final session = _client.auth.currentSession;
    user.value = session?.user;
    if (user.value != null) {
      loadProfile();
    }

    _subscription = _client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      user.value = session?.user;
      if (suspendRedirect.value) {
        return;
      }
      if (session?.user != null) {
        loadProfile();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.currentRoute != Routes.main) {
            if (Get.isRegistered<NavigationController>()) {
              Get.find<NavigationController>().reset();
            }
            Get.offAllNamed(Routes.main);
          }
        });
      } else {
        role.value = '';
        name.value = '';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.currentRoute != Routes.welcome &&
              Get.currentRoute != Routes.login &&
              Get.currentRoute != Routes.register) {
            Get.offAllNamed(Routes.welcome);
          }
        });
      }
    });
  }

  Future<void> loadProfile() async {
    final currentUser = user.value;
    if (currentUser == null) {
      return;
    }
    try {
      final response = await _client
          .from('profiles')
          .select('name, role')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (response == null) {
        return;
      }

      name.value = (response['name'] ?? '') as String;
      role.value = (response['role'] ?? 'user') as String;
    } catch (_) {
      name.value = '';
      role.value = '';
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final result = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'role': role},
    );

    final createdUser = result.user;
    if (createdUser == null) {
      return;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
