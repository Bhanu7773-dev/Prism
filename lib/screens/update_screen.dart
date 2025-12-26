import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/update_service.dart';
import '../widgets/glass_container.dart'; // Reuse for consistent style

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  final UpdateService _updateService = UpdateService();

  bool _isLoading = true;
  ReleaseInfo? _releaseInfo;
  String _currentVersion = '';

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;

      final release = await _updateService.checkForUpdate();

      if (mounted) {
        setState(() {
          _releaseInfo = release;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to check for updates.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startDownload() async {
    if (_releaseInfo == null) return;

    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    try {
      await _updateService.downloadUpdate(
        _releaseInfo!.downloadUrl,
        _releaseInfo!.fileName,
        (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      // Download finished logic is handled by service calling install
      // But we can reset UI state if user cancels install and comes back
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 1.0;
        });

        // Show snackbar prompting to install if it didn't auto-open
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Download complete. Installing...")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Download failed. Please check internet.";
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      body: Stack(
        children: [
          // Background Gradient (Simplified version of Home)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F2027),
                    Color(0xFF203A43),
                    Color(0xFF2C5364),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Software Update",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.outfit(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _checkForUpdates();
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_releaseInfo == null) {
      // Up to date
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.greenAccent,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              "Your system is up to date",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Version $_currentVersion",
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Update Available
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graphic
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update,
                color: Colors.blueAccent,
                size: 50,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            "New Update Available",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              _buildVersionTag("Current: $_currentVersion", Colors.white24),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_right_alt, color: Colors.white54),
              const SizedBox(width: 12),
              _buildVersionTag(
                "Latest: ${_releaseInfo!.version}",
                Colors.blueAccent,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Changelog
          Text(
            "What's New",
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GlassContainer(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child:
                  _releaseInfo!.changelog.contains("Developer didn't specify")
                  ? Center(
                      child: Text(
                        _releaseInfo!.changelog,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        _releaseInfo!.changelog,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Button
          if (_isDownloading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Downloading...",
                      style: GoogleFonts.outfit(color: Colors.white70),
                    ),
                    Text(
                      "${(_downloadProgress * 100).toInt()}%",
                      style: GoogleFonts.outfit(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _downloadProgress,
                  backgroundColor: Colors.white10,
                  color: Colors.blueAccent,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _startDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Download & Install",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVersionTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
