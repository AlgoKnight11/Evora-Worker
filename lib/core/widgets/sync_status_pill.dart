import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/worker_enums.dart';
import '../../l10n/generated/app_localizations.dart';
import '../state/sync_status_provider.dart';
import '../theme/evora_colors.dart';

/// Persistent connectivity & offline queue badge displayed in the worker header.
class SyncStatusPill extends ConsumerWidget {
  const SyncStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStatusProvider);
    final l10n = AppLocalizations.of(context)!;

    final (label, icon, fg, bg) = switch (syncState.connectionState) {
      SyncConnectionState.online => (
          syncState.pendingOperationCount > 0
              ? l10n.syncPendingCount(syncState.pendingOperationCount)
              : l10n.syncOnline,
          Icons.cloud_done_outlined,
          EvoraColors.verifiedSeal,
          EvoraColors.successContainer,
        ),
      SyncConnectionState.offline => (
          syncState.pendingOperationCount > 0
              ? '${l10n.syncOffline} • ${l10n.syncPendingCount(syncState.pendingOperationCount)}'
              : l10n.syncOffline,
          Icons.cloud_off_rounded,
          EvoraColors.warmOchre,
          EvoraColors.warningContainer,
        ),
      SyncConnectionState.syncing => (
          l10n.syncSyncing,
          Icons.sync_rounded,
          EvoraColors.infoBlue,
          EvoraColors.infoBlueContainer,
        ),
    };

    return Semantics(
      liveRegion: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: fg.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
