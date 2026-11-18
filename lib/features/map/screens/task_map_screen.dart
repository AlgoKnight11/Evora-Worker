import 'package:flutter/material.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Task Map / Work Area (`/map`): Assigned pins, approved service area, and offline navigation fallback.
class TaskMapScreen extends StatelessWidget {
  const TaskMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.mapSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: EvoraColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: EvoraColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: EvoraColors.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: EvoraColors.successContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    size: 30,
                    color: EvoraColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.mapServiceAreaLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.directions_outlined,
                  color: EvoraColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mapOfflineFallbackTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.mapOfflineFallbackDesc,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: EvoraColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
