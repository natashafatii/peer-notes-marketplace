import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // triggers analyzer
import 'premium_thumbnail.dart';
import '../models/note.dart';
import '../screens/note_detail_screen.dart';
import '../screens/edit_note_screen.dart';
import '../services/note_service.dart';
import 'bookmark_icon.dart';
import 'author_avatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NoteCard extends StatelessWidget {
  final Note note;

  const NoteCard({Key? key, required this.note}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnNote = currentUserId != null && currentUserId == note.uploaderId;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteDetailScreen(note: note),
              ),
            );
          },
          highlightColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.05),
          splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail / Icon Section
                    Hero(
                      tag: 'note_image_${note.id}',
                      child: PremiumThumbnail(
                        fileUrl: note.fileUrl,
                        previewUrl: note.previewUrl,
                        fileName: note.fileName,
                        isPdf: note.isPdf,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  height: 1.3,
                                  letterSpacing: -0.5,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            note.category,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isOwnNote)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditNoteScreen(note: note),
                                    ),
                                  );
                                },
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.only(right: 8),
                                tooltip: 'Edit Note',
                              ),
                            BookmarkIcon(
                              isBookmarked: note.isBookmarked,
                              size: 20,
                              onToggle: (save) {
                                NoteService().setBookmark(note.id, save);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: note.isPremium
                                ? Colors.amber.withOpacity(0.12)
                                : note.isFree
                                ? Colors.green.withOpacity(0.12)
                                : Theme.of(
                                    context,
                                  ).colorScheme.errorContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            note.isPremium
                                ? 'PREMIUM'
                                : note.isFree
                                ? 'FREE'
                                : '\$${note.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: note.isPremium
                                  ? Colors.amber.shade900
                                  : note.isFree
                                  ? Colors.green.shade700
                                  : Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (note.isPremium) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                size: 12,
                                color: Colors.amber.shade900,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${note.creditsCost} cr',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withOpacity(0.4),
                  height: 1,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          AuthorAvatar(
                            userId: note.uploaderId,
                            imageUrl: note.authorAvatarUrl,
                            radius: 10,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              note.uploaderName,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          note.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.download_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          note.downloadCount.toString(),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${note.createdAt.day}/${note.createdAt.month}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
