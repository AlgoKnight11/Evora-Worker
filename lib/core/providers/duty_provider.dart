import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/worker_profile.dart';
import '../services/foreground_dispatch_service.dart';

/// StateNotifier tracking whether the field worker is currently On-Duty
/// with active background dispatch monitoring.
class DutyNotifier extends StateNotifier<bool> {
  DutyNotifier() : super(true) {
    _initDutyState();
  }

  Future<void> _initDutyState() async {
    try {
      final active = await ForegroundDispatchService.isDutyActive();
      state = active;
    } catch (_) {}
  }

  /// Toggles between On-Duty (Active Dispatch Service) and Off-Duty
  Future<bool> toggleDuty(WorkerProfile? profile) async {
    if (state) {
      final success = await ForegroundDispatchService.stopDuty();
      if (success) {
        state = false;
      }
      return !state;
    } else {
      if (profile != null) {
        final success = await ForegroundDispatchService.startDuty(
          tenantId: profile.tenantId,
          departmentId: profile.departmentId,
        );
        if (success) {
          state = true;
        }
      }
      return state;
    }
  }

  /// Explicitly marks duty as active and starts foreground service
  Future<void> setDutyActive(WorkerProfile profile) async {
    final success = await ForegroundDispatchService.startDuty(
      tenantId: profile.tenantId,
      departmentId: profile.departmentId,
    );
    if (success) {
      state = true;
    }
  }
}

/// Global provider for the worker's shift / duty state
final dutyProvider = StateNotifierProvider<DutyNotifier, bool>((ref) {
  return DutyNotifier();
});
