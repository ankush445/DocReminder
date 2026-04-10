import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  late final AnimationController _textController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _logoController,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _logoController,
    curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
  );
  late final Animation<double> _textFade = CurvedAnimation(
    parent: _textController,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _textSlide = Tween(
    begin: const Offset(0, 0.25),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));
  late final Animation<double> _pulse = Tween(begin: 0.85, end: 1.0).animate(
    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _logoController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _textController.forward();
      });
    });

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Stack(
        children: [
          // Radial glow — top right
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.14),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Radial glow — bottom left
          Positioned(
            bottom: -80, left: -60,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.07),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo ──────────────────────────────────────────────
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: ScaleTransition(
                      scale: _pulse,
                      child: Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          color: AppColors.lightBackground2,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              blurRadius: 36,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 60,
                              color: AppColors.primary,
                            ),
                            Positioned(
                              bottom: 16, right: 16,
                              child: Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.lightBackground2,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ── Text block ────────────────────────────────────────
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        Text(
                          'DOCUMENT VAULT',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.4,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 40,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                            children: const [
                              TextSpan(text: 'Doc'),
                              TextSpan(
                                text: 'Reminder',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: 40, height: 1.5,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Never miss a document deadline',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textTertiary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 72),

                // ── Loading dots ──────────────────────────────────────
                FadeTransition(
                  opacity: _textFade,
                  child: _LoadingDots(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = ((_c.value * 3) - i).clamp(0.0, 1.0);
          final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.2, 1.0);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: opacity),
            ),
          );
        }),
      );
    },
  );
}