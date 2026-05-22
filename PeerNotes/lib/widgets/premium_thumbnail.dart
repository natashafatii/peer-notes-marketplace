import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';

class PremiumThumbnail extends StatefulWidget {
  final String fileUrl;
  final String? previewUrl;
  final String? fileName;
  final bool isPdf;

  const PremiumThumbnail({
    Key? key,
    required this.fileUrl,
    this.previewUrl,
    this.fileName,
    this.isPdf = false,
  }) : super(key: key);

  @override
  State<PremiumThumbnail> createState() => _PremiumThumbnailState();
}

class _PremiumThumbnailState extends State<PremiumThumbnail>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _floatController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _floatController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  bool _isImage(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.png') ||
        lowerPath.endsWith('.gif') ||
        lowerPath.endsWith('.webp');
  }

  bool _isWord(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.doc') || lowerPath.endsWith('.docx');
  }

  bool _isPpt(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.ppt') || lowerPath.endsWith('.pptx');
  }

  @override
  Widget build(BuildContext context) {
    final String urlToCheck = widget.fileUrl;
    final String nameToCheck = widget.fileName ?? '';
    final String pathToCheck = nameToCheck.isNotEmpty
        ? nameToCheck
        : urlToCheck;

    final bool isImg = _isImage(pathToCheck);
    final bool isPdfFile =
        widget.isPdf || pathToCheck.toLowerCase().endsWith('.pdf');
    final bool isWordFile = _isWord(pathToCheck);
    final bool isPptFile = _isPpt(pathToCheck);

    if (isImg) {
      return _buildImageThumbnail();
    } else if (isPptFile) {
      return _buildPptThumbnail();
    } else {
      return _buildAdvancedDocumentThumbnail(isPdfFile, isWordFile);
    }
  }

  Widget _buildImageThumbnail() {
    final imageUrl =
        (widget.previewUrl != null && widget.previewUrl!.isNotEmpty)
        ? widget.previewUrl!
        : widget.fileUrl;

    // Vibrant color palette that cycles — never grey
    const List<Color> vibrancy = [
      Color(0xFF6C63FF), // purple
      Color(0xFFFF6584), // pink
      Color(0xFF43E97B), // green
      Color(0xFFF7971E), // amber
      Color(0xFF4FACFE), // sky blue
      Color(0xFFFA709A), // coral
    ];

    return GestureDetector(
      onTapDown: (_) => _floatController.forward(),
      onTapUp: (_) => _floatController.reverse(),
      onTapCancel: () => _floatController.reverse(),
      child: SizedBox(
        width: 80,
        height: 80,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _gradientController,
            _floatController,
            _particleController,
          ]),
          builder: (context, child) {
            // Ken Burns slow zoom
            final kbScale =
                1.0 +
                (math.sin(_gradientController.value * math.pi * 2) + 1) * 0.08;
            // Cinematic parallax float
            final floatY = math.sin(_floatController.value * math.pi) * 3;
            // Tap bounce scale
            final tapScale = 1.0 - (_floatController.value * 0.04);
            // Shimmer sweep position (left → right)
            final shimmerX = -1.5 + _particleController.value * 3.0;
            // Cycling gradient angle
            final gradAngle = _gradientController.value * 2 * math.pi;
            // Vibrant border colors cycling
            final colorIdx =
                (_gradientController.value * vibrancy.length).floor() %
                vibrancy.length;
            final nextIdx = (colorIdx + 1) % vibrancy.length;
            final t = (_gradientController.value * vibrancy.length) - colorIdx;
            final borderColor = Color.lerp(
              vibrancy[colorIdx],
              vibrancy[nextIdx],
              t,
            )!;

            return Transform.scale(
              scale: tapScale,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // 1. Outer pulsing neon glow (vibrant, never grey)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: borderColor.withOpacity(0.5),
                          blurRadius: 18,
                          spreadRadius: 2,
                          offset: Offset(
                            math.cos(gradAngle) * 3,
                            math.sin(gradAngle) * 3,
                          ),
                        ),
                        BoxShadow(
                          color: vibrancy[(colorIdx + 2) % vibrancy.length]
                              .withOpacity(0.25),
                          blurRadius: 24,
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.6),
                          blurRadius: 10,
                          offset: const Offset(-4, -4),
                        ),
                      ],
                    ),
                  ),

                  // 2. Animated vibrant gradient border ring
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: SweepGradient(
                        transform: GradientRotation(gradAngle),
                        colors: [
                          vibrancy[colorIdx % vibrancy.length],
                          vibrancy[(colorIdx + 1) % vibrancy.length],
                          vibrancy[(colorIdx + 2) % vibrancy.length],
                          vibrancy[(colorIdx + 3) % vibrancy.length],
                          vibrancy[colorIdx % vibrancy.length],
                        ],
                      ),
                    ),
                  ),

                  // 3. Inner image card (inset 2px so gradient border shows)
                  Padding(
                    padding: const EdgeInsets.all(2.5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.002)
                          ..translate(0.0, floatY, 0.0)
                          ..scale(kbScale),
                        alignment: Alignment.center,
                        child: kIsWeb
                            ? Image.network(
                                imageUrl,
                                width: 75,
                                height: 75,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildVibrantFallback(borderColor),
                              )
                            : CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 75,
                                height: 75,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    _buildVibrantShimmerPlaceholder(
                                      borderColor,
                                    ),
                                errorWidget: (context, url, error) =>
                                    _buildVibrantFallback(borderColor),
                              ),
                      ),
                    ),
                  ),

                  // 4. Cinematic bottom gradient overlay
                  Positioned(
                    bottom: 2,
                    left: 2,
                    right: 2,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(18),
                      ),
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.55),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 5. Shimmer sweep (light bar sweeping left to right)
                  Positioned(
                    left: 2,
                    right: 2,
                    top: 2,
                    bottom: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(shimmerX - 0.4, -1),
                            end: Alignment(shimmerX + 0.4, 1),
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 6. Vibrant orbital particles
                  CustomPaint(
                    size: const Size(80, 80),
                    painter: ParticlePainter(
                      progress: _particleController.value,
                      color: borderColor,
                    ),
                  ),

                  // 7. Frosted glass IMG badge
                  Positioned(
                    bottom: -6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                borderColor.withOpacity(0.85),
                                vibrancy[(colorIdx + 2) % vibrancy.length]
                                    .withOpacity(0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: borderColor.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 8,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 3),
                              const Text(
                                'IMG',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVibrantShimmerPlaceholder(Color accentColor) {
    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.15),
            accentColor.withOpacity(0.35),
            accentColor.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_rounded,
          color: accentColor.withOpacity(0.6),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildVibrantFallback(Color accentColor) {
    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withOpacity(0.2), accentColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            color: accentColor.withOpacity(0.5),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            'IMG',
            style: TextStyle(
              color: accentColor.withOpacity(0.6),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrokenImageFallback() {
    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            size: 28,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedDocumentThumbnail(bool isPdf, bool isWord) {
    IconData iconData = Icons.description_rounded;
    String badgeText = 'FILE';
    Color baseColor = Colors.grey.shade600;
    Color glowColor = Colors.grey.shade300;

    if (isPdf) {
      iconData = Icons.picture_as_pdf_rounded;
      badgeText = 'PDF';
      baseColor = const Color(0xFFE53935);
      glowColor = const Color(0xFFFF8A80);
    } else if (isWord) {
      iconData = Icons.description_rounded;
      badgeText = 'DOC';
      baseColor = const Color(0xFF1E88E5);
      glowColor = const Color(0xFF82B1FF);
    }

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Neumorphic Base
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(6, 6),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 12,
                  offset: const Offset(-6, -6),
                ),
              ],
            ),
          ),

          // 2. Animated Gradient Border / Glow
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _gradientController.value * 2 * math.pi,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: SweepGradient(
                      colors: [
                        baseColor.withOpacity(0.0),
                        glowColor.withOpacity(0.5),
                        baseColor.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // 3. Glassmorphism Layer
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          // 4. Particle Effects
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(80, 80),
                painter: ParticlePainter(
                  progress: _particleController.value,
                  color: glowColor,
                ),
              );
            },
          ),

          // 5. Isometric 3D Floating Icon
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final floatOffset =
                  math.sin(_floatController.value * math.pi) * 4;
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002) // Perspective
                  ..rotateX(0.4) // Isometric tilt
                  ..rotateY(-0.3)
                  ..translate(0.0, floatOffset, 0.0),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Icon shadow for 3D depth
                    Transform.translate(
                      offset: const Offset(2, 8),
                      child: Icon(
                        iconData,
                        size: 38,
                        color: Colors.black.withOpacity(0.2),
                      ),
                    ),
                    // Actual Icon
                    Icon(iconData, size: 38, color: baseColor),
                  ],
                ),
              );
            },
          ),

          // 6. Premium Glass Badge
          Positioned(
            bottom: -6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [baseColor.withOpacity(0.8), baseColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// PowerPoint 3D slide-stack thumbnail with fire gradient + confetti particles
  Widget _buildPptThumbnail() {
    const Color pptRed = Color(0xFFD83B01);
    const Color pptOrange = Color(0xFFED6B00);
    const Color pptFire = Color(0xFFFF4B2B);
    const Color pptPink = Color(0xFFFF416C);
    const Color pptGold = Color(0xFFFFD700);

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Neumorphic base glow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: pptRed.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(6, 6),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 12,
                  offset: const Offset(-6, -6),
                ),
              ],
            ),
          ),

          // 2. Rotating fire sweep gradient
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _gradientController.value * 2 * math.pi,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: SweepGradient(
                      colors: [
                        pptFire.withOpacity(0.0),
                        pptPink.withOpacity(0.6),
                        pptOrange.withOpacity(0.4),
                        pptFire.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.33, 0.66, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // 3. Glassmorphism base card
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x22FF4B2B), Color(0x22D83B01)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          // 4. Confetti particle burst
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(80, 80),
                painter: ConfettiPainter(progress: _particleController.value),
              );
            },
          ),

          // 5. 3D stacked slide icons (floating)
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final floatOffset =
                  math.sin(_floatController.value * math.pi) * 4;

              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.003)
                  ..rotateX(0.35)
                  ..rotateY(-0.25)
                  ..translate(0.0, floatOffset, 0.0),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Slide 3 (back)
                    Transform.translate(
                      offset: const Offset(6, 6),
                      child: Container(
                        width: 34,
                        height: 26,
                        decoration: BoxDecoration(
                          color: pptOrange.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),
                    // Slide 2 (mid)
                    Transform.translate(
                      offset: const Offset(3, 3),
                      child: Container(
                        width: 34,
                        height: 26,
                        decoration: BoxDecoration(
                          color: pptRed.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    // Slide 1 (front - main)
                    Container(
                      width: 34,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [pptFire, pptRed],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: pptRed.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.slideshow_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 6. Glossy top-left reflection
          Positioned(
            top: 6,
            left: 8,
            child: Container(
              width: 28,
              height: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0.0),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),

          // 7. PPT badge
          Positioned(
            bottom: -6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [pptFire, pptPink, pptRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: pptRed.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 8, color: pptGold),
                      const SizedBox(width: 3),
                      const Text(
                        'PPT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // fixed seed for consistent particle paths
    for (int i = 0; i < 6; i++) {
      final startAngle = random.nextDouble() * 2 * math.pi;
      final distance = 15.0 + random.nextDouble() * 25.0;

      // Calculate particle position based on progress
      final currentProgress = (progress + (i / 6)) % 1.0;
      final currentDist = distance * math.sin(currentProgress * math.pi);

      final x =
          size.width / 2 +
          math.cos(startAngle + progress * math.pi) * currentDist;
      final y =
          size.height / 2 +
          math.sin(startAngle + progress * math.pi) * currentDist;

      // Fade out at edges
      paint.color = color.withOpacity((1.0 - currentProgress) * 0.8);
      canvas.drawCircle(Offset(x, y), 2.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;

  ConfettiPainter({required this.progress});

  static const List<Color> _colors = [
    Color(0xFFFF4B2B),
    Color(0xFFFF416C),
    Color(0xFFFFD700),
    Color(0xFFED6B00),
    Color(0xFFFF8C00),
    Color(0xFFFFFFFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(77);
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 0; i < 10; i++) {
      final angle = (i / 10) * 2 * math.pi + progress * 2 * math.pi;
      final dist = 20.0 + random.nextDouble() * 22.0;
      final currentProgress = (progress + (i / 10)) % 1.0;

      final x =
          cx + math.cos(angle) * dist * math.sin(currentProgress * math.pi);
      final y =
          cy + math.sin(angle) * dist * math.sin(currentProgress * math.pi);

      final color = _colors[i % _colors.length];
      final paint = Paint()
        ..color = color.withOpacity((1.0 - currentProgress) * 0.9)
        ..style = PaintingStyle.fill;

      // Draw tiny rotating squares for confetti effect
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * math.pi * 3 + i);
      canvas.drawRect(const Rect.fromLTWH(-2, -2, 4, 3), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({Key? key}) : super(key: key);

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.8),
                Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-2.0 + (_shimmerController.value * 4), 0.0),
              end: Alignment(-1.0 + (_shimmerController.value * 4), 0.0),
            ),
          ),
        );
      },
    );
  }
}
