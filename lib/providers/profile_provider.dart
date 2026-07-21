import 'package:flutter/foundation.dart';
import '../supabase_config.dart';

class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic>? profile;
  bool isLoading = false;

  Future<void> fetchProfile() async {
    final userId = supabase.auth.currentUser!.id;
    isLoading = true;
    notifyListeners();

    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    profile = response;
    isLoading = false;
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('profiles').upsert({'id': userId, 'name': name});
    await fetchProfile();
  }

  Future<void> updateAvatar(Uint8List imageBytes) async {
    final userId = supabase.auth.currentUser!.id;
    final path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await supabase.storage.from('post_images').uploadBinary(path, imageBytes);
    final url = supabase.storage.from('post_images').getPublicUrl(path);

    await supabase.from('profiles').upsert({'id': userId, 'avatar_url': url});
    await fetchProfile();
  }

  Future<void> removeAvatar() async {
    final userId = supabase.auth.currentUser!.id;
    await supabase
        .from('profiles')
        .update({'avatar_url': null})
        .eq('id', userId);
    await fetchProfile();
  }
}
