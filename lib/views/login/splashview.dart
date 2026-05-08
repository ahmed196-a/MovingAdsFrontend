import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/apptheme.dart';

class Splashview extends StatefulWidget {
  const Splashview({super.key});

  @override
  State<Splashview> createState() => _SplashviewState();
}

class _SplashviewState extends State<Splashview>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────
  late AnimationController _bgController;      // background gradient shift
  late AnimationController _roadController;    // road lines scrolling
  late AnimationController _carController;     // car slide-in
  late AnimationController _logoController;    // logo + text reveal
  late AnimationController _pulseController;   // glow pulse
  late AnimationController _particleController;// floating dots

  // ── Animations ───────────────────────────────────────────────────────────────
  late Animation<double> _bgAnim;
  late Animation<Offset> _carSlide;
  late Animation<double> _carFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _taglineFade;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Background gradient breathe
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgController, curve: Curves.easeInOut);

    // Road scroll — infinite
    _roadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    // Car swoops in from left
    _carController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _carSlide = Tween<Offset>(
      begin: const Offset(-1.6, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _carController, curve: Curves.easeOutCubic));
    _carFade = CurvedAnimation(parent: _carController, curve: Curves.easeIn);

    // Logo pop
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));
    _logoFade = CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.6));

    // Title slides up
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.4, 0.85, curve: Curves.easeOutCubic),
    ));
    _titleFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.4, 0.85),
    );

    // Tagline fades in last
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
    ));
    _taglineFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.65, 1.0),
    );

    // Glow pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Particle float
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // ── Sequence: car in → logo pop ────────────────────────────────────────────
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _carController.forward();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _logoController.forward();
    });

    // ── Navigate after 5 s ────────────────────────────────────────────────────
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _roadController.dispose();
    _carController.dispose();
    _logoController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgController,
          _roadController,
          _carController,
          _logoController,
          _pulseController,
          _particleController,
        ]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [

              // ── 1. ANIMATED GRADIENT BACKGROUND ──────────────────────────────
              _buildBackground(size),

              // ── 2. FLOATING PARTICLES ─────────────────────────────────────────
              _buildParticles(size),

              // ── 3. ROAD STRIP ─────────────────────────────────────────────────
              _buildRoad(size),

              // ── 4. SCROLLING ROAD DASHES ──────────────────────────────────────
              _buildRoadDashes(size),

              // ── 5. ANIMATED CAR ───────────────────────────────────────────────
              _buildCar(size),

              // ── 6. LOGO + TEXT ────────────────────────────────────────────────
              _buildLogoSection(size),

              // ── 7. BOTTOM TAGLINE BAR ─────────────────────────────────────────
              _buildBottomBar(size),
            ],
          );
        },
      ),
    );
  }

  // ── BACKGROUND ───────────────────────────────────────────────────────────────
  Widget _buildBackground(Size size) {
    final t = _bgAnim.value;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(const Color(0xff0d2b2b), const Color(0xff0a1f2e), t)!,
            Color.lerp(const Color(0xff0a3d35), const Color(0xff083025), t)!,
            Color.lerp(const Color(0xff051a14), const Color(0xff040f0b), t)!,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }

  // ── FLOATING PARTICLES ───────────────────────────────────────────────────────
  Widget _buildParticles(Size size) {
    final rnd = Random(42);
    final t = _particleController.value;
    return CustomPaint(
      size: size,
      painter: _ParticlePainter(t, rnd),
    );
  }

  // ── ROAD STRIP ───────────────────────────────────────────────────────────────
  Widget _buildRoad(Size size) {
    final roadY = size.height * 0.62;
    return Positioned(
      top: roadY,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xff1c1c1c),
              const Color(0xff111111),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff18B6A3).withOpacity(0.25 * _pulseAnim.value),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  // ── ROAD DASHES ──────────────────────────────────────────────────────────────
  Widget _buildRoadDashes(Size size) {
    final roadY = size.height * 0.62 + 36; // center of road
    final offset = _roadController.value * 60; // 60px per loop
    return Positioned(
      top: roadY - 3,
      left: 0,
      right: 0,
      child: ClipRect(
        child: SizedBox(
          height: 6,
          child: CustomPaint(
            size: Size(size.width, 6),
            painter: _DashPainter(offset),
          ),
        ),
      ),
    );
  }

  // ── CAR ──────────────────────────────────────────────────────────────────────
  Widget _buildCar(Size size) {
    final roadY = size.height * 0.62;
    return Positioned(
      top: roadY - 28,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _carFade,
        child: SlideTransition(
          position: _carSlide,
          child: Center(
            child: _CarWidget(glowValue: _pulseAnim.value),
          ),
        ),
      ),
    );
  }

  // ── LOGO + TEXT ──────────────────────────────────────────────────────────────
  Widget _buildLogoSection(Size size) {
    return Positioned(
      top: size.height * 0.14,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // Glow ring behind logo
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff18B6A3)
                          .withOpacity(0.35 * _pulseAnim.value),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
              // Logo
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: const Color(0xff18B6A3).withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // MOVING ADS title
          SlideTransition(
            position: _titleSlide,
            child: FadeTransition(
              opacity: _titleFade,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xff18B6A3), Color(0xffffffff), Color(0xff18B6A3)],
                  stops: [0.0, 0.5, 1.0],
                ).createShader(bounds),
                child: const Text(
                  'MOVING ADS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Decorative line
          FadeTransition(
            opacity: _titleFade,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, const Color(0xff18B6A3)],
                    ),
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xff18B6A3).withOpacity(_pulseAnim.value),
                  ),
                ),
                Container(
                  width: 40,
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xff18B6A3), Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM BAR ───────────────────────────────────────────────────────────────
  Widget _buildBottomBar(Size size) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _taglineSlide,
        child: FadeTransition(
          opacity: _taglineFade,
          child: Container(
            padding: const EdgeInsets.only(bottom: 40, top: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xff18B6A3).withOpacity(0.18),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tagline in Urdu-roman style
                Text(
                  'Ad lagao, paisa kamao',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 20),
                // Loading dots
                _buildLoadingDots(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final phase = (_particleController.value + i * 0.33) % 1.0;
        final opacity = (sin(phase * pi * 2) * 0.5 + 0.5).clamp(0.2, 1.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xff18B6A3).withOpacity(opacity),
          ),
        );
      }),
    );
  }
}

