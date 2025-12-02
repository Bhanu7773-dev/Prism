import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../widgets/layered_background.dart';
import '../widgets/weather_hero.dart';
import '../widgets/glass_bottom_sheet.dart';
import '../widgets/glass_container.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _weatherService = WeatherService();
  Weather? _weather;
  ForecastData? _forecastData;
  String? _locationName;
  bool _isLoading = true;
  String _errorMessage = '';

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  double _sheetPosition = 0.45;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    try {
      // 1. Get permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'Location permissions are permanently denied, we cannot request permissions.';
          _isLoading = false;
        });
        return;
      }

      // 2. Get location (Try last known first for speed)
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Fetch all data in parallel
      final results = await Future.wait([
        _weatherService.getWeatherByCoordinates(
          position.latitude,
          position.longitude,
        ),
        _weatherService.getForecast(position.latitude, position.longitude),
        placemarkFromCoordinates(position.latitude, position.longitude)
            .then(
              (placemarks) => placemarks.isNotEmpty ? placemarks.first : null,
            )
            .catchError((_) => null), // Handle geocoding error gracefully
      ]);

      final weather = results[0] as Weather;
      final forecast = results[1] as ForecastData;
      final placemark = results[2] as Placemark?;

      if (placemark != null) {
        _locationName =
            placemark.locality ??
            placemark.subAdministrativeArea ??
            placemark.administrativeArea;
      }

      setState(() {
        _weather = weather;
        _forecastData = forecast;
        _locationName ??= weather.cityName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI to edge-to-edge for transparency
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Animation Progress (0.0 at min extent, 1.0 at max extent)
    // min=0.45, max=0.88 -> range=0.43
    // final t = ((_sheetPosition - 0.45) / 0.43).clamp(0.0, 1.0); // Removed from here

    // Screen dimensions
    final size = MediaQuery.of(context).size;

    // Start Position (Center)
    final startTop = size.height * 0.15; // Adjusted for new layout
    final startLeft = 0.0;
    final startRight = 0.0; // Centered

    // End Position (Top Left Pill)
    final endTop = 50.0; // Align with location pill
    final endLeft = 20.0;

    // Interpolation
    // We'll use a custom Positioned for the WeatherHero content

    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent keyboard push
      body: Stack(
        children: [
          // 1. Background
          const LayeredBackground(),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 18),
                ),
              ),
            )
          else ...[
            // 4. The Glass Sheet (Bottom) - Now behind the pills
            GlassBottomSheet(
              controller: _sheetController,
              forecastData: _forecastData,
              currentWeather: _weather,
            ),

            // Animated Header Elements
            AnimatedBuilder(
              animation: _sheetController,
              builder: (context, child) {
                // Calculate t based on current sheet size
                // min=0.45, max=0.88 -> range=0.43
                final currentSize = _sheetController.isAttached
                    ? _sheetController.size
                    : 0.45;
                final t = ((currentSize - 0.45) / 0.43).clamp(0.0, 1.0);

                // Define Styles
                final largeStyle = GoogleFonts.outfit(
                  fontSize: 120,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(4, 4),
                      blurRadius: 10,
                    ),
                  ],
                );

                final smallStyle = GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.0,
                  shadows: [],
                );

                final currentStyle = TextStyle.lerp(largeStyle, smallStyle, t);

                return Stack(
                  children: [
                    // 3. Condition Text (Fades out in place)
                    Positioned(
                      top: startTop + 130, // Position below the temperature
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: (1.0 - t * 3).clamp(
                          0.0,
                          1.0,
                        ), // Fade out quickly
                        child: Center(
                          child: Text(
                            _weather?.condition ?? 'Loading...',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                              color: Colors.white.withOpacity(0.8),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 5. Location Pill (Top Center) - Always Visible & On Top
                    Positioned(
                      top: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 160,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _locationName?.toUpperCase() ?? 'UNKNOWN',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 6. Animated Weather Hero (Temp Only) - On Top
                    // We move this from center to top-left
                    Positioned(
                      top: lerpDouble(startTop, endTop, t), // Move up
                      left: lerpDouble(startLeft, endLeft, t), // Move left
                      right: 0, // Keep full width to allow Align to work
                      child: Align(
                        alignment: Alignment.lerp(
                          Alignment.center,
                          Alignment.centerLeft,
                          t,
                        )!,
                        child: Builder(
                          builder: (context) {
                            Widget content = Container(
                              height: t > 0.8 ? 40 : null, // Match pill height
                              padding: EdgeInsets.symmetric(
                                horizontal: t > 0.8 ? 16 : 0,
                                vertical: t > 0.8 ? 0 : 0,
                              ),
                              decoration: t > 0.8
                                  ? BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    )
                                  : null,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Temperature
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Ghost character for alignment (only when centered)
                                      if (t < 0.5)
                                        Text(
                                          '°',
                                          style: currentStyle?.copyWith(
                                            color: Colors.transparent,
                                            shadows: [],
                                          ),
                                        ),
                                      Text(
                                        _weather?.temperature
                                                .round()
                                                .toString() ??
                                            '--',
                                        style: currentStyle,
                                      ),
                                      Text('°', style: currentStyle),
                                    ],
                                  ),
                                ],
                              ),
                            );

                            // Only clip and blur when forming the pill (t > 0.6)
                            // This prevents the large text shadow from being clipped
                            if (t > 0.6) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: t > 0.8 ? 10 : 0,
                                    sigmaY: t > 0.8 ? 10 : 0,
                                  ),
                                  child: content,
                                ),
                              );
                            } else {
                              return content;
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
