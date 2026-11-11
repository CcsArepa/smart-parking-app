import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/theme/app_colors.dart';

/// Indicador de carga a pantalla completa dentro de un `CustomScrollView`.
class SliverLoading extends StatelessWidget {
  const SliverLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.white),
        ),
      ),
    );
  }
}

/// Mensaje de error con botón para reintentar (prevención y recuperación de
/// errores: el usuario nunca se queda "atorado").
class SliverError extends StatelessWidget {
  const SliverError({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.white),
            const SizedBox(height: 12),
            Text(
              'No pudimos cargar la información.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.black,
              ),
              onPressed: () {
                AppFeedback.instance.play(UiSound.tap);
                onRetry();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
