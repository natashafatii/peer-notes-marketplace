import 'package:flutter/material.dart';

class BookmarkIcon extends StatefulWidget {
  final bool isBookmarked;
  final Function(bool)? onToggle;
  final double size;

  const BookmarkIcon({
    Key? key,
    this.isBookmarked = false,
    this.onToggle,
    this.size = 24,
  }) : super(key: key);

  @override
  State<BookmarkIcon> createState() => _BookmarkIconState();
}

class _BookmarkIconState extends State<BookmarkIcon> with SingleTickerProviderStateMixin {
  late bool _isBookmarked;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.isBookmarked;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });
        _controller.forward(from: 0);
        
        if (widget.onToggle != null) widget.onToggle!(_isBookmarked);
      },

      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Icon(
          _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
          color: _isBookmarked ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
          size: widget.size,
        ),
      ),
    );
  }
}
