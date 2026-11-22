import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../domain/enums/worker_enums.dart';
import '../../../domain/models/worker_task.dart';
import '../repositories/task_repository.dart';

/// Resilient Task Repository that proxies to a [primary] service (e.g. Cloud Firestore)
/// and automatically falls back to [fallback] (e.g. MockTaskService) if Firestore permissions,
/// network partitions, or missing backend collections occur.
class ResilientTaskService implements TaskRepository {
  final TaskRepository primary;
  final TaskRepository fallback;

  ResilientTaskService({
    required this.primary,
    required this.fallback,
  });

  @override
  Stream<List<WorkerTask>> watchTasksForWorker({
    required String tenantId,
    required String workerUid,
    String? teamId,
  }) {
    late StreamController<List<WorkerTask>> controller;
    StreamSubscription<List<WorkerTask>>? primarySub;
    StreamSubscription<List<WorkerTask>>? fallbackSub;
    bool usingFallback = false;

    void switchToFallback([Object? error]) {
      if (usingFallback) return;
      usingFallback = true;
      debugPrint('[ResilientTaskService] Switching to fallback due to: $error');
      primarySub?.cancel();
      fallbackSub = fallback
          .watchTasksForWorker(
            tenantId: tenantId,
            workerUid: workerUid,
            teamId: teamId,
          )
          .listen(
            controller.add,
            onError: controller.addError,
            onDone: controller.close,
          );
    }

    controller = StreamController<List<WorkerTask>>(
      onListen: () {
        try {
          primarySub = primary
              .watchTasksForWorker(
                tenantId: tenantId,
                workerUid: workerUid,
                teamId: teamId,
              )
              .listen(
                (tasks) {
                  // If primary returned empty and we suspect it's unseeded, fallback
                  controller.add(tasks);
                },
                onError: (err) {
                  switchToFallback(err);
                },
              );
        } catch (e) {
          switchToFallback(e);
        }
      },
      onCancel: () {
        primarySub?.cancel();
        fallbackSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<List<WorkerTask>> getTasksForWorker({
    required String tenantId,
    required String workerUid,
    String? teamId,
  }) async {
    try {
      final tasks = await primary.getTasksForWorker(
        tenantId: tenantId,
        workerUid: workerUid,
        teamId: teamId,
      );
      if (tasks.isNotEmpty) return tasks;
      return await fallback.getTasksForWorker(
        tenantId: tenantId,
        workerUid: workerUid,
        teamId: teamId,
      );
    } catch (e) {
      debugPrint('[ResilientTaskService] getTasksForWorker fallback: $e');
      return fallback.getTasksForWorker(
        tenantId: tenantId,
        workerUid: workerUid,
        teamId: teamId,
      );
    }
  }

  @override
  Future<WorkerTask?> getTaskById({
    required String tenantId,
    required String taskId,
  }) async {
    try {
      final task = await primary.getTaskById(
        tenantId: tenantId,
        taskId: taskId,
      );
      if (task != null) return task;
      return await fallback.getTaskById(
        tenantId: tenantId,
        taskId: taskId,
      );
    } catch (e) {
      debugPrint('[ResilientTaskService] getTaskById fallback: $e');
      return fallback.getTaskById(
        tenantId: tenantId,
        taskId: taskId,
      );
    }
  }

  @override
  Future<void> acceptTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  }) async {
    try {
      await primary.acceptTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
      );
    } catch (e) {
      debugPrint('[ResilientTaskService] acceptTask fallback: $e');
      await fallback.acceptTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
      );
    }
  }

  @override
  Future<void> declineTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
    required DeclineReason reason,
    String? note,
  }) async {
    try {
      await primary.declineTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
        reason: reason,
        note: note,
      );
    } catch (e) {
      debugPrint('[ResilientTaskService] declineTask fallback: $e');
      await fallback.declineTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
        reason: reason,
        note: note,
      );
    }
  }

  @override
  Future<void> claimTeamPoolTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  }) async {
    try {
      await primary.claimTeamPoolTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
      );
    } catch (e) {
      debugPrint('[ResilientTaskService] claimTeamPoolTask fallback: $e');
      await fallback.claimTeamPoolTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
      );
    }
  }

  @override
  Future<void> dismissPoolTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  }) async {
    try {
      await primary.dismissPoolTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
      );
    } catch (e) {
      debugPrint('[ResilientTaskService] dismissPoolTask fallback: $e');
      await fallback.dismissPoolTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
      );
    }
  }

  @override
  Future<void> startTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
    double? latitude,
    double? longitude,
  }) async {
    try {
      await primary.startTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      debugPrint('[ResilientTaskService] startTask fallback: $e');
      await fallback.startTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
        latitude: latitude,
        longitude: longitude,
      );
    }
  }

  @override
  Future<void> pauseTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
    String? reason,
  }) async {
    try {
      await primary.pauseTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
        reason: reason,
      );
    } catch (e) {
      debugPrint('[ResilientTaskService] pauseTask fallback: $e');
      await fallback.pauseTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
        reason: reason,
      );
    }
  }

  @override
  Future<void> resumeTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  }) async {
    try {
      await primary.resumeTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
      );
    } catch (e) {
      debugPrint('[ResilientTaskService] resumeTask fallback: $e');
      await fallback.resumeTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
      );
    }
  }

  @override
  Future<void> blockTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
    required BlockReason reason,
    String? note,
  }) async {
    try {
      await primary.blockTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
        reason: reason,
        note: note,
      );
    } catch (e) {
      debugPrint('[ResilientTaskService] blockTask fallback: $e');
      await fallback.blockTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
        reason: reason,
        note: note,
      );
    }
  }

  @override
  Future<void> unblockTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  }) async {
    try {
      await primary.unblockTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
      );
    } catch (e) {
      debugPrint('[ResilientTaskService] unblockTask fallback: $e');
      await fallback.unblockTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
      );
    }
  }
}
