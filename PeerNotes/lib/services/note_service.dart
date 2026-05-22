import 'dart:io';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/note.dart';

class NoteService {
  final _supabase = Supabase.instance.client;

  String? get uid => _supabase.auth.currentUser?.id;

  // Upload a note file and its metadata
  Future<bool> uploadNote({
    required File file,
    required String fileName,
    required String title,
    required String description,
    required double price,
    required String category,
  }) async {
    // Note: The actual upload logic is currently in UploadScreen.
    // This method can be implemented here if refactoring is needed.
    return true;
  }

  // Get notes uploaded by the current user
  Stream<List<Note>> getUserUploads() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('uploader_id', user.id)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Note.fromMap(json)).toList());
  }

  // Get notes saved by the current user
  Stream<List<Note>> getSavedNotes() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('saved_notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .asyncMap((data) async {
          if (data.isEmpty) return [];
          final noteIds = data.map((row) => row['note_id']).toList();
          final notesData = await _supabase
              .from('notes')
              .select()
              .filter('id', 'in', noteIds);

          return (notesData as List).map((json) {
            final note = Note.fromMap(json);
            note.isBookmarked = true;
            return note;
          }).toList();
        });
  }

  // Set bookmark status
  Future<void> setBookmark(String noteId, bool save) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (!save) {
      await _supabase
          .from('saved_notes')
          .delete()
          .eq('user_id', user.id)
          .eq('note_id', noteId);
    } else {
      // Check if already exists to avoid unique constraint error
      final exists = await isNoteSaved(noteId);
      if (!exists) {
        await _supabase.from('saved_notes').insert({
          'user_id': user.id,
          'note_id': noteId,
        });
      }
    }
  }

  // Check if note is saved
  Future<bool> isNoteSaved(String noteId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final data = await _supabase
        .from('saved_notes')
        .select()
        .eq('user_id', user.id)
        .eq('note_id', noteId)
        .maybeSingle();

    return data != null;
  }

  // Get reviews for a note (with reviewer avatar join and graceful fallback)
  Stream<List<Review>> getNoteReviews(String noteId) async* {
    try {
      // 1. Try to fetch with profiles join to get avatarUrl
      final response = await _supabase
          .from('reviews')
          .select('*, profiles(avatar_url)')
          .eq('note_id', noteId)
          .order('created_at', ascending: false);

      yield (response as List).map((json) => Review.fromMap(json)).toList();
    } catch (e) {
      print('DEBUG: Error loading reviews with profile join, falling back: $e');
      try {
        // 2. Graceful fallback: Query without join if constraint is missing
        final fallbackResponse = await _supabase
            .from('reviews')
            .select()
            .eq('note_id', noteId)
            .order('created_at', ascending: false);

        yield (fallbackResponse as List).map((json) => Review.fromMap(json)).toList();
      } catch (fallbackError) {
        print('DEBUG: Error in fallback loading reviews: $fallbackError');
        yield [];
      }
    }
  }

  // Add a review
  Future<void> addReview(
    String noteId,
    double rating,
    String reviewText,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final userName =
        (user.userMetadata?['display_name'] as String?)?.trim().isNotEmpty ==
            true
        ? user.userMetadata!['display_name'] as String
        : (user.email?.split('@').first ?? 'Anonymous');

    await _supabase.from('reviews').insert({
      'note_id': noteId,
      'user_id': user.id,
      'user_name': userName,
      'rating': rating,
      'comment': reviewText,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Update average rating and review count in 'notes' table
    try {
      final reviewsData = await _supabase
          .from('reviews')
          .select('rating')
          .eq('note_id', noteId);

      if (reviewsData.isNotEmpty) {
        double totalRating = 0;
        int validRatingsCount = 0;
        for (var r in reviewsData) {
          final rValue = (r['rating'] as num).toDouble();
          if (rValue > 0) {
            totalRating += rValue;
            validRatingsCount++;
          }
        }
        
        double avgRating = validRatingsCount > 0 ? totalRating / validRatingsCount : 0.0;

        await _supabase.from('notes').update({
          'rating': avgRating,
          'review_count': reviewsData.length,
        }).eq('id', noteId);
      }
    } catch (e) {
      debugPrint('Error updating average rating: $e');
    }
  }

  // Delete a review and update the average rating
  Future<void> deleteReview(String reviewId, String noteId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // 1. Delete the review ensuring the user is only deleting their own review
    await _supabase
        .from('reviews')
        .delete()
        .eq('id', reviewId)
        .eq('user_id', user.id);

    // 2. Update average rating and review count in 'notes' table
    try {
      final reviewsData = await _supabase
          .from('reviews')
          .select('rating')
          .eq('note_id', noteId);

      double avgRating = 0.0;
      int reviewCount = 0;

      if (reviewsData.isNotEmpty) {
        double totalRating = 0;
        int validRatingsCount = 0;
        for (var r in reviewsData) {
          final rValue = (r['rating'] as num).toDouble();
          if (rValue > 0) {
            totalRating += rValue;
            validRatingsCount++;
          }
        }
        avgRating = validRatingsCount > 0 ? totalRating / validRatingsCount : 0.0;
        reviewCount = reviewsData.length;
      }

      await _supabase.from('notes').update({
        'rating': avgRating,
        'review_count': reviewCount,
      }).eq('id', noteId);
    } catch (e) {
      debugPrint('Error updating average rating after delete: $e');
    }
  }

  // Get a stream for a single note
  Stream<Note> getNoteStream(String noteId) {
    return _supabase
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('id', noteId)
        .map((data) => Note.fromMap(data.first));
  }

  // Record a download in the history
  Future<void> recordDownload(String noteId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // 1. Record in downloaded_notes table
    // Using upsert (onConflict: note_id, user_id) to update timestamp if already downloaded
    await _supabase.from('downloaded_notes').upsert({
      'user_id': user.id,
      'note_id': noteId,
      'downloaded_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,note_id');

    // 2. Increment download count in notes table
    // In a real app, you might use a RPC or trigger for this.
    // For now, we'll fetch and update.
    try {
      final noteData = await _supabase
          .from('notes')
          .select('download_count')
          .eq('id', noteId)
          .single();

      final currentCount = (noteData['download_count'] as int? ?? 0);
      await _supabase
          .from('notes')
          .update({'download_count': currentCount + 1})
          .eq('id', noteId);
    } catch (e) {
      print('Error incrementing download count: $e');
    }
  }

  // Get notes downloaded by the current user
  Stream<List<Note>> getDownloadedNotes() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('downloaded_notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('downloaded_at', ascending: false)
        .asyncMap((data) async {
          if (data.isEmpty) return [];
          final noteIds = data.map((row) => row['note_id']).toList();

          final List<Note> notes = [];
          for (var noteId in noteIds) {
            final noteData = await _supabase
                .from('notes')
                .select()
                .eq('id', noteId)
                .maybeSingle();

            if (noteData != null) {
              notes.add(Note.fromMap(noteData));
            }
          }
          return notes;
        });
  }

  // Get all notes from Supabase with author profile pictures
  Stream<List<Note>> getAllNotes() {
    return _supabase
        .from('notes')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((notesData) async {
          if (notesData.isEmpty) return [];

          // 1. Get unique uploader IDs and filter out any null/invalid ones
          final uploaderIds = notesData
              .map((n) => n['uploader_id'])
              .where((id) => id != null && id.toString().isNotEmpty)
              .toSet()
              .toList();

          if (uploaderIds.isEmpty) {
            return notesData.map((json) => Note.fromMap(json)).toList();
          }

          // 2. Fetch avatars for these users in one batch
          final profilesData = await _supabase
              .from('profiles')
              .select('id, avatar_url')
              .filter('id', 'in', '(${uploaderIds.join(',')})');

          debugPrint(
            'DEBUG: Fetched ${profilesData.length} profiles for notes list',
          );

          // 3. Create a lookup map (userId -> avatarUrl)
          final avatarMap = {
            for (var p in profilesData as List) p['id']: p['avatar_url'],
          };

          // 4. Attach avatars to the notes
          return notesData.map((json) {
            final note = Note.fromMap(json);
            return note.copyWith(authorAvatarUrl: avatarMap[note.uploaderId]);
          }).toList();
        });
  }

  // Delete a note from both the database and storage
  Future<void> deleteNote(String noteId, String fileUrl) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // 1. Delete related records manually to prevent any foreign key constraint failures
    try {
      await _supabase.from('saved_notes').delete().eq('note_id', noteId);
      await _supabase.from('reviews').delete().eq('note_id', noteId);
      await _supabase.from('downloaded_notes').delete().eq('note_id', noteId);
    } catch (e) {
      debugPrint('Error deleting related note records: $e');
    }

    // 2. Delete the note from database
    await _supabase
        .from('notes')
        .delete()
        .eq('id', noteId)
        .eq('uploader_id', user.id);

    // 3. Extract path in bucket from public URL and delete from storage
    try {
      String pathInBucket;
      if (fileUrl.contains('note_attachments/')) {
        pathInBucket = Uri.decodeComponent(fileUrl.split('note_attachments/').last);
      } else {
        pathInBucket = Uri.decodeComponent(fileUrl.split('/').last);
      }

      if (pathInBucket.contains('?')) {
        pathInBucket = pathInBucket.split('?').first;
      }

      await _supabase.storage.from('note_attachments').remove([pathInBucket]);
    } catch (e) {
      debugPrint('Error deleting note file from storage: $e');
    }
  }
}
