import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../services/wind_data_service.dart';
import '../services/weather_service.dart';
import '../widgets/wind_particle_painter.dart';

class WindMapScreen extends StatefulWidget {
  const WindMapScreen({super.key});

  @override
  State<WindMapScreen> createState() => _WindMapScreenState();
}

class _WindMapScreenState extends State<WindMapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final WindDataService _windService = WindDataService();
  final WeatherService _weatherService = WeatherService();

  late AnimationController _animationController;
  final List<Particle> _particles = [];

  // Updated State: WindGrid instead of List<WindPoint>
  WindGrid? _windGrid;

  Rect _currentMapBounds = Rect.zero;
  LatLng? _userLocation;
  LatLng? _selectedPinLocation;
  bool _isLoading = true;
  String _windInfo = "-- km/h";
  String _windDir = "";
  String _locationName = "Locating...";

  final Color _particleColor = Colors.white;

  @override
  void initState() {
    super.initState();
    // 800 Light Particles for high detail
    for (int i = 0; i < 800; i++)
      _particles.add(Particle()..life = 20 + Random().nextInt(100));

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(hours: 1),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locateUser();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _locateUser() async {
    setState(() {
      _selectedPinLocation = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          final latLng = LatLng(lastKnown.latitude, lastKnown.longitude);
          setState(() {
            _userLocation = latLng;
          });
          _mapController.move(latLng, 6.0);
          _updateData();
        }

        final pos = await Geolocator.getCurrentPosition();
        final latLng = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _userLocation = latLng;
        });
        if (lastKnown == null) {
          _mapController.move(latLng, 6.0);
          _updateData();
        }
      }
    } catch (e) {
      debugPrint("Location Error: $e");
    }

    if (_userLocation == null) _updateData();
  }

  Future<void> _updateData() async {
    // Debounce check: If dragging, maybe skip?
    // But since we optimizing, it should be fine.

    setState(() => _isLoading = true);
    final center = _mapController.camera.center;
    final bounds = _mapController.camera.visibleBounds;
    double span = (bounds.east - bounds.west).abs();
    if (span > 180) span = 360 - span;

    try {
      final grid = await _windService.fetchWindGrid(
        center.latitude,
        center.longitude,
        span,
      );

      LatLng target = _selectedPinLocation ?? _userLocation ?? center;

      // Lookup logic for Header Label (Nearest Neighbor)
      WindPoint nearest = grid.points[0];
      double minDist = 99999;
      for (var p in grid.points) {
        double d =
            (p.lat - target.latitude).abs() + (p.lon - target.longitude).abs();
        if (d < minDist) {
          minDist = d;
          nearest = p;
        }
      }

      String dir = _getCardinalDirection(nearest.direction);

      setState(() {
        _windGrid = grid;
        _currentMapBounds = Rect.fromLTWH(
          bounds.west,
          bounds.north,
          (bounds.east - bounds.west),
          (bounds.north - bounds.south),
        );
        _windInfo = "${nearest.speed.toStringAsFixed(1)} km/h";
        _windDir = dir;
        _isLoading = false;
      });

      // Fetch Location Name
      try {
        final weather = await _weatherService.getWeatherByCoordinates(
          target.latitude,
          target.longitude,
        );
        if (mounted) {
          setState(() {
            _locationName = weather.cityName;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _locationName = "Unknown Location");
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _onMapTap(TapPosition tapPos, LatLng point) {
    setState(() {
      _selectedPinLocation = point;
      if (_windGrid != null && !_windGrid!.isEmpty) {
        WindPoint nearest = _windGrid!.points[0];
        double minDist = 99999;
        for (var p in _windGrid!.points) {
          double d =
              (p.lat - point.latitude).abs() + (p.lon - point.longitude).abs();
          if (d < minDist) {
            minDist = d;
            nearest = p;
          }
        }
        _windInfo = "${nearest.speed.toStringAsFixed(1)} km/h";
        _windDir = _getCardinalDirection(nearest.direction);
      }
    });
  }

  String _getCardinalDirection(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    int index = ((bearing + 22.5) % 360) ~/ 45;
    return directions[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      body: Stack(
        children: [
          // 1. Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(20.0, 0.0),
              initialZoom: 4.0,
              minZoom: 2.0,
              onTap: _onMapTap,
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) _updateData();
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.dark.prism',
              ),

              // Labels
              ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  1.3,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1.3,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1.3,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/dark_only_labels/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.dark.prism',
                ),
              ),

              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 24,
                      height: 24,
                      child: _buildUserMarker(),
                    ),

                  if (_selectedPinLocation != null)
                    Marker(
                      point: _selectedPinLocation!,
                      width: 32,
                      height: 32,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 32,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // 2. Particles
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                // Dynamic Particle Scaling based on Zoom
                double zoom = _mapController.camera.zoom;
                // Scale from Zoom 3 (200 particles) to Zoom 8 (800 particles)
                double t = ((zoom - 3.0) / (8.0 - 3.0)).clamp(0.0, 1.0);
                int activeCount = (200 + (600 * t))
                    .round(); // 200 + max 600 = 800

                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: WindParticlePainter(
                    particles: _particles.take(activeCount).toList(),
                    windGrid: _windGrid, // Pass grid object
                    mapBounds: _currentMapBounds,
                    color: _particleColor,
                  ),
                );
              },
            ),
          ),

          // 3. Header
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                _buildAcrylicButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _locationName.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    letterSpacing: 1.0,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  _windInfo,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                _windDir,
                                style: GoogleFonts.outfit(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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
          ),

          // 4. Controls
          Positioned(
            bottom: 40,
            right: 20,
            child: Column(
              children: [
                _buildAcrylicButton(
                  icon: Icons.my_location,
                  onTap: () {
                    setState(() {
                      _selectedPinLocation = null;
                    });
                    if (_userLocation != null) {
                      _mapController.move(_userLocation!, 10.0);
                      _updateData();
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildAcrylicButton(
                  icon: Icons.refresh,
                  onTap: _updateData,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcrylicButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  )
                : Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildUserMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
