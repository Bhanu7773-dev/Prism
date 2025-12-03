import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _locationEnabled = false;
  bool _isRequestingPermission = false;

  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _parallaxController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _parallaxController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    final permission = await Geolocator.checkPermission();
    setState(() {
      _locationEnabled = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    });
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _isRequestingPermission = true);

    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please enable location services',
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        setState(() => _isRequestingPermission = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please enable location in settings',
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
      }

      setState(() {
        _locationEnabled = permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;
      });
    } finally {
      setState(() => _isRequestingPermission = false);
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _parallaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _parallaxController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xFF1a1a2e),
                        const Color(0xFF16213e),
                        _parallaxController.value,
                      )!,
                      Color.lerp(
                        const Color(0xFF0f3460),
                        const Color(0xFF1a1a2e),
                        _parallaxController.value,
                      )!,
                      const Color(0xFF0a0a15),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),

          // Floating particles
          ..._buildFloatingParticles(),

          // Page content
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              HapticFeedback.lightImpact();
            },
            children: [
              _buildWelcomePage(),
              _buildLocationPage(),
            ],
          ),

          // Page indicator & navigation
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Page dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(2, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: _currentPage == index
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 30),

                // Navigation button
                if (_currentPage == 0)
                  _buildGlassButton(
                    text: 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    onTap: () {
                      _pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                      );
                    },
                  )
                else
                  _buildGlassButton(
                    text: _locationEnabled ? 'Get Started' : 'Skip for Now',
                    icon: _locationEnabled
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    onTap: _completeOnboarding,
                    isPrimary: _locationEnabled,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingParticles() {
    final random = math.Random(42);
    return List.generate(20, (index) {
      final size = 2.0 + random.nextDouble() * 4;
      final left = random.nextDouble() * MediaQuery.of(context).size.width;
      final top = random.nextDouble() * MediaQuery.of(context).size.height;
      final delay = random.nextInt(3000);

      return Positioned(
        left: left,
        top: top,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final offset = math.sin(_floatController.value * math.pi * 2 +
                    index * 0.5) *
                20;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1 + random.nextDouble() * 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: size * 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ).animate(delay: Duration(milliseconds: delay)).fadeIn(
            duration: const Duration(milliseconds: 800),
          );
    });
  }

  Widget _buildWelcomePage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // 3D Paper cutout weather icon
            _build3DCutoutIcon(
              child: _buildWeatherIconGroup(),
            ),

            const SizedBox(height: 50),

            // Title with shimmer
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.8),
                  Colors.white,
                ],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(bounds),
              child: Text(
                'Welcome to Prism',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 300.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 16),

            Text(
              'Experience weather like never before.\nBeautiful, immersive, and precise.',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 500.ms)
                .slideY(begin: 0.3, end: 0),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // 3D Paper cutout location icon
            _build3DCutoutIcon(
              child: _buildLocationIconGroup(),
            ),

            const SizedBox(height: 50),

            Text(
              'Enable Location',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 300.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 16),

            Text(
              'Allow location access to get accurate\nweather updates for your area.',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 500.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 40),

            // Location enable button
            _buildLocationButton(),

            // Status indicator
            if (_locationEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Location enabled',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
              ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _build3DCutoutIcon({required Widget child}) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) {
        final floatOffset = math.sin(_floatController.value * math.pi) * 8;
        final rotateX = math.sin(_floatController.value * math.pi) * 0.05;
        final rotateY = math.cos(_floatController.value * math.pi * 0.5) * 0.05;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateX(rotateX)
            ..rotateY(rotateY)
            ..translate(0.0, floatOffset, 0.0),
          alignment: Alignment.center,
          child: child,
        );
      },
    ).animate().fadeIn(duration: 800.ms).scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          curve: Curves.elasticOut,
          duration: 1200.ms,
        );
  }

  Widget _buildWeatherIconGroup() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 180 + _pulseController.value * 20,
                height: 180 + _pulseController.value * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1 - _pulseController.value * 0.05),
                    width: 2,
                  ),
                ),
              );
            },
          ),

          // Glass container
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Paper cutout layers
          _buildPaperCutoutLayer(
            offset: const Offset(0, 0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Sun
                Positioned(
                  top: 35,
                  right: 40,
                  child: _buildCutoutShape(
                    size: 50,
                    color: const Color(0xFFFFD700),
                    shadowColor: const Color(0xFFFF8C00),
                    isCircle: true,
                  ),
                ),

                // Cloud 1
                Positioned(
                  top: 50,
                  left: 30,
                  child: _buildCutoutCloud(width: 70, height: 35),
                ),

                // Cloud 2
                Positioned(
                  bottom: 50,
                  right: 35,
                  child: _buildCutoutCloud(width: 55, height: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationIconGroup() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse rings
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + _pulseController.value * 0.3 + index * 0.15;
                final opacity = (1.0 - _pulseController.value) * (0.3 - index * 0.08);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue.withOpacity(opacity.clamp(0.0, 1.0)),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Glass container
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Paper cutout location pin
          _buildPaperCutoutLayer(
            offset: const Offset(0, -5),
            child: _buildCutoutLocationPin(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperCutoutLayer({
    required Offset offset,
    required Widget child,
  }) {
    return Transform.translate(
      offset: offset,
      child: child,
    );
  }

  Widget _buildCutoutShape({
    required double size,
    required Color color,
    required Color shadowColor,
    bool isCircle = false,
  }) {
    return Stack(
      children: [
        // Deep shadow (3D depth)
        Transform.translate(
          offset: const Offset(3, 4),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              color: Colors.black.withOpacity(0.3),
              borderRadius: isCircle ? null : BorderRadius.circular(8),
            ),
          ),
        ),

        // Color shadow
        Transform.translate(
          offset: const Offset(1, 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              color: shadowColor.withOpacity(0.5),
              borderRadius: isCircle ? null : BorderRadius.circular(8),
            ),
          ),
        ),

        // Main shape
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            color: color,
            borderRadius: isCircle ? null : BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
        ),

        // Highlight
        Positioned(
          top: size * 0.15,
          left: size * 0.15,
          child: Container(
            width: size * 0.3,
            height: size * 0.15,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size),
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCutoutCloud({required double width, required double height}) {
    return Stack(
      children: [
        // Shadow
        Transform.translate(
          offset: const Offset(3, 4),
          child: CustomPaint(
            size: Size(width, height),
            painter: _CloudPainter(color: Colors.black.withOpacity(0.2)),
          ),
        ),

        // Main cloud
        CustomPaint(
          size: Size(width, height),
          painter: _CloudPainter(color: Colors.white),
        ),

        // Highlight
        Positioned(
          top: height * 0.2,
          left: width * 0.15,
          child: Container(
            width: width * 0.25,
            height: height * 0.2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCutoutLocationPin() {
    const pinWidth = 60.0;
    const pinHeight = 80.0;

    return SizedBox(
      width: pinWidth + 10,
      height: pinHeight + 10,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shadow
          Transform.translate(
            offset: const Offset(4, 5),
            child: CustomPaint(
              size: const Size(pinWidth, pinHeight),
              painter: _LocationPinPainter(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),

          // Color shadow
          Transform.translate(
            offset: const Offset(2, 3),
            child: CustomPaint(
              size: const Size(pinWidth, pinHeight),
              painter: _LocationPinPainter(
                color: Colors.blue.shade900.withOpacity(0.5),
              ),
            ),
          ),

          // Main pin
          CustomPaint(
            size: const Size(pinWidth, pinHeight),
            painter: _LocationPinPainter(
              color: Colors.blue.shade500,
              showGradient: true,
            ),
          ),

          // Inner circle
          Positioned(
            top: 18,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),

          // Highlight
          Positioned(
            top: 12,
            left: 18,
            child: Container(
              width: 12,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationButton() {
    return GestureDetector(
      onTap: _isRequestingPermission || _locationEnabled
          ? null
          : _requestLocationPermission,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _locationEnabled
                ? [Colors.green.shade600, Colors.green.shade700]
                : [Colors.blue.shade500, Colors.blue.shade700],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_locationEnabled ? Colors.green : Colors.blue)
                  .withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRequestingPermission)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            else
              Icon(
                _locationEnabled
                    ? Icons.check_rounded
                    : Icons.location_on_rounded,
                color: Colors.white,
                size: 22,
              ),
            const SizedBox(width: 12),
            Text(
              _locationEnabled ? 'Location Enabled' : 'Enable Location',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 700.ms)
        .slideY(begin: 0.3, end: 0);
  }

  Widget _buildGlassButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPrimary
                    ? [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                      ]
                    : [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(isPrimary ? 0.4 : 0.2),
              ),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 800.ms).slideY(begin: 0.3, end: 0);
  }
}

// Custom painters

class _CloudPainter extends CustomPainter {
  final Color color;

  _CloudPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Cloud shape using circles
    final baseY = size.height * 0.7;

    // Left bump
    path.addOval(Rect.fromCenter(
      center: Offset(size.width * 0.25, baseY),
      width: size.width * 0.4,
      height: size.height * 0.5,
    ));

    // Middle bump (taller)
    path.addOval(Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.45),
      width: size.width * 0.5,
      height: size.height * 0.7,
    ));

    // Right bump
    path.addOval(Rect.fromCenter(
      center: Offset(size.width * 0.75, baseY),
      width: size.width * 0.4,
      height: size.height * 0.5,
    ));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LocationPinPainter extends CustomPainter {
  final Color color;
  final bool showGradient;

  _LocationPinPainter({required this.color, this.showGradient = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    if (showGradient) {
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color,
          Color.lerp(color, Colors.black, 0.3)!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      paint.color = color;
    }

    final path = Path();

    // Pin shape
    final centerX = size.width / 2;
    final topRadius = size.width * 0.5;
    final bottomY = size.height;

    // Top circle
    path.addArc(
      Rect.fromCircle(center: Offset(centerX, topRadius), radius: topRadius),
      math.pi,
      math.pi,
    );

    // Right side curve to point
    path.quadraticBezierTo(
      size.width,
      size.height * 0.5,
      centerX,
      bottomY,
    );

    // Left side curve from point
    path.quadraticBezierTo(
      0,
      size.height * 0.5,
      0,
      topRadius,
    );

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
