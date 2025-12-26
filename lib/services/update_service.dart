import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dart:ffi';

class UpdateService {
  static const String _repoOwner = 'Bhanu7773-dev';
  static const String _repoName = 'Prism';

  final Dio _dio = Dio();
  // removed DeviceInfoPlugin

  // Returns null if no update is available, otherwise returns the Release info
  Future<ReleaseInfo?> checkForUpdate() async {
    try {
      final currentPackageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = currentPackageInfo.version;

      // Fetch latest release from GitHub
      final response = await _dio.get(
        'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final String tagName = data['tag_name'];
        final String latestVersion = tagName.startsWith('v')
            ? tagName.substring(1)
            : tagName;

        // Simple version comparison
        if (_isNewerVersion(currentVersion, latestVersion)) {
          final List assets = data['assets'];
          Map<String, dynamic>? apkAsset;

          // Check current running ABI to match the installed APK split
          if (Platform.isAndroid) {
            String? targetAbi;
            final abi = Abi.current();

            if (abi == Abi.androidArm64) {
              targetAbi = 'arm64-v8a';
            } else if (abi == Abi.androidArm) {
              targetAbi = 'armeabi-v7a';
            } else if (abi == Abi.androidX64) {
              targetAbi = 'x86_64';
            }

            if (targetAbi != null) {
              debugPrint("Current Running ABI: $abi, looking for: $targetAbi");

              apkAsset = assets.firstWhere((asset) {
                final name = asset['name'].toString().toLowerCase();
                return name.endsWith('.apk') && name.contains(targetAbi!);
              }, orElse: () => null);
            }
          }

          // Fallback: If no specific match or not Android, try universal or first available
          if (apkAsset == null) {
            apkAsset = assets.firstWhere((asset) {
              final name = asset['name'].toString().toLowerCase();
              return name.endsWith('.apk') &&
                  (name.contains('universal') || !name.contains('-'));
            }, orElse: () => null);
          }

          // Ultimate Fallback: Just grab the first APK found
          apkAsset ??= assets.firstWhere(
            (asset) => asset['name'].toString().endsWith('.apk'),
            orElse: () => null,
          );

          if (apkAsset != null) {
            return ReleaseInfo(
              version: latestVersion,
              changelog:
                  (data['body'] != null && data['body'].toString().isNotEmpty)
                  ? data['body']
                  : 'Developer didn\'t specify',
              downloadUrl: apkAsset['browser_download_url'],
              fileName: apkAsset['name'],
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
    return null;
  }

  // Compare versions like "1.0.0" and "1.0.1"
  bool _isNewerVersion(String current, String latest) {
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> latestParts = latest.split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length; i++) {
        // Current is shorter (e.g. 1.0 vs 1.0.1) -> latest is newer
        if (i >= currentParts.length) return true;

        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
    } catch (e) {
      debugPrint("Version parsing error: $e");
    }
    return false;
  }

  Future<void> downloadUpdate(
    String url,
    String fileName,
    Function(int received, int total) onProgress,
  ) async {
    try {
      final Directory? downloadsDir = await getExternalStorageDirectory();
      // Using external storage directory to ensure the file is readable by the installer
      // For Android 10+ scoped storage, this is usually strictly app-private but OpenFile should handle it via FileProvider

      if (downloadsDir == null)
        throw Exception("Cannot get download directory");

      final String savePath = '${downloadsDir.path}/$fileName';

      await _dio.download(url, savePath, onReceiveProgress: onProgress);

      // Trigger install immediately after download
      await installUpdate(savePath);
    } catch (e) {
      debugPrint('Download error: $e');
      rethrow;
    }
  }

  static const MethodChannel platform = MethodChannel('com.dark.prism/widget');

  Future<void> installUpdate(String filePath) async {
    try {
      await platform.invokeMethod('installApk', {'filePath': filePath});
    } catch (e) {
      debugPrint('Install error: $e');
    }
  }
}

class ReleaseInfo {
  final String version;
  final String changelog;
  final String downloadUrl;
  final String fileName;

  ReleaseInfo({
    required this.version,
    required this.changelog,
    required this.downloadUrl,
    required this.fileName,
  });
}
