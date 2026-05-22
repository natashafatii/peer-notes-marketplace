import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class UserService {
  final _supabase = Supabase.instance.client;

  // Real User Stream using Supabase
  Stream<Map<String, dynamic>> getUserStream() async* {
    final user = _supabase.auth.currentUser;
    
    // 1. If no user, yield guest data
    if (user == null) {
      yield {
        'name': 'Guest User',
        'email': 'guest@example.com',
        'profileImage': null,
        'uploadedNotes': [],
      };
      return;
    }

    // 2. Yield initial data from Auth metadata immediately to avoid stuck loading spinner
    yield {
      'name': user.userMetadata?['full_name'] ?? 
              user.userMetadata?['display_name'] ?? 
              user.userMetadata?['name'] ?? 
              'User',
      'email': user.email ?? '',
      'profileImage': user.userMetadata?['avatar_url'],
      'uploadedNotes': [],
    };

    // 3. Yield real-time updates from 'profiles' table
    try {
      yield* _supabase
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', user.id)
          .map((data) {
            if (data.isEmpty) {
              return {
                'name': user.userMetadata?['full_name'] ?? 
                        user.userMetadata?['display_name'] ?? 
                        user.userMetadata?['name'] ?? 
                        'User',
                'email': user.email ?? '',
                'profileImage': null,
                'uploadedNotes': [],
              };
            }
            final profile = data.first;
            return {
              'name': profile['full_name'] ?? 
                      user.userMetadata?['full_name'] ?? 
                      user.userMetadata?['display_name'] ?? 
                      user.userMetadata?['name'] ?? 
                      'User',
              'email': user.email ?? '',
              'profileImage': profile['avatar_url'],
              'uploadedNotes': [],
            };
          })
          .handleError((error) {
            print('DEBUG: Stream error: $error');
            // If the table doesn't exist yet, the stream will error.
            // We return null or empty to let the UI know, or just let the initial yield stand.
          });
    } catch (e) {
      print('DEBUG: Exception in getUserStream: $e');
    }
  }

  // Update User Data in 'profiles' table
  Future<void> updateUserData({
    String? name,
    String? email,
    String? profileImage,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{
      'id': user.id,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (name != null) updates['full_name'] = name;
    if (profileImage != null) updates['avatar_url'] = profileImage;

    await _supabase.from('profiles').upsert(updates);
  }

  // Upload Profile Image to Supabase Storage
  // Using XFile for Web compatibility
  Future<String?> uploadProfileImage(XFile file) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // 1. Prepare file details
    final fileExt = file.path.split('.').last.toLowerCase();
    // On web, the path might not have an extension, default to 'jpg'
    final ext = fileExt.length > 5 ? 'jpg' : fileExt;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final filePath = '${user.id}/$fileName';

    try {
      print('DEBUG: Starting upload for $filePath');
      
      // 2. Upload to 'avatars' bucket
      // readAsBytes() is safe for both mobile and web
      final bytes = await file.readAsBytes();
      await _supabase.storage.from('avatars').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ),
          );

      print('DEBUG: Upload successful, getting public URL');

      // 3. Get Public URL
      final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
      
      // 4. Update the profile record with the new URL
      await updateUserData(profileImage: publicUrl);
      
      return publicUrl;
    } on StorageException catch (e) {
      print('DEBUG: Supabase Storage Error: ${e.message}');
      throw Exception('Storage Error: ${e.message}');
    } catch (e) {
      print('DEBUG: Unexpected Error during upload: $e');
      rethrow;
    }
  }

  // Get any user's profile stream by ID
  Stream<Map<String, dynamic>?> getProfileStream(String userId) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) => data.isNotEmpty ? data.first : null);
  }
}
