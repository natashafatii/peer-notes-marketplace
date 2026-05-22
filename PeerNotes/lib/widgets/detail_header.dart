import 'package:flutter/material.dart';
import '../models/note.dart';
import '../widgets/bookmark_icon.dart';
import '../widgets/rating_widget.dart';

class DetailHeader extends StatelessWidget {
  final Note note;
  final VoidCallback? onBookmarkToggle;

  const DetailHeader({
    Key? key,
    required this.note,
    this.onBookmarkToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBadge(context),
              BookmarkIcon(
                isBookmarked: note.isBookmarked,
                size: 28,
                onToggle: (_) => onBookmarkToggle?.call(),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text(
            note.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -1.0,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 12),
          RatingWidget(
            rating: note.rating,
            count: note.reviewCount,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                note.category.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    final color = note.isFree ? Colors.green.shade600 : Colors.orange.shade700;
    final text = note.isFree ? 'FREE' : '\$${note.price.toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
