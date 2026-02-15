import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String latestVersion;
  final String tagName;
  final String releaseName;
  final String releaseUrl;
  final String? assetName;
  final String? assetDownloadUrl;

  const UpdateInfo({
    required this.latestVersion,
    required this.tagName,
    required this.releaseName,
    required this.releaseUrl,
    required this.assetName,
    required this.assetDownloadUrl,
  });
}

class AppUpdateService extends ChangeNotifier {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  static const String _latestReleaseApi =
      'https://api.github.com/repos/GLLB-Apps/mw_cartracker/releases/latest';
  static const String _installedReleaseTagKey = 'installed_release_tag';

  String? currentVersion;
  UpdateInfo? updateInfo;
  bool isChecking = false;
  bool isDownloading = false;
  String? statusMessage;
  String? lastError;

  bool get hasUpdate => updateInfo != null;

  Future<void> checkForUpdates() async {
    if (isChecking) return;

    isChecking = true;
    lastError = null;
    updateInfo = null;
    statusMessage = 'Checking for updates...';
    notifyListeners();

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final prefs = await SharedPreferences.getInstance();
      final installedTag = prefs.getString(_installedReleaseTagKey);
      final packageVersion = _normalizeVersion(packageInfo.version);
      final installedTagVersion =
          installedTag != null ? _normalizeVersion(installedTag) : '0.0.0';

      // Use the highest known local version source so updater logic does not
      // depend solely on hardcoded pubspec versions.
      currentVersion = _isNewerVersion(installedTagVersion, packageVersion)
          ? installedTagVersion
          : packageVersion;

      final response = await http.get(
        Uri.parse(_latestReleaseApi),
        headers: {'Accept': 'application/vnd.github+json'},
      );

      if (response.statusCode != 200) {
        throw Exception('GitHub API responded with ${response.statusCode}');
      }

      final payload = json.decode(response.body) as Map<String, dynamic>;
      final tagName = (payload['tag_name'] ?? '').toString();
      final releaseName = (payload['name'] ?? tagName).toString();
      final releaseUrl = (payload['html_url'] ?? '').toString();
      final latestVersion = _normalizeVersion(tagName);
      final normalizedCurrentVersion = _normalizeVersion(currentVersion ?? '0.0.0');

      if (_isNewerVersion(latestVersion, normalizedCurrentVersion)) {
        final asset = _selectBestAsset(payload['assets'] as List<dynamic>? ?? []);
        updateInfo = UpdateInfo(
          latestVersion: latestVersion,
          tagName: tagName,
          releaseName: releaseName,
          releaseUrl: releaseUrl,
          assetName: asset?['name'] as String?,
          assetDownloadUrl: asset?['browser_download_url'] as String?,
        );
        statusMessage = 'Update available: v$latestVersion';
      } else {
        updateInfo = null;
        statusMessage = 'You are up to date (current $normalizedCurrentVersion, latest $latestVersion).';
      }
    } catch (e) {
      lastError = '$e';
      updateInfo = null;
      statusMessage = 'Update check failed';
    } finally {
      isChecking = false;
      notifyListeners();
    }
  }

  Future<void> installUpdate() async {
    if (isDownloading || updateInfo == null) return;

    isDownloading = true;
    lastError = null;
    notifyListeners();

    try {
      final downloadUrl = updateInfo!.assetDownloadUrl;
      if (downloadUrl == null || downloadUrl.isEmpty) {
        await _openReleasePage();
        statusMessage = 'No installer asset found. Opened releases page.';
        return;
      }

      statusMessage = 'Downloading update...';
      notifyListeners();

      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Download failed with ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = updateInfo!.assetName ?? downloadUrl.split('/').last;
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes, flush: true);

      // Persist latest release tag so next app start/update check can use a
      // GitHub-driven local version signal.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_installedReleaseTagKey, updateInfo!.tagName);

      statusMessage = 'Installing update...';
      notifyListeners();

      await _launchInstaller(filePath);
    } catch (e) {
      lastError = '$e';
      statusMessage = 'Install failed';
    } finally {
      isDownloading = false;
      notifyListeners();
    }
  }

  Future<void> openReleaseNotes() async {
    await _openReleasePage();
  }

  Future<void> _openReleasePage() async {
    final url = updateInfo?.releaseUrl ??
        'https://github.com/GLLB-Apps/mw_cartracker/releases';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _launchInstaller(String filePath) async {
    if (Platform.isWindows) {
      final lowerPath = filePath.toLowerCase();

      if (lowerPath.endsWith('.zip')) {
        final extractedExePath = await _extractZipAndFindExe(filePath);
        if (extractedExePath != null) {
          await Process.start(extractedExePath, [], mode: ProcessStartMode.detached);
          exit(0);
        }

        final extractedDir = await _extractZip(filePath);
        await Process.start('explorer.exe', [extractedDir.path], mode: ProcessStartMode.detached);
        statusMessage = 'Update downloaded. Opened extracted folder.';
        return;
      }

      await Process.start(filePath, [], mode: ProcessStartMode.detached);
      exit(0);
    } else if (Platform.isMacOS) {
      await Process.start('open', [filePath], mode: ProcessStartMode.detached);
      exit(0);
    } else if (Platform.isLinux) {
      await Process.start('xdg-open', [filePath], mode: ProcessStartMode.detached);
      exit(0);
    } else {
      await _openReleasePage();
    }
  }

  Future<Directory> _extractZip(String zipPath) async {
    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory(
      '${tempDir.path}/makeway_update_${DateTime.now().millisecondsSinceEpoch}',
    );
    await extractDir.create(recursive: true);

    final result = await Process.run(
      'powershell',
      [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        'Expand-Archive -Path "$zipPath" -DestinationPath "${extractDir.path}" -Force',
      ],
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to extract update ZIP: ${result.stderr}');
    }

    return extractDir;
  }

  Future<String?> _extractZipAndFindExe(String zipPath) async {
    final extractDir = await _extractZip(zipPath);
    final entities = extractDir.listSync(recursive: true);
    final exeFiles = entities
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.exe'))
        .toList();

    if (exeFiles.isEmpty) {
      return null;
    }

    File? preferred = exeFiles.cast<File?>().firstWhere(
          (file) =>
              file!.path.toLowerCase().endsWith(r'\mw_cartracker.exe') ||
              file.path.toLowerCase().endsWith('/mw_cartracker.exe'),
          orElse: () => null,
        );

    preferred ??= exeFiles.first;
    return preferred.path;
  }

  Map<String, dynamic>? _selectBestAsset(List<dynamic> assets) {
    if (assets.isEmpty) return null;

    final normalizedAssets = assets.whereType<Map<String, dynamic>>().toList();
    if (normalizedAssets.isEmpty) return null;

    final platformHints = <String>[];
    if (Platform.isWindows) {
      platformHints.addAll(['windows', 'win', '.exe', '.msi']);
    } else if (Platform.isMacOS) {
      platformHints.addAll(['mac', 'darwin', '.dmg', '.pkg']);
    } else if (Platform.isLinux) {
      platformHints.addAll(['linux', '.appimage', '.deb', '.rpm']);
    }

    for (final hint in platformHints) {
      final match = normalizedAssets.firstWhere(
        (asset) =>
            (asset['name'] as String? ?? '').toLowerCase().contains(hint),
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty) return match;
    }

    return normalizedAssets.first;
  }

  String _normalizeVersion(String rawTag) {
    final cleaned = rawTag.trim().toLowerCase().replaceFirst(RegExp(r'^v'), '');
    if (cleaned.isEmpty) return '0.0.0';
    final parts = _toVersionParts(cleaned);
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }

  bool _isNewerVersion(String latest, String current) {
    final latestParts = _toVersionParts(latest);
    final currentParts = _toVersionParts(current);
    for (var i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  List<int> _toVersionParts(String version) {
    final sanitized = version.toLowerCase().split('+').first;
    final matches = RegExp(r'\d+').allMatches(sanitized).toList();
    return List<int>.generate(3, (index) {
      if (index >= matches.length) return 0;
      return int.tryParse(matches[index].group(0)!) ?? 0;
    });
  }
}