// ── CAR WIDGET ────────────────────────────────────────────────────────────────
class _CarWidget extends StatelessWidget {
  final double glowValue;
  const _CarWidget({required this.glowValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 70,
      decoration: BoxDecoration(
        boxShadow: [
          // Underglow
          BoxShadow(
            color: const Color(0xff18B6A3).withOpacity(0.45 * glowValue),
            blurRadius: 25,
            offset: const Offset(0, 18),
            spreadRadius: 4,
          ),
          BoxShadow(
            color: const Color(0xff18B6A3).withOpacity(0.2 * glowValue),
            blurRadius: 50,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _CarPainter(glowValue: glowValue),
      ),
    );
  }
}

// ── CAR PAINTER ───────────────────────────────────────────────────────────────
class _CarPainter extends CustomPainter {
  final double glowValue;
  _CarPainter({required this.glowValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Body gradient
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xff2ee8cc), const Color(0xff0e9a89)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Car body — sleek coupe shape
    final bodyPath = Path()
      ..moveTo(w * 0.05, h * 0.72)
      ..lineTo(w * 0.02, h * 0.55)
      ..lineTo(w * 0.18, h * 0.28)
      ..quadraticBezierTo(w * 0.3, h * 0.10, w * 0.45, h * 0.08)
      ..lineTo(w * 0.68, h * 0.08)
      ..quadraticBezierTo(w * 0.82, h * 0.10, w * 0.88, h * 0.28)
      ..lineTo(w * 0.98, h * 0.48)
      ..lineTo(w * 0.98, h * 0.72)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Roof shine
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    final roofPath = Path()
      ..moveTo(w * 0.22, h * 0.30)
      ..lineTo(w * 0.32, h * 0.13)
      ..lineTo(w * 0.65, h * 0.13)
      ..lineTo(w * 0.78, h * 0.30)
      ..close();
    canvas.drawPath(roofPath, shinePaint);

    // Windshield
    final glassPaint = Paint()
      ..color = const Color(0xff0d2b2b).withOpacity(0.75)
      ..style = PaintingStyle.fill;
    final windshieldPath = Path()
      ..moveTo(w * 0.24, h * 0.30)
      ..lineTo(w * 0.33, h * 0.15)
      ..lineTo(w * 0.52, h * 0.15)
      ..lineTo(w * 0.52, h * 0.30)
      ..close();
    canvas.drawPath(windshieldPath, glassPaint);

    // Rear window
    final rearPath = Path()
      ..moveTo(w * 0.55, h * 0.15)
      ..lineTo(w * 0.68, h * 0.15)
      ..lineTo(w * 0.78, h * 0.30)
      ..lineTo(w * 0.55, h * 0.30)
      ..close();
    canvas.drawPath(rearPath, glassPaint);

    // Headlight glow
    final headlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.9 * glowValue)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.92, h * 0.5), width: 18, height: 9),
      headlightPaint,
    );

    // Tail light
    final tailPaint = Paint()
      ..color = Colors.redAccent.withOpacity(0.8 * glowValue)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.05, h * 0.52), width: 12, height: 7),
      tailPaint,
    );

    // Wheels
    _drawWheel(canvas, Offset(w * 0.2, h * 0.78), 14.0);
    _drawWheel(canvas, Offset(w * 0.78, h * 0.78), 14.0);
  }

  void _drawWheel(Canvas canvas, Offset center, double r) {
    // Tire
    canvas.drawCircle(
      center,
      r,
      Paint()..color = const Color(0xff1a1a1a),
    );
    // Rim
    canvas.drawCircle(
      center,
      r * 0.6,
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.fill,
    );
    // Rim shine
    canvas.drawCircle(
      center,
      r * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xffaaaaaa), const Color(0xff555555)],
        ).createShader(Rect.fromCircle(center: center, radius: r * 0.55)),
    );
    // Spokes
    final spokePaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 5; i++) {
      final angle = i * 2 * pi / 5;
      canvas.drawLine(
        center,
        Offset(center.dx + cos(angle) * r * 0.52,
            center.dy + sin(angle) * r * 0.52),
        spokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CarPainter old) => old.glowValue != glowValue;
}

