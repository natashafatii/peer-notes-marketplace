import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';

class CreditService {
  final _supabase = Supabase.instance.client;

  String? get uid => _supabase.auth.currentUser?.id;

  // 1. Get current user's profile data (credits, upload count, etc.)
  Stream<Map<String, dynamic>> getCreditProfile() {
    if (uid == null) return Stream.value({'credits': 0, 'daily_uploads_count': 0});
    
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', uid!)
        .map((data) => data.isNotEmpty ? data.first : {'credits': 0, 'daily_uploads_count': 0});
  }

  // 2. Check if user has enough credits to unlock a note
  Future<bool> hasEnoughCredits(int cost) async {
    if (uid == null) return false;
    
    final res = await _supabase
        .from('profiles')
        .select('credits')
        .eq('id', uid!)
        .single();
    
    final credits = (res['credits'] as int? ?? 0);
    return credits >= cost;
  }

  // 3. Unlock a premium note
  Future<bool> unlockNote(Note note) async {
    if (uid == null) return false;

    try {
      // a. Deduct credits from user
      final currentProfile = await _supabase
          .from('profiles')
          .select('credits')
          .eq('id', uid!)
          .single();
      
      final currentCredits = (currentProfile['credits'] as int? ?? 0);
      
      if (currentCredits < note.creditsCost) {
        throw Exception('Insufficient credits');
      }

      // b. Record the transaction
      await _supabase.from('transactions').insert({
        'user_id': uid,
        'note_id': note.id,
        'credits_spent': note.creditsCost,
      });

      // c. Update user credits balance
      await _supabase.from('profiles').update({
        'credits': currentCredits - note.creditsCost,
      }).eq('id', uid!);

      return true;
    } catch (e) {
      print('DEBUG: Error unlocking note: $e');
      return false;
    }
  }

  // 4. Check if note is already unlocked by user
  Future<bool> isNoteUnlocked(String noteId) async {
    if (uid == null) return false;

    final res = await _supabase
        .from('transactions')
        .select()
        .eq('user_id', uid!)
        .eq('note_id', noteId)
        .maybeSingle();

    return res != null;
  }

  // 5. Add credits (mock purchase)
  Future<void> addCredits(int amount) async {
    if (uid == null) return;

    final currentProfile = await _supabase
        .from('profiles')
        .select('credits')
        .eq('id', uid!)
        .single();
    
    final currentCredits = (currentProfile['credits'] as int? ?? 0);

    await _supabase.from('profiles').update({
      'credits': currentCredits + amount,
    }).eq('id', uid!);
  }

  // 6. Get daily upload status (Idempotent and Self-Healing)
  Future<Map<String, dynamic>> getUploadStatus() async {
    if (uid == null) return {'canUpload': false, 'remaining': 0};

    try {
      final now = DateTime.now();
      final localMidnight = DateTime(now.year, now.month, now.day);
      final todayStart = localMidnight.toUtc().toIso8601String();

      // Query the actual number of notes uploaded by this user today
      final notesUploadedToday = await _supabase
          .from('notes')
          .select('id')
          .eq('uploader_id', uid!)
          .gte('created_at', todayStart);

      final int actualCount = notesUploadedToday.length;
      int remaining = 5 - actualCount;

      // Sync the profiles table so it matches the actual count
      try {
        await _supabase.from('profiles').update({
          'daily_uploads_count': actualCount,
          'last_upload_date': now.toIso8601String(),
        }).eq('id', uid!);
      } catch (profileError) {
        print('DEBUG: Profile update sync failed: $profileError');
      }

      return {
        'canUpload': remaining > 0,
        'remaining': remaining < 0 ? 0 : remaining,
        'count': actualCount,
      };
    } catch (e) {
      print('DEBUG: Error in getUploadStatus, falling back: $e');
      // Fallback to reading profiles table if notes query fails
      try {
        final data = await _supabase
            .from('profiles')
            .select('daily_uploads_count, last_upload_date')
            .eq('id', uid!)
            .single();

        final int count = data['daily_uploads_count'] ?? 0;
        final String? lastDateStr = data['last_upload_date'];
        final DateTime lastDate = lastDateStr != null ? DateTime.parse(lastDateStr) : DateTime.fromMillisecondsSinceEpoch(0);
        final now = DateTime.now();
        final isNewDay = lastDate.year != now.year || 
                         lastDate.month != now.month || 
                         lastDate.day != now.day;

        int effectiveCount = isNewDay ? 0 : count;
        int remaining = 5 - effectiveCount;

        return {
          'canUpload': remaining > 0,
          'remaining': remaining < 0 ? 0 : remaining,
          'count': effectiveCount,
        };
      } catch (fallbackError) {
        print('DEBUG: Fallback failed: $fallbackError');
        return {'canUpload': true, 'remaining': 5, 'count': 0};
      }
    }
  }

  // 7. Record a successful upload (Idempotent and Self-Healing)
  Future<void> recordUpload() async {
    if (uid == null) return;

    try {
      final now = DateTime.now();
      final localMidnight = DateTime(now.year, now.month, now.day);
      final todayStart = localMidnight.toUtc().toIso8601String();

      // Query the actual number of notes uploaded by this user today
      final notesUploadedToday = await _supabase
          .from('notes')
          .select('id')
          .eq('uploader_id', uid!)
          .gte('created_at', todayStart);

      final int actualCount = notesUploadedToday.length;

      await _supabase.from('profiles').update({
        'daily_uploads_count': actualCount,
        'last_upload_date': now.toIso8601String(),
      }).eq('id', uid!);
      
      print('DEBUG: Upload recorded. Actual count updated: $actualCount');
    } catch (e) {
      print('DEBUG: Error recording upload: $e');
    }
  }
}
