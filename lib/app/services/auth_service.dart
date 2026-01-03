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
  final RxString nim = ''.obs;
  final RxString avatarUrl = ''.obs;
  final RxBool isProfileLoading = false.obs;
  final RxBool suspendRedirect = false.obs;
  StreamSubscription<AuthState>? _subscription;

  bool get isLoggedIn => user.value != null;

  @override
  void onInit() {
    super.onInit();
    final session = _client.auth.currentSession;
    user.value = session?.user;
    if (user.value != null) {
      Future.microtask(loadProfile);
    } else {
      isProfileLoading.value = false;
    }

    _subscription = _client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      user.value = session?.user;
      if (suspendRedirect.value) {
        return;
      }
      if (session?.user != null) {
        await loadProfile();
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
        nim.value = '';
        avatarUrl.value = '';
        isProfileLoading.value = false;
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
      isProfileLoading.value = false;
      return;
    }
    isProfileLoading.value = true;
    final meta = currentUser.userMetadata ?? {};
    final metaName = (meta['name'] ?? '') as String;
    final metaRole = (meta['role'] ?? 'user') as String;
    final metaNim = (meta['nim'] ?? '') as String;
    final hadRole = role.value.isNotEmpty;
    try {
      final response = await _client
          .from('profiles')
          .select('name, role, nim, avatar_url')
          .eq('id', currentUser.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 3), onTimeout: () => null);

      if (response == null) {
        if (metaName.isNotEmpty || metaNim.isNotEmpty) {
          await _client.from('profiles').upsert({
            'id': currentUser.id,
            'name': metaName,
            'role': metaRole,
            'nim': metaNim,
          });
        }
        name.value = metaName;
        role.value = metaRole;
        nim.value = metaNim;
        avatarUrl.value = '';
        return;
      }

      final profileName = (response['name'] ?? '') as String;
      final profileRole = (response['role'] ?? 'user') as String;
      final profileNim = (response['nim'] ?? '') as String;
      final profileAvatar = (response['avatar_url'] ?? '') as String;
      if ((profileName.isEmpty && metaName.isNotEmpty) ||
          (profileNim.isEmpty && metaNim.isNotEmpty)) {
        await _client
            .from('profiles')
            .update({
              'name': profileName.isEmpty ? metaName : profileName,
              'nim': profileNim.isEmpty ? metaNim : profileNim,
            })
            .eq('id', currentUser.id);
      }

      name.value = profileName.isEmpty ? metaName : profileName;
      role.value = profileRole.isEmpty ? metaRole : profileRole;
      nim.value = profileNim.isEmpty ? metaNim : profileNim;
      avatarUrl.value = profileAvatar;
    } catch (_) {
      if (!hadRole) {
        name.value = metaName;
        role.value = metaRole;
        nim.value = metaNim;
      }
      avatarUrl.value = '';
    } finally {
      isProfileLoading.value = false;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String name,
    required String nim,
    required String email,
    required String password,
    required String role,
  }) async {
    final result = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'role': role, 'nim': nim},
    );

    final createdUser = result.user;
    if (createdUser == null) {
      return;
    }
    try {
      await _client.from('profiles').upsert({
        'id': createdUser.id,
        'name': name,
        'role': role,
        'nim': nim,
      });
    } catch (_) {
      // Ignore profile insert errors; profile can be updated later.
    }
  }

  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    await _client.auth.signOut(scope: scope);
  }

  void signOutAndRedirect() {
    Get.offAllNamed(Routes.welcome);
    _client.auth.signOut(scope: SignOutScope.local);
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
