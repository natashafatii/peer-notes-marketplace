import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewCard extends StatelessWidget {
  final String userName;
  final String date;
  final String comment;
  final double rating;
  final String userId;
  final String? avatarUrl;
  final VoidCallback? onDelete;

  const ReviewCard({
    Key? key,
    required this.userName,
    required this.date,
    required this.comment,
    required this.rating,
    required this.userId,
    this.avatarUrl,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnReview = currentUserId != null && currentUserId == userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (avatarUrl != null && avatarUrl!.isNotEmpty)
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        backgroundImage: NetworkImage(avatarUrl!),
                      )
                    else
                      FutureBuilder<Map<String, dynamic>?>(
                        future: Supabase.instance.client
                            .from('profiles')
                            .select('avatar_url')
                            .eq('id', userId)
                            .maybeSingle(),
                        builder: (context, snapshot) {
                          final fetchedAvatarUrl = snapshot.data?['avatar_url'] as String?;
                          return CircleAvatar(
                            radius: 14,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            backgroundImage: (fetchedAvatarUrl != null && fetchedAvatarUrl.isNotEmpty)
                                ? NetworkImage(fetchedAvatarUrl)
                                : null,
                            child: (fetchedAvatarUrl == null || fetchedAvatarUrl.isEmpty)
                                ? Text(
                                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            date,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOwnReview && onDelete != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        onPressed: onDelete,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        splashRadius: 20,
                        tooltip: 'Delete Review',
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 14,
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}
