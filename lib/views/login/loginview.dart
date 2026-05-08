import 'dart:math';
import 'package:ads_frontend/UserSession.dart';
import 'package:ads_frontend/services/api_service.dart';
import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../theme/apptheme.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Use nullable so build() can safely check before use
  AnimationController? _bgController;
  AnimationController? _entryController;
  AnimationController? _pulseController;

  Animation<double>? _bgAnim;
  Animation<double>? _cardSlide;
  Animation<double>? _cardFade;
  Animation<double>? _logoScale;
  Animation<double>? _pulseAnim;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _bgAnim = CurvedAnimation(
      parent: _bgController!,
      curve: Curves.easeInOut,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _cardSlide = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(parent: _entryController!, curve: Curves.easeOutCubic),
    );

    _cardFade = CurvedAnimation(
      parent: _entryController!,
      curve: const Interval(0.0, 0.7),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.12), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 45),
    ]).animate(
      CurvedAnimation(parent: _entryController!, curve: Curves.easeOut),
    );

    // Use addPostFrameCallback so first frame renders before animation starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryController!.forward();
    });
  }

  @override
  void dispose() {
    _bgController?.dispose();
    _entryController?.dispose();
    _pulseController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── LOGIN LOGIC (unchanged) ────────────────────────────────────────────────
  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All fields are required"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final AppUser? result = await ApiService.login(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      await UserSession.saveUser(
        result.userId,
        result.name,
        result.role,
        result.email,
        result.rating!,
      );
      if (result.role == 'a') {
        Navigator.pushReplacementNamed(context, '/advertiserDashboard');
      } else if (result.role == 'd') {
        Navigator.pushReplacementNamed(context, '/driverDashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/agencyDashboard');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid Credentials"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Safety guard — controllers not yet initialized
    if (_bgController == null ||
        _entryController == null ||
        _pulseController == null) {
      return const Scaffold(backgroundColor: Color(0xff071a17));
    }

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgController!,
          _entryController!,
          _pulseController!,
        ]),
        builder: (context, _) {
          final bgT     = _bgAnim?.value    ?? 0.0;
          final pulseT  = _pulseAnim?.value ?? 0.7;
          final slideT  = _cardSlide?.value ?? 0.0;
          final fadeT   = (_cardFade?.value ?? 0.0).clamp(0.0, 1.0);
          final scaleT  = _logoScale?.value ?? 1.0;

          return Stack(
            fit: StackFit.expand,
            children: [

              // ── Background ──────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(const Color(0xff071a17), const Color(0xff0a2822), bgT)!,
                      Color.lerp(const Color(0xff0b2e28), const Color(0xff071a14), bgT)!,
                      Color.lerp(const Color(0xff040f0b), const Color(0xff071410), bgT)!,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // ── Particles ────────────────────────────────────────────────
              CustomPaint(
                size: size,
                painter: _ParticlePainter(_bgController!.value),
              ),

              // ── Scrollable content ────────────────────────────────────────
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 48),

                      // Logo
                      Transform.scale(
                        scale: scaleT,
                        child: _buildLogoSection(pulseT),
                      ),

                      const SizedBox(height: 40),

                      // Card
                      Opacity(
                        opacity: fadeT,
                        child: Transform.translate(
                          offset: Offset(0, slideT),
                          child: _buildLoginCard(pulseT),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Sign up
                      Opacity(
                        opacity: fadeT,
                        child: _buildSignupRow(),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── LOGO SECTION ────────────────────────────────────────────────────────────
  Widget _buildLogoSection(double pulseT) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff18B6A3).withOpacity(0.4 * pulseT),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
                border: Border.all(
                  color: const Color(0xff18B6A3).withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xff18B6A3), Color(0xffffffff), Color(0xff18B6A3)],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: const Text(
            'MOVING ADS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 5,
            ),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Ad lagao, paisa kamao',
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 13,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.3,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _gradientLine(toRight: false),
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff18B6A3).withOpacity(pulseT),
              ),
            ),
            _gradientLine(toRight: true),
          ],
        ),
      ],
    );
  }

  Widget _gradientLine({required bool toRight}) {
    return Container(
      width: 36,
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: toRight
              ? [const Color(0xff18B6A3), Colors.transparent]
              : [Colors.transparent, const Color(0xff18B6A3)],
        ),
      ),
    );
  }

  // ── LOGIN CARD ──────────────────────────────────────────────────────────────
  Widget _buildLoginCard(double pulseT) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xff18B6A3).withOpacity(0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xff18B6A3).withOpacity(0.08),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Back',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to continue',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 28),

          _buildField(
            controller: _emailController,
            hint: 'Email or Username',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          _buildField(
            controller: _passwordController,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.black38,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: GestureDetector(
              onTap: _isLoading ? null : _login,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff18B6A3), Color(0xff0e9a89)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff18B6A3).withOpacity(0.45 * pulseT),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
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

  // ── TEXT FIELD ──────────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xff18B6A3).withOpacity(0.18),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black, fontSize: 14),
        cursorColor: const Color(0xff18B6A3),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.35),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: const Color(0xff18B6A3), size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // ── SIGN UP ROW ─────────────────────────────────────────────────────────────
  Widget _buildSignupRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?  ",
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/signup'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xff18B6A3).withOpacity(0.5),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Sign Up',
              style: TextStyle(
                color: Color(0xff18B6A3),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── PARTICLE PAINTER ──────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double t;
  _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const seeds = [
      [0.10, 0.10], [0.88, 0.07], [0.32, 0.20], [0.70, 0.33],
      [0.06, 0.48], [0.94, 0.55], [0.22, 0.72], [0.78, 0.78],
      [0.50, 0.90], [0.42, 0.04], [0.62, 0.62], [0.16, 0.86],
    ];

    for (int i = 0; i < seeds.length; i++) {
      final phase = (t + i * 0.083) % 1.0;
      final y = (seeds[i][1] - phase * 0.15 + 1.0) % 1.0;
      final opacity = (sin(phase * pi) * 0.5).clamp(0.0, 0.5);
      final radius = 1.2 + (i % 3) * 0.9;
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