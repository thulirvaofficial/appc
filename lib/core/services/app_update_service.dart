import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/api_endpoints.dart';

class AppUpdateInfo {
  final bool updateAvailable;
  final bool isMandatory;
  final String currentVersion;
  final int currentVersionCode;
  final String latestVersion;
  final int latestVersionCode;
  final String releaseTitle;
  final String releaseNotes;
  final String downloadUrl;
  final String fileSize;
  final int fileSizeBytes;
  final String checksumSha256;
  final String minSupportedVersion;

  const AppUpdateInfo({
    required this.updateAvailable,
    required this.isMandatory,
    required this.currentVersion,
    required this.currentVersionCode,
    required this.latestVersion,
    required this.latestVersionCode,
    required this.releaseTitle,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.fileSize,
    required this.fileSizeBytes,
    required this.checksumSha256,
    required this.minSupportedVersion,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json, String clientVer, int clientCode) {
    return AppUpdateInfo(
      updateAvailable: json['updateAvailable'] == true,
      isMandatory: json['isMandatory'] == true,
      currentVersion: clientVer,
      currentVersionCode: clientCode,
      latestVersion: (json['latestVersion'] ?? '').toString(),
      latestVersionCode: int.tryParse((json['latestVersionCode'] ?? json['versionCode'] ?? 0).toString()) ?? 0,
      releaseTitle: (json['releaseTitle'] ?? 'New Thulirva Update').toString(),
      releaseNotes: (json['releaseNotes'] ?? '').toString(),
      downloadUrl: (json['downloadUrl'] ?? '/app/releases/download').toString(),
      fileSize: (json['fileSize'] ?? '40 MB').toString(),
      fileSizeBytes: int.tryParse((json['fileSizeBytes'] ?? 0).toString()) ?? 0,
      checksumSha256: (json['checksumSha256'] ?? '').toString(),
      minSupportedVersion: (json['minSupportedVersion'] ?? '1.0.0').toString(),
    );
  }
}

enum AppUpdateStatus {
  idle,
  checking,
  updateAvailable,
  upToDate,
  downloading,
  readyToInstall,
  error,
}

class AppUpdateState {
  final AppUpdateStatus status;
  final AppUpdateInfo? info;
  final double progress; // 0.0 to 1.0
  final int bytesReceived;
  final int totalBytes;
  final String? errorMessage;
  final String? downloadedApkPath;

