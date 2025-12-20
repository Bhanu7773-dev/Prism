import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/widget_service.dart';
import '../widgets/layered_background.dart';
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
  bool _isCelsius = true;
  bool _isBackgroundPaused = false;
  bool _isSheetVisible = true;
  int _modalCount = 0;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  double _sheetPosition = 0.45;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _sheetController.addListener(_onSheetMove);
  }

  void _onSheetMove() {
    // Pause background if the sheet is being moved from its base position (0.45)
    // or if it's near the top where we want maximum performance for the Hero transition.
    final position = _sheetController.size;
    final shouldPause = position > 0.46 || position < 0.44;

    if (_isBackgroundPaused != shouldPause) {
      setState(() {
        _isBackgroundPaused = shouldPause;
      });
    }
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

      // Update home screen widget with new weather data
      WidgetService.updateWidgetData(
        weather,
        _locationName ?? weather.cityName,
        forecast: forecast,
      );
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
          // 1. Background with dynamic day/night based on selected city
          LayeredBackground(
            sunrise: _weather?.sunrise,
            sunset: _weather?.sunset,
            currentTime: _weather?.localTime,
            weatherCondition: _weather?.condition,
            conditionCode: _weather?.conditionCode,
            temperature: _weather?.temperature,
            humidity: _weather?.humidity.toDouble(),
            windSpeed: _weather?.windSpeed,
            pauseAnimation: _isBackgroundPaused,
          ),

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
            Visibility(
              visible: _isSheetVisible,
              maintainState:
                  false, // Ensure it's fully unmounted for performance
              child: GlassBottomSheet(
                controller: _sheetController,
                forecastData: _forecastData,
                currentWeather: _weather,
              ),
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
                      child: Visibility(
                        visible: _isSheetVisible,
                        maintainState: false,
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
                    ),

                    // 5. Location Pill (Top Center) - Always Visible & On Top
                    Positioned(
                      top: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GlassContainer(
                          width: 140, // Reduced from 160 to prevent overlap
                          height: 40,
                          blur: 20, // Restored blur to match bottom sheet
                          opacity: 0.1,
                          borderRadius: BorderRadius.circular(30),
                          padding: EdgeInsets.zero,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _locationName?.toUpperCase() ?? 'UNKNOWN',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Menu Pill (Top Right) - Three dots
                    Positioned(
                      top: 50,
                      right: 20,
                      child: GestureDetector(
                        onTap: () => _showSettingsSheet(context),
                        child: GlassContainer(
                          width: 44,
                          height: 44,
                          blur: 20, // Restored blur to match bottom sheet
                          opacity: 0.1,
                          borderRadius: BorderRadius.circular(22),
                          padding: EdgeInsets.zero,
                          child: Icon(
                            Icons.more_horiz,
                            color: Colors.white.withOpacity(0.8),
                            size: 24,
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
                      child: Visibility(
                        visible: _isSheetVisible,
                        maintainState: false,
                        child: IgnorePointer(
                          // Prevent this large, full-width animated widget from
                          // intercepting taps so top-right controls remain tappable.
                          ignoring: true,
                          child: Align(
                            alignment: Alignment.lerp(
                              Alignment.center,
                              Alignment.centerLeft,
                              t,
                            )!,
                            child: Builder(
                              builder: (context) {
                                Widget content = Container(
                                  height: t > 0.8
                                      ? 40
                                      : null, // Match pill height
                                  padding: EdgeInsets.symmetric(
                                    horizontal: t > 0.8 ? 16 : 0,
                                    vertical: t > 0.8 ? 0 : 0,
                                  ),
                                  decoration: null,
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
                                            _weather != null
                                                ? _formatTemperature(
                                                    _weather!.temperature,
                                                  )
                                                : '--',
                                            style: currentStyle,
                                          ),
                                          Text('°', style: currentStyle),
                                        ],
                                      ),
                                    ],
                                  ),
                                );

                                // Only wrap in GlassContainer when forming the pill (t > 0.6)
                                if (t > 0.6) {
                                  return GlassContainer(
                                    blur:
                                        20, // Restored blur to match bottom sheet
                                    opacity: 0.1,
                                    borderRadius: BorderRadius.circular(30),
                                    padding: t > 0.8
                                        ? const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          )
                                        : EdgeInsets.zero,
                                    child: content,
                                  );
                                } else {
                                  return content;
                                }
                              },
                            ),
                          ),
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

  void _showSettingsSheet(BuildContext context) {
    setState(() {
      _isBackgroundPaused = true;
      _isSheetVisible = false;
      _modalCount++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) => RepaintBoundary(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag Handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'Settings',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Temperature Unit Toggle
                      _buildSettingsTile(
                        icon: Icons.thermostat,
                        title: 'Temperature Unit',
                        trailing: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setSheetState(() {});
                                  setState(() => _isCelsius = true);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isCelsius
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '°C',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: _isCelsius
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setSheetState(() {});
                                  setState(() => _isCelsius = false);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_isCelsius
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '°F',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: !_isCelsius
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Manual Location Search
                      _buildSettingsTile(
                        icon: Icons.search,
                        title: 'Search Location',
                        subtitle: 'Find weather for any city',
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showLocationSearch(context);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Current Location
                      _buildSettingsTile(
                        icon: Icons.my_location,
                        title: 'Use Current Location',
                        subtitle: 'Get weather for your location',
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _fetchWeather();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Developer Info
                      _buildSettingsTile(
                        icon: Icons.code,
                        title: 'Developer',
                        subtitle: 'Bhanu',
                      ),
                      const SizedBox(height: 16),

                      // App Version
                      _buildSettingsTile(
                        icon: Icons.info_outline,
                        title: 'App Version',
                        subtitle: 'v1.0.0',
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ).then((_) {
        if (!mounted) return;
        setState(() {
          _modalCount--;
          if (_modalCount <= 0) {
            _modalCount = 0;
            _isBackgroundPaused = false;
            _isSheetVisible = true;
          }
        });
      });
    });
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void _showLocationSearch(BuildContext context) {
    setState(() {
      _isBackgroundPaused = true;
      _isSheetVisible = false;
      _modalCount++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final searchController = TextEditingController();
      List<CityResult> suggestions = [];
      bool isSearching = false;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag Handle
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Search Location',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Search Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: TextField(
                            controller: searchController,
                            style: GoogleFonts.outfit(color: Colors.white),
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Enter city name...',
                              hintStyle: GoogleFonts.outfit(
                                color: Colors.white.withOpacity(0.5),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              suffixIcon: isSearching
                                  ? Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    )
                                  : searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                      onPressed: () {
                                        searchController.clear();
                                        setSheetState(() {
                                          suggestions = [];
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            onChanged: (value) async {
                              if (value.length >= 2) {
                                setSheetState(() => isSearching = true);
                                try {
                                  final results = await _weatherService
                                      .searchCities(value);
                                  setSheetState(() {
                                    suggestions = results;
                                    isSearching = false;
                                  });
                                } catch (e) {
                                  setSheetState(() => isSearching = false);
                                }
                              } else {
                                setSheetState(() {
                                  suggestions = [];
                                });
                              }
                            },
                            onSubmitted: (value) {
                              if (suggestions.isNotEmpty) {
                                _selectCity(suggestions.first);
                                Navigator.pop(context);
                              } else if (value.isNotEmpty) {
                                Navigator.pop(context);
                                _searchAndSetLocation(value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Search Results
                        if (suggestions.isNotEmpty)
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: suggestions.length,
                              itemBuilder: (context, index) {
                                final city = suggestions[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _selectCity(city);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          color: Colors.white.withOpacity(0.6),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                city.name,
                                                style: GoogleFonts.outfit(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (city.state != null ||
                                                  city.country.isNotEmpty)
                                                Text(
                                                  [
                                                    if (city.state != null)
                                                      city.state,
                                                    city.country,
                                                  ].join(', '),
                                                  style: GoogleFonts.outfit(
                                                    color: Colors.white
                                                        .withOpacity(0.5),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        // Empty state
                        if (suggestions.isEmpty &&
                            searchController.text.length >= 2 &&
                            !isSearching)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No cities found',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ).then((_) {
        if (!mounted) return;
        setState(() {
          _modalCount--;
          if (_modalCount <= 0) {
            _modalCount = 0;
            _isBackgroundPaused = false;
            _isSheetVisible = true;
          }
        });
      });
    });
  }

  Future<void> _selectCity(CityResult city) async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _weatherService.getWeatherByCoordinates(city.lat, city.lon),
        _weatherService.getForecast(city.lat, city.lon),
      ]);

      final weather = results[0] as Weather;
      final forecast = results[1] as ForecastData;

      setState(() {
        _weather = weather;
        _forecastData = forecast;
        _locationName = city.name;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load weather';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchAndSetLocation(String query) async {
    setState(() => _isLoading = true);

    try {
      // Use geocoding to find the location
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;

        // Fetch weather for this location
        final results = await Future.wait([
          _weatherService.getWeatherByCoordinates(
            location.latitude,
            location.longitude,
          ),
          _weatherService.getForecast(location.latitude, location.longitude),
        ]);

        final weather = results[0] as Weather;
        final forecast = results[1] as ForecastData;

        setState(() {
          _weather = weather;
          _forecastData = forecast;
          _locationName = query;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Location not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to find location';
        _isLoading = false;
      });
    }
  }

  String _formatTemperature(double celsius) {
    if (_isCelsius) {
      return '${celsius.round()}';
    } else {
      return '${((celsius * 9 / 5) + 32).round()}';
    }
  }
}
