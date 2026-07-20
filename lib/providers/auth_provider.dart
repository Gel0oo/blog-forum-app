import 'package:flutter/foundation.dart';
import '../supabase_config.dart';

// Handles all authentication, will be called via main.dart and router.dart to determine if user is logged in or not
class AuthProvider extends ChangeNotifier {
  bool get isLoggedIn => supabase.auth.currentSession != null;

  Future<void> signUp(String email, String password) async {
    await supabase.auth.signUp(email: email, password: password);
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