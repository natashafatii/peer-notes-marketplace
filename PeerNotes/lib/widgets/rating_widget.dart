import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final int count;
  final double iconSize;

  const RatingWidget({
    Key? key,
    required this.rating,
    required this.count,
    this.iconSize = 18,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < rating.floor()
                  ? Icons.star_rounded
                  : (index < rating ? Icons.star_half_rounded : Icons.star_outline_rounded),
              color: Colors.amber,
              size: iconSize,
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(width: 4),
        Text(
          '($count)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
