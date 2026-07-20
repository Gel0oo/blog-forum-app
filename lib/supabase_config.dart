import 'package:supabase_flutter/supabase_flutter.dart';

// Connection for supabase
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
}

// Shortcut so we don't type Supabase.instance.client anywhere
final supabase = Supabase.instance.client;