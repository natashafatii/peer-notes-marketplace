import 'package:flutter/material.dart';
import '../services/user_service.dart';

class AuthorAvatar extends StatelessWidget {
  final String userId;
  final String? imageUrl;
  final double radius;

  const AuthorAvatar({
    Key? key,
    required this.userId,
    this.imageUrl,
    this.radius = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();

    // If we have a valid URL, show it immediately for better performance
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return _buildAvatar(context, imageUrl);
    }

    // Otherwise, listen for real-time updates for this specific user
    return StreamBuilder<Map<String, dynamic>?>(
      stream: userService.getProfileStream(userId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final String? avatarUrl = profile?['avatar_url'];
        
        // Debug print to help us track the URL
        if (avatarUrl != null) {
          debugPrint('DEBUG: Loaded avatar for $userId: $avatarUrl');
        }

        return _buildAvatar(context, avatarUrl);
      },
    );
  }

  Widget _buildAvatar(BuildContext context, String? avatarUrl) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
          ? NetworkImage(avatarUrl)
          : null,
      child: (avatarUrl == null || avatarUrl.isEmpty)
          ? Icon(
              Icons.person,
              size: radius * 1.2,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
    );
  }
}
