import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/app_update_service.dart';

class AppUpdateDialog extends ConsumerWidget {
  final AppUpdateInfo info;

  const AppUpdateDialog({super.key, required this.info});

  /// Static helper to show dialog over the navigator context safely
  static Future<void> show(BuildContext context, AppUpdateInfo info) async {
    await showDialog(
      context: context,
      barrierDismissible: !info.isMandatory,
      builder: (ctx) => AppUpdateDialog(info: info),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(appUpdateProvider);
    final notifier = ref.read(appUpdateProvider.notifier);

    final isMandatory = info.isMandatory;
    final isDownloading = updateState.status == AppUpdateStatus.downloading;
    final isReadyToInstall = updateState.status == AppUpdateStatus.readyToInstall;
    final isError = updateState.status == AppUpdateStatus.error;

    return PopScope(
      canPop: !isMandatory && !isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.cream,
        elevation: 16,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Decorative Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: const BoxDecoration(
                  color: AppColors.forestGreen,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
                child: Column(
                  children: [
                    // App Logo Badge
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/thulirva-favicon-512.png',
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.eco,
                            color: AppColors.forestGreen,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Mandatory / Optional Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isMandatory ? Colors.red.shade900 : AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isMandatory ? Colors.red.shade400 : AppColors.gold,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isMandatory ? 'MANDATORY UPDATE' : 'NEW UPDATE AVAILABLE',
                        style: TextStyle(
                          color: isMandatory ? Colors.white : AppColors.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A New Thulirva Update Is Available',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Playfair Display',
                      ),
                    ),
                  ],
                ),
              ),

              // Body Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Version Comparison Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.paleGreen,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sage),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Installed Version',
                                style: TextStyle(fontSize: 11, color: AppColors.textLight),
                              ),
                              Text(
                                'v${info.currentVersion}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_forward, color: AppColors.forestGreen, size: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Latest Version',
                                style: TextStyle(fontSize: 11, color: AppColors.textLight),
                              ),
                              Text(
                                'v${info.latestVersion}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forestGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // File size & date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Size: ${info.fileSize}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        ),
                        if (isMandatory)
                          const Text(
                            'Required to continue',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Release Notes Section
                    if (info.releaseNotes.isNotEmpty) ...[
                      const Text(
                        "What's New:",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            info.releaseNotes,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textDark,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Downloading Progress State
                    if (isDownloading) ...[
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: updateState.progress > 0 ? updateState.progress : null,
                              minHeight: 10,
                              backgroundColor: AppColors.sage,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(updateState.progress * 100).toInt()}% downloaded',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forestGreen,
                                ),
                              ),
                              if (updateState.totalBytes > 0)
                                Text(
                                  '${(updateState.bytesReceived / (1024 * 1024)).toStringAsFixed(1)} / ${(updateState.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => notifier.cancelDownload(),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ] else if (isReadyToInstall) ...[
                      // Ready to install
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.paleGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_circle, color: AppColors.forestGreen, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Download complete! Ready to install.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.forestGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.forestGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => notifier.installDownloadedApk(),
                                child: const Text(
                                  'Open Android Installer',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isError) ...[
                      // Error State
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          children: [
                            Text(
                              updateState.errorMessage ?? 'Download failed.',
                              style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () => notifier.downloadAndInstall(),
                                  child: const Text('Retry Download'),
                                ),
                                TextButton(
                                  onPressed: () => notifier.openInBrowser(),
                                  child: const Text('Open in Browser'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Default Action Buttons: Update Now & Later
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () => notifier.downloadAndInstall(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.download, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              isMandatory ? 'Update Now (Required)' : 'Update Now',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Optional Update "Later" button
                      if (!isMandatory) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            notifier.dismissOptionalUpdate();
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Maybe Later',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

