import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// A compact full-width banner shown when the app is operating in offline mode.
///
/// Returns [SizedBox.shrink] when [isOffline] is false.
class OfflineBannerWidget extends StatelessWidget {
  final bool isOffline;

  /// If provided, the date is appended to the banner text as " · dados de DD/MM".
  final DateTime? lastSync;

  const OfflineBannerWidget({
    super.key,
    required this.isOffline,
    this.lastSync,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    final syncLabel = lastSync != null
        ? ' · dados de ${lastSync!.day.toString().padLeft(2, '0')}/${lastSync!.month.toString().padLeft(2, '0')}'
        : '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          const Icon(Icons.cloud_off, color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Text(
            'Modo offline$syncLabel',
            style: const TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