// ── ROAD DASH PAINTER ─────────────────────────────────────────────────────────
class _DashPainter extends CustomPainter {
  final double offset;
  _DashPainter(this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xffE8E8E8).withOpacity(0.35)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const dashW = 40.0;
    const gap = 20.0;
    final step = dashW + gap;
    final start = -(step - offset % step);
    for (double x = start; x < size.width + step; x += step) {
      canvas.drawLine(Offset(x, 3), Offset(x + dashW, 3), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.offset != offset;
}

// ── PARTICLE PAINTER ──────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double t;
  final Random rnd;

  _ParticlePainter(this.t, this.rnd);

  @override
  void paint(Canvas canvas, Size size) {
    final seeds = [
      [0.12, 0.15], [0.85, 0.08], [0.35, 0.22], [0.67, 0.35],
      [0.08, 0.45], [0.92, 0.5],  [0.25, 0.70], [0.75, 0.75],
      [0.5,  0.88], [0.45, 0.05], [0.6,  0.60], [0.18, 0.88],
    ];

    for (int i = 0; i < seeds.length; i++) {
      final phase = (t + i * 0.083) % 1.0;
      final y = (seeds[i][1] - phase * 0.18 + 1.0) % 1.0;
      final opacity = (sin(phase * pi) * 0.6).clamp(0.0, 0.6);
      final radius = 1.5 + (i % 3) * 1.0;

      canvas.drawCircle(
        Offset(seeds[i][0] * size.width, y * size.height),
        radius,
        Paint()
          ..color = const Color(0xff18B6A3).withOpacity(opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}