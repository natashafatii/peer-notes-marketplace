import 'package:flutter/material.dart';

class StarRatingInput extends StatefulWidget {
  final Function(int) onRatingChanged;
  final int initialRating;

  const StarRatingInput({
    Key? key,
    required this.onRatingChanged,
    this.initialRating = 0,
  }) : super(key: key);

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  void _updateRating(int rating) {
    setState(() {
      _currentRating = rating;
    });
    widget.onRatingChanged(rating);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isSelected = starIndex <= _currentRating;

            return IconButton(
              onPressed: () => _updateRating(starIndex),
              iconSize: 36,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                  key: ValueKey<bool>(isSelected),
                  color: isSelected ? Colors.amber : Theme.of(context).colorScheme.outline,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          '$_currentRating.0 / 5',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }
}
