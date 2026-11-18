import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/worker_enums.dart';

class SyncStatusState {
  final SyncConnectionState connectionState;
  final int pendingOperationCount;
  final DateTime? lastSyncedAt;

  const SyncStatusState({
    this.connectionState = SyncConnectionState.online,
    this.pendingOperationCount = 0,
    this.lastSyncedAt,
  });

  bool get isOffline => connectionState == SyncConnectionState.offline;
  bool get isSyncing => connectionState == SyncConnectionState.syncing;

  SyncStatusState copyWith({
    SyncConnectionState? connectionState,
    int? pendingOperationCount,
    DateTime? lastSyncedAt,
  }) {
    return SyncStatusState(
      connectionState: connectionState ?? this.connectionState,
      pendingOperationCount:
          pendingOperationCount ?? this.pendingOperationCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class SyncStatusNotifier extends StateNotifier<SyncStatusState> {
  SyncStatusNotifier() : super(const SyncStatusState());

  void setConnectionState(SyncConnectionState connectionState) {
    state = state.copyWith(connectionState: connectionState);
  }

  void setPendingCount(int count) {
    state = state.copyWith(pendingOperationCount: count);
  }

  void markSyncedNow() {
    state = state.copyWith(
      connectionState: SyncConnectionState.online,
      pendingOperationCount: 0,
      lastSyncedAt: DateTime.now(),
    );
  }
}

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatusState>((ref) {
  return SyncStatusNotifier();
});
