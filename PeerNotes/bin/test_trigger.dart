import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: 'https://dpfnzmtvojbiafeksqaw.supabase.co',
    anonKey: 'sb_publishable_o0FkuB_yGuRYM1brWkLNEw_gL9_2ILY',
  );

  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  
  if (user == null) {
    print('Error: No active session. Please log in first or run within an authenticated context.');
    // Let's try to sign in with a test account or get the first profile to test
    final profiles = await client.from('profiles').select().limit(1);
    if (profiles.isEmpty) {
      print('No profiles found');
      return;
    }
    final firstProfile = profiles.first;
    print('Testing with profile: ${firstProfile['id']}');
    print('Current daily_uploads_count: ${firstProfile['daily_uploads_count']}');
    
    // We can't insert a note on behalf of someone else unless RLS allows it, 
    // but we can query if there are triggers on the notes table using Postgres system views if accessible:
    try {
      final triggers = await client.from('pg_trigger').select('tgname');
      print('Triggers: $triggers');
    } catch (e) {
      print('Cannot query pg_trigger directly: $e');
    }
    return;
  }
}
