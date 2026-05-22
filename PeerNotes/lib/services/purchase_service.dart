import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';

class PurchaseService {
  final _supabase = Supabase.instance.client;

  String? get uid => _supabase.auth.currentUser?.id;

  // Check if note is already unlocked by user
  Future<bool> isNoteUnlocked(String noteId) async {
    if (uid == null) return false;

    try {
      final res = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', uid!)
          .eq('note_id', noteId)
          .maybeSingle();

      return res != null;
    } catch (e) {
      print('DEBUG: Error checking purchase status: $e');
      return false;
    }
  }

  // Deduct credits ONLY
  Future<void> deductCredits(int cost) async {
    if (uid == null) throw Exception('Not logged in.');
    
    // 1. Get current user's credits
    final profile = await _supabase
        .from('profiles')
        .select('credits')
        .eq('id', uid!)
        .single();
    
    final int currentCredits = profile['credits'] ?? 0;

    if (currentCredits < cost) {
      throw Exception('Insufficient credits. You need $cost credits to unlock this note.');
    }

    // 2. Deduct credits
    await _supabase.from('profiles').update({
      'credits': currentCredits - cost,
    }).eq('id', uid!);
  }

  // Record the purchase transaction after mock payment completes
  Future<bool> completePurchase(Note note) async {
    if (uid == null) return false;

    try {
      await _supabase.from('transactions').insert({
        'user_id': uid,
        'note_id': note.id,
        'credits_spent': note.isPremium ? note.creditsCost : 0,
      });

      return true;
    } catch (e) {
      print('DEBUG: Purchase failed: $e');
      rethrow;
    }
  }

  // Stream for real-time credit updates
  Stream<int> getUserCreditsStream() {
    if (uid == null) return Stream.value(0);
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', uid!)
        .map((data) => data.isNotEmpty ? (data.first['credits'] ?? 0) : 0);
  }
}
