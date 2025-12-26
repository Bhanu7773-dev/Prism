import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/wind_data_service.dart';
import '../widgets/wind_particle_painter.dart';
import '../screens/wind_map_screen.dart';

class MiniWindMap extends StatefulWidget {
  final double latitude;
  final double longitude;

  const MiniWindMap({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<MiniWindMap> createState() => _MiniWindMapState();
}

class _MiniWindMapState extends State<MiniWindMap>
    with SingleTickerProviderStateMixin {
  final WindDataService _windService = WindDataService();
  late AnimationController _animationController;
  final List<Particle> _particles = [];
  WindGrid? _windGrid;

  // Use a simplified map controller just to set initial center
  final MapController _mapController = MapController();

  // Bounds for the simplified view
  // Since we don't interact, we can estimate bounds based on zoom 4 like the main map
  // or just use logic in painter. Painter needs rect.
  Rect _mapBounds = Rect.zero;

  @override
  void initState() {
    super.initState();
    // More particles for mini map detail
    for (int i = 0; i < 150; i++)
      _particles.add(Particle()..life = 20 + Random().nextInt(80));

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(hours: 1),
    )..repeat();

    // Fetch data immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void didUpdateWidget(MiniWindMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      // Location changed, move map and refresh data
      _mapController.move(LatLng(widget.latitude, widget.longitude), 3.0);
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    // 30 degrees span roughly matches Zoom 4
    try {
      final grid = await _windService.fetchWindGrid(
        widget.latitude,
        widget.longitude,
        40.0,
      );
      if (mounted) {
        setState(() {
          _windGrid = grid;
          // Approximate bounds if we assume the widget fills some box.
          // However, the Painter needs LAT/LON bounds vs SCREEN bounds mapping.
          // We can grab this from the map controller if we wait for map ready
          // OR we can just hardcode bounds around center since we know the span.
          // Standard Mercator projection:
          // We will rely on onMapEvent or just LayoutBuilder with map bounds.
        });
      }
    } catch (e) {
      debugPrint("MiniWindMap Error: $e");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [

            RepaintBoundary(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(widget.latitude, widget.longitude),
                  initialZoom: 3.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ), // Static
                  onMapReady: () {
                    // Once map is ready, we can get bounds if needed,
                    // but for now we just rely on grid fetching done in init.
                    // To get accurate bounds for painter, we need the map controller's bounds.
                    _updateBounds();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.dark.prism.mini',
                  ),
                  // Labels (Simple Bright)
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
                      userAgentPackageName: 'com.dark.prism.mini',
                    ),
                  ),

                  // Marker (Location Dot)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(widget.latitude, widget.longitude),
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),


            RepaintBoundary(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // Update bounds if controller valid
                    if (_windGrid != null) {
                      final bounds = _mapController.camera.visibleBounds;
                      _mapBounds = Rect.fromLTWH(
                        bounds.west,
                        bounds.north,
                        bounds.east - bounds.west,
                        bounds.north - bounds.south,
                      );
                    }

                    return CustomPaint(
                      size: MediaQuery.of(context).size,
                      painter: WindParticlePainter(
                        particles: _particles,
                        windGrid: _windGrid,
                        mapBounds: _mapBounds,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    );
                  },
                ),
              ),
            ),


              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.air, color: Colors.blueAccent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "LIVE WIND",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Full Screen Button
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WindMapScreen()),
                    );
                  },
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateBounds() {
    if (mounted) setState(() {});
  }
}
