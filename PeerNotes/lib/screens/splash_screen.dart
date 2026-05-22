import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'home_screen.dart';

// ─────────────────────────────────────────────
//  Brand colours — aligned with M3 seed 0xFF6750A4
// ─────────────────────────────────────────────
const _kDeep = Color(0xFF1C0F3F); // darkest purple base (M3 shadow tone)
const _kAccent = Color(0xFF6750A4); // exact M3 primary seed
const _kGlow = Color(0xFFB39DDB); // M3 primary-container tint / lighter purple
const _kGold = Color(0xFFD0BCFF); // M3 onPrimary-container / lavender highlight

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── controllers ──────────────────────────────
  late final AnimationController _bgCtrl; // background rise
  late final AnimationController _logoCtrl; // logo entrance
  late final AnimationController _textCtrl; // title + subtitle
  late final AnimationController _dotsCtrl; // loading dots pulse
  late final AnimationController _orbCtrl; // floating orbs rotation
  late final AnimationController _shimmerCtrl; // shimmer ring

  // ── animations ───────────────────────────────
  late final Animation<double> _bgFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _dividerWidth; // decorative line expand
  late final Animation<double> _dotsFade;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();

    // Immersive full-screen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // ── background ──────────────────────────────
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);

    // ── logo ────────────────────────────────────
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = Tween<double>(
      begin: 0.55,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));

    _logoFade = CurvedAnimation(
      parent: _logoCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic));

    // ── title ───────────────────────────────────
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _titleFade = CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
          ),
        );

    _subtitleFade = CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );
    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
          ),
        );

    _dividerWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── dots ────────────────────────────────────
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _dotsFade = CurvedAnimation(parent: _dotsCtrl, curve: Curves.easeIn);

    // ── orbs ────────────────────────────────────
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // ── shimmer ring ────────────────────────────
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _shimmer = CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear);

    _runSequence();
  }

  Future<void> _runSequence() async {
    // stagger entrance
    await _bgCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _dotsCtrl.forward();

    // stay on screen
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    // restore system UI before leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final session = Supabase.instance.client.auth.currentSession;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) =>
            session != null ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _dotsCtrl.dispose();
    _orbCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _kDeep,
      body: FadeTransition(
        opacity: _bgFade,
        child: Stack(
          children: [
            // ── 1. Deep gradient background ──────
            _GradientBackground(size: size),

            // ── 2. Floating ambient orbs ──────────
            _FloatingOrbs(ctrl: _orbCtrl, size: size),

            // ── 3. Radial glow beneath logo ───────
            _RadialGlow(size: size),

            // ── 4. Main content column ────────────
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // ── Logo block ──────────────────
                  SlideTransition(
                    position: _logoSlide,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: _LogoBlock(shimmer: _shimmer),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Title ───────────────────────
                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleFade,
                      child: _buildTitle(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Divider ─────────────────────
                  AnimatedBuilder(
                    animation: _dividerWidth,
                    builder: (_, __) => Center(
                      child: Container(
                        width: 180 * _dividerWidth.value,
                        height: 1.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _kAccent.withValues(alpha: 0),
                              _kGold.withValues(alpha: 0.9),
                              _kAccent.withValues(alpha: 0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Subtitle ────────────────────
                  SlideTransition(
                    position: _subtitleSlide,
                    child: FadeTransition(
                      opacity: _subtitleFade,
                      child: _buildSubtitle(),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Animated dots ───────────────
                  FadeTransition(
                    opacity: _dotsFade,
                    child: const _PulsingDots(),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFEADDFF)],
        // white → M3 primaryContainer lavender
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: const Text(
        'Peer Notes',
        style: TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          color: Colors.white, // masked by ShaderMask
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'M A R K E T P L A C E',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 5,
        color: _kGlow.withValues(alpha: 0.75),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Gradient background
// ─────────────────────────────────────────────
class _GradientBackground extends StatelessWidget {
  final Size size;
  const _GradientBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.30),
          radius: 1.3,
          colors: [
            Color(0xFF4A3780), // M3 primary-dark centre
            Color(0xFF1C0F3F), // deep purple base edge
          ],
          stops: [0.0, 1.0],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Radial glow beneath logo
// ─────────────────────────────────────────────
class _RadialGlow extends StatelessWidget {
  final Size size;
  const _RadialGlow({required this.size});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: size.width / 2 - 130,
      top: size.height * 0.22,
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              _kAccent.withValues(alpha: 0.28),
              _kAccent.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Floating ambient orbs
// ─────────────────────────────────────────────
class _FloatingOrbs extends StatelessWidget {
  final AnimationController ctrl;
  final Size size;
  const _FloatingOrbs({required this.ctrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ctrl.value * 2 * math.pi;
        return Stack(
          children: [
            _orb(
              left: size.width * 0.1 + math.sin(t * 0.7) * 18,
              top: size.height * 0.12 + math.cos(t * 0.5) * 14,
              radius: 90,
              color: _kAccent.withValues(alpha: 0.12),
            ),
            _orb(
              left: size.width * 0.65 + math.cos(t * 0.4) * 20,
              top: size.height * 0.08 + math.sin(t * 0.6) * 16,
              radius: 60,
              color: _kGold.withValues(alpha: 0.08),
            ),
            _orb(
              left: size.width * 0.75 + math.sin(t * 0.3) * 24,
              top: size.height * 0.7 + math.cos(t * 0.45) * 18,
              radius: 110,
              color: _kAccent.withValues(alpha: 0.10),
            ),
            _orb(
              left: size.width * 0.05 + math.cos(t * 0.6) * 14,
              top: size.height * 0.75 + math.sin(t * 0.5) * 16,
              radius: 70,
              color: _kGlow.withValues(alpha: 0.09),
            ),
          ],
        );
      },
    );
  }

  Widget _orb({
    required double left,
    required double top,
    required double radius,
    required Color color,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Logo block with shimmer ring
// ─────────────────────────────────────────────
class _LogoBlock extends StatelessWidget {
  final Animation<double> shimmer;
  const _LogoBlock({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer shimmer ring
        AnimatedBuilder(
          animation: shimmer,
          builder: (_, __) {
            return CustomPaint(
              size: const Size(148, 148),
              painter: _ShimmerRingPainter(shimmer.value),
            );
          },
        ),

        // Frosted inner circle
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6750A4), Color(0xFF38276F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withValues(alpha: 0.55),
                blurRadius: 40,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: _kGlow.withValues(alpha: 0.2),
                blurRadius: 80,
                spreadRadius: 10,
              ),
            ],
            border: Border.all(
              color: _kGlow.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            size: 54,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Shimmer ring painter
// ─────────────────────────────────────────────
class _ShimmerRingPainter extends CustomPainter {
  final double progress;
  _ShimmerRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 70.0;

    // Dim track ring
    final trackPaint = Paint()
      ..color = _kGlow.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, trackPaint);

    // Rotating shimmer arc
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [
          Colors.transparent,
          _kGold.withValues(alpha: 0.9),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(2 * math.pi * progress),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2 * math.pi * progress,
      math.pi * 0.7,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ShimmerRingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────
//  Pulsing animated dots
// ─────────────────────────────────────────────
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];
  final List<Animation<double>> _scales = [];

  static const int _dotCount = 3;
  static const Duration _period = Duration(milliseconds: 600);
  static const Duration _stagger = Duration(milliseconds: 160);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _dotCount; i++) {
      final ctrl = AnimationController(vsync: this, duration: _period)
        ..repeat(reverse: true);
      _ctrls.add(ctrl);
      _scales.add(
        Tween<double>(
          begin: 0.5,
          end: 1.0,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut)),
      );

      // stagger start
      Future.delayed(_stagger * i, () {
        if (mounted) ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_dotCount, (i) {
        return AnimatedBuilder(
          animation: _scales[i],
          builder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Opacity(
              opacity: 0.4 + 0.6 * _scales[i].value,
              child: Container(
                width: 7 * _scales[i].value,
                height: 7 * _scales[i].value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kGlow,
                  boxShadow: [
                    BoxShadow(
                      color: _kAccent.withValues(alpha: 0.6 * _scales[i].value),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
