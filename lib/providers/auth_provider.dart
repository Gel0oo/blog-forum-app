// lib/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import '../supabase_config.dart';

class AuthProvider extends ChangeNotifier {
  bool get isLoggedIn => supabase.auth.currentSession != null;

  Future<void> signUp(String email, String password, {String? name}) async {
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
      data: name != null ? {'name': name} : null,
    );
    if (res.user != null && name != null && name.isNotEmpty) {
      await supabase.from('profiles').upsert({
        'id': res.user!.id,
        'name': name,
      });
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
    notifyListeners();
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    notifyListeners();
  }
}