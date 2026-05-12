import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/error/failures.dart';

/// Reusable error display widget that renders typed [Failure] objects
/// with appropriate icons, messages, and a retry button.
///
/// Ensures the app never shows a blank screen — every error state
/// has a clear message and actionable next step.
class ErrorDisplayWidget extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;

  const ErrorDisplayWidget({
    super.key,
    required this.failure,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(),
              color: _getColor(),
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              _getTitle(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              failure.message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(
                  'TENTAR NOVAMENTE',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    return switch (failure) {
      NetworkFailure() => Icons.wifi_off_rounded,
      PlayerNotFoundFailure() => Icons.person_search_rounded,
      ServerFailure() => Icons.cloud_off_rounded,
      LlmFailure() => Icons.psychology_alt_rounded,
      CacheFailure() => Icons.storage_rounded,
      DatabaseFailure() => Icons.cloud_off_rounded,
      UnknownFailure() => Icons.error_outline_rounded,
    };
  }

  Color _getColor() {
    return switch (failure) {
      NetworkFailure() => AppColors.warning,
      PlayerNotFoundFailure() => AppColors.primary,
      ServerFailure() => AppColors.error,
      LlmFailure() => AppColors.roleSupport,
      CacheFailure() => AppColors.roleDefault,
      DatabaseFailure() => AppColors.error,
      UnknownFailure() => AppColors.error,
    };
  }

  String _getTitle() {
    return switch (failure) {
      NetworkFailure() => 'Sem Conexão',
      PlayerNotFoundFailure() => 'Jogador Não Encontrado',
      ServerFailure() => 'Erro no Servidor',
      LlmFailure() => 'Falha na Análise IA',
      CacheFailure() => 'Erro de Cache',
      DatabaseFailure() => 'Erro na Nuvem',
      UnknownFailure() => 'Erro Inesperado',
    };
  }
}

/// Compact inline error for embedding in cards/sections.
class InlineErrorWidget extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;

  const InlineErrorWidget({
    super.key,
    required this.failure,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              failure.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary, size: 18),
              onPressed: onRetry,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