  const AppUpdateState({
    this.status = AppUpdateStatus.idle,
    this.info,
    this.progress = 0.0,
    this.bytesReceived = 0,
    this.totalBytes = 0,
    this.errorMessage,
    this.downloadedApkPath,
  });

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    AppUpdateInfo? info,
    double? progress,
    int? bytesReceived,
    int? totalBytes,
    String? errorMessage,
    String? downloadedApkPath,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      info: info ?? this.info,
      progress: progress ?? this.progress,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadedApkPath: downloadedApkPath ?? this.downloadedApkPath,
    );
  }
}

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  AppUpdateNotifier() : super(const AppUpdateState());

  bool _dismissedThisSession = false;
  CancelToken? _downloadCancelToken;

  bool get isDismissedThisSession => _dismissedThisSession;

  void dismissOptionalUpdate() {
    _dismissedThisSession = true;
    state = state.copyWith(status: AppUpdateStatus.idle);
  }

  /// Check for updates from backend
  Future<AppUpdateInfo?> checkForUpdate({bool manualCheck = false}) async {
    if (state.status == AppUpdateStatus.checking || state.status == AppUpdateStatus.downloading) {
      return state.info;
    }

    state = state.copyWith(status: AppUpdateStatus.checking, errorMessage: null);

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentCode = int.tryParse(packageInfo.buildNumber) ?? 1;

      debugPrint('📦 [APP UPDATE] Checking update: installed v$currentVersion (code: $currentCode)');

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final checkUrl = '${ApiEndpoints.serverRoot}/api${ApiEndpoints.appReleaseCheck}';
      final response = await dio.get(
        checkUrl,
        queryParameters: {
          'version': currentVersion,
          'version_code': currentCode,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};

        final info = AppUpdateInfo.fromJson(data, currentVersion, currentCode);

        if (info.updateAvailable) {
          debugPrint('✨ [APP UPDATE] New version available: v${info.latestVersion} (Mandatory: ${info.isMandatory})');

          // If it's an optional update and the user dismissed it already during this session, don't re-prompt automatically unless it's a manual check
          if (!manualCheck && !info.isMandatory && _dismissedThisSession) {
            state = state.copyWith(status: AppUpdateStatus.idle, info: info);
            return info;
          }

          state = state.copyWith(
            status: AppUpdateStatus.updateAvailable,
            info: info,
          );
          return info;
        } else {
          debugPrint('✅ [APP UPDATE] App is up to date.');
          state = state.copyWith(status: AppUpdateStatus.upToDate, info: info);
          return info;
        }
      } else {
        state = state.copyWith(
          status: AppUpdateStatus.idle,
          errorMessage: 'Server returned ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('⚠️ [APP UPDATE] Error checking update: $e');
      state = state.copyWith(
        status: AppUpdateStatus.idle,
        errorMessage: e.toString(),
      );
    }
    return null;
  }

  /// Download and install the update APK directly inside the app
  Future<void> downloadAndInstall() async {
    final info = state.info;
    if (info == null) return;

    state = state.copyWith(
      status: AppUpdateStatus.downloading,
      progress: 0.0,
      bytesReceived: 0,
      totalBytes: info.fileSizeBytes,
      errorMessage: null,
    );

    _downloadCancelToken = CancelToken();

    try {
      // 1. Resolve full download URL
      String fullUrl = info.downloadUrl;
      if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
        fullUrl = '${ApiEndpoints.serverRoot}$fullUrl';
      }

      debugPrint('🚀 [APP UPDATE] Downloading APK from: $fullUrl');

      // 2. Resolve destination directory
      Directory storageDir;
      if (Platform.isAndroid) {
        storageDir = (await getExternalStorageDirectory()) ?? await getTemporaryDirectory();
      } else {
        storageDir = await getTemporaryDirectory();
      }

      final fileName = 'thulirva_v${info.latestVersion}_${info.latestVersionCode}.apk';
      final savePath = '${storageDir.path}/$fileName';

      final file = File(savePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      // 3. Download using Dio with chunk progress
      final dio = Dio();
      await dio.download(
        fullUrl,
        savePath,
        cancelToken: _downloadCancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final prog = received / total;
            state = state.copyWith(
              progress: prog.clamp(0.0, 1.0),
              bytesReceived: received,
              totalBytes: total,
            );
          } else {
            state = state.copyWith(
              bytesReceived: received,
            );
          }
        },
      );

      debugPrint('📥 [APP UPDATE] Download complete. File saved at: $savePath');

      // 4. Verify SHA-256 Checksum if provided
      if (info.checksumSha256.isNotEmpty) {
        try {
          final bytes = await File(savePath).readAsBytes();
          final computedHash = sha256.convert(bytes).toString();
          debugPrint('🔒 [APP UPDATE] Checksum verify: computed=$computedHash, expected=${info.checksumSha256}');
          if (computedHash.toLowerCase() != info.checksumSha256.toLowerCase()) {
            debugPrint('⚠️ [APP UPDATE] Checksum mismatch! Download may be corrupted.');
          } else {
            debugPrint('✅ [APP UPDATE] SHA-256 verified successfully.');
          }
        } catch (hashErr) {
          debugPrint('⚠️ [APP UPDATE] Hash verification note: $hashErr');
        }
      }

      state = state.copyWith(
        status: AppUpdateStatus.readyToInstall,
        downloadedApkPath: savePath,
        progress: 1.0,
      );

      // 5. Launch native Android installer
      await installDownloadedApk();
    } catch (e) {
      if (CancelToken.isCancel(e as dynamic)) {
        debugPrint('🛑 [APP UPDATE] Download cancelled by user');
        state = state.copyWith(status: AppUpdateStatus.updateAvailable);
      } else {
        debugPrint('❌ [APP UPDATE] Download error: $e');
        state = state.copyWith(
          status: AppUpdateStatus.error,
          errorMessage: 'Failed to download APK. Please check your internet connection or use browser download.',
        );
      }
    }
  }

  /// Launch the Android Package Installer for the downloaded APK
  Future<void> installDownloadedApk() async {
    final apkPath = state.downloadedApkPath;
    if (apkPath == null || !File(apkPath).existsSync()) {
      state = state.copyWith(
        status: AppUpdateStatus.error,
        errorMessage: 'Downloaded APK not found on device storage. Please retry.',
      );
      return;
    }

    try {
      debugPrint('📦 [APP UPDATE] Opening APK with OpenFilex: $apkPath');
      final result = await OpenFilex.open(
        apkPath,
        type: 'application/vnd.android.package-archive',
      );

      debugPrint('📦 [APP UPDATE] OpenFilex result: ${result.type} - ${result.message}');

      if (result.type != ResultType.done) {
        state = state.copyWith(
          status: AppUpdateStatus.readyToInstall,
          errorMessage: 'Please grant "Install unknown apps" permission to complete update, or tap "Open in Browser".',
        );
      }
    } catch (e) {
      debugPrint('❌ [APP UPDATE] Install intent error: $e');
      state = state.copyWith(
        status: AppUpdateStatus.error,
        errorMessage: 'Unable to launch installer: $e. You can download directly via browser.',
      );
    }
  }

  /// Cancel active download
  void cancelDownload() {
    _downloadCancelToken?.cancel('Cancelled by user');
    state = state.copyWith(status: AppUpdateStatus.updateAvailable, progress: 0.0);
  }

  /// Fallback: Open public download page in external browser
  Future<void> openInBrowser() async {
    try {
      final uri = Uri.parse('https://thulirva.com/download-app.html');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final fallback = Uri.parse('${ApiEndpoints.serverRoot}/api/app/releases/download');
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('⚠️ [APP UPDATE] Browser launch error: $e');
    }
  }
}

final appUpdateProvider = StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
  return AppUpdateNotifier();
});

