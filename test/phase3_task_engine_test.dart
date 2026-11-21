import 'package:evora_workers/domain/enums/worker_enums.dart';
import 'package:evora_workers/features/auth/models/auth_state.dart';
import 'package:evora_workers/features/auth/providers/auth_provider.dart';
import 'package:evora_workers/features/auth/services/mock_auth_service.dart';
import 'package:evora_workers/features/tasks/models/task_filter.dart';
import 'package:evora_workers/features/tasks/providers/task_providers.dart';
import 'package:evora_workers/features/tasks/repositories/task_repository.dart';
import 'package:evora_workers/features/tasks/services/mock_task_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 3.1: Task Repository & Data Layer Tests', () {
    late MockTaskService taskService;
    const tenantId = 'tenant-shimla-01';
    const workerUid = 'mock-worker-rajesh-001';
    const crewId = 'crew-alpha-12';

    setUp(() {
      taskService = MockTaskService(simulateDelay: false);
    });

    tearDown(() {
      taskService.dispose();
    });

    test('1. Queries active tasks for worker including individual and unclaimed team-pool tasks',
        () async {
      final tasks = await taskService.getTasksForWorker(
        tenantId: tenantId,
        workerUid: workerUid,
        teamId: crewId,
      );

      // Verify we retrieved tasks
      expect(tasks, isNotEmpty);

      // Individual tasks for Rajesh
      final individual = tasks.where((t) => t.workerUid == workerUid).toList();
      expect(individual, isNotEmpty);

      // Unclaimed team-pool tasks for crew-alpha-12
      final pool = tasks.where((t) => t.isUnclaimedTeamPool).toList();
      expect(pool, isNotEmpty);
      expect(pool.any((t) => t.id == 'task_swm_003'), isTrue);

      // Verify CivicFlow linkage exists on citizen-reported tasks
      final civicFlowLinked = tasks.where((t) => t.isCivicFlowLinked).toList();
      expect(civicFlowLinked, isNotEmpty);
      expect(civicFlowLinked.first.civicFlowCaseId, isNotNull);

      // Verify P1 priority comes before P2
      expect(tasks.first.priority, TaskPriority.p1);
    });

    test('2. acceptTask moves task from assigned to accepted and increments version', () async {
      const targetTaskId = 'task_swm_001';

      final before = await taskService.getTaskById(tenantId: tenantId, taskId: targetTaskId);
      expect(before?.status, TaskStatus.assigned);
      final initialVersion = before!.version;

      await taskService.acceptTask(
        tenantId: tenantId,
        taskId: targetTaskId,
        workerUid: workerUid,
      );

      final after = await taskService.getTaskById(tenantId: tenantId, taskId: targetTaskId);
      expect(after?.status, TaskStatus.accepted);
      expect(after?.version, initialVersion + 1);
    });

    test('3. declineTask records municipal decline reason and moves task to reassigned', () async {
      const targetTaskId = 'task_swm_001';

      await taskService.declineTask(
        tenantId: tenantId,
        taskId: targetTaskId,
        workerUid: workerUid,
        reason: DeclineReason.outOfArea,
        note: 'Outside assigned morning route boundary',
      );

      final after = await taskService.getTaskById(tenantId: tenantId, taskId: targetTaskId);
      expect(after?.status, TaskStatus.reassigned);
    });

    test('4. claimTeamPoolTask atomically locks pool task to claiming worker', () async {
      const poolTaskId = 'task_swm_003';

      final before = await taskService.getTaskById(tenantId: tenantId, taskId: poolTaskId);
      expect(before?.workerUid, isNull);
      expect(before?.isUnclaimedTeamPool, isTrue);

      // First worker claims the pool task
      await taskService.claimTeamPoolTask(
        tenantId: tenantId,
        taskId: poolTaskId,
        workerUid: workerUid,
      );

      final after = await taskService.getTaskById(tenantId: tenantId, taskId: poolTaskId);
      expect(after?.workerUid, workerUid);
      expect(after?.status, TaskStatus.accepted);
      expect(after?.isUnclaimedTeamPool, isFalse);

      // Second worker attempting to claim throws TaskAlreadyClaimedException
      expect(
        () => taskService.claimTeamPoolTask(
          tenantId: tenantId,
          taskId: poolTaskId,
          workerUid: 'mock-worker-sunita-002',
        ),
        throwsA(isA<TaskAlreadyClaimedException>()),
      );
    });

    test('5. dismissPoolTask hides pool item from claiming worker without deleting it for others',
        () async {
      const poolTaskId = 'task_swm_007';

      var workerTasks = await taskService.getTasksForWorker(
        tenantId: tenantId,
        workerUid: workerUid,
        teamId: crewId,
      );
      expect(workerTasks.any((t) => t.id == poolTaskId), isTrue);

      // Worker Rajesh dismisses it
      await taskService.dismissPoolTask(
        tenantId: tenantId,
        taskId: poolTaskId,
        workerUid: workerUid,
      );

      // No longer visible to Rajesh
      workerTasks = await taskService.getTasksForWorker(
        tenantId: tenantId,
        workerUid: workerUid,
        teamId: crewId,
      );
      expect(workerTasks.any((t) => t.id == poolTaskId), isFalse);

      // Still visible to other crew members
      final crewMemberTasks = await taskService.getTasksForWorker(
        tenantId: tenantId,
        workerUid: 'other-crew-worker-099',
        teamId: crewId,
      );
      expect(crewMemberTasks.any((t) => t.id == poolTaskId), isTrue);
    });

    test('6. TaskFilter correctly decomposes search queries, priority, and scope', () async {
      final tasks = await taskService.getTasksForWorker(
        tenantId: tenantId,
        workerUid: workerUid,
        teamId: crewId,
      );

      // Priority Filter
      const p1Filter = TaskFilter(priority: TaskPriority.p1);
      final p1Matches = tasks.where((t) => p1Filter.matches(t, workerUid)).toList();
      expect(p1Matches.every((t) => t.priority == TaskPriority.p1), isTrue);

      // Status Tab Filter
      const inProgressFilter = TaskFilter(statusTab: TaskStatus.inProgress);
      final inProgressMatches =
          tasks.where((t) => inProgressFilter.matches(t, workerUid)).toList();
      expect(inProgressMatches.length, 1);
      expect(inProgressMatches.first.id, 'task_swm_004');

      // Scope Filter (Individual Only)
      const individualFilter = TaskFilter(scope: TaskScope.individual);
      final individualMatches =
          tasks.where((t) => individualFilter.matches(t, workerUid)).toList();
      expect(individualMatches.every((t) => t.workerUid == workerUid), isTrue);

      // Search Query Filter
      const searchFilter = TaskFilter(searchQuery: 'Mall Road');
      final searchMatches = tasks.where((t) => searchFilter.matches(t, workerUid)).toList();
      expect(searchMatches, isNotEmpty);
      expect(
        searchMatches.any((t) => t.title.contains('Mall Road') || t.location.addressSummary.contains('Mall Road')),
        isTrue,
      );
    });

    test('7. Riverpod OverviewMetrics accurately calculates operational counts', () async {
      final testWorker = MockAuthService.mockDirectory['+919999999999']!;

      final container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(taskService),
          authNotifierProvider.overrideWith((ref) {
            final notifier = AuthNotifier(ref.watch(authRepositoryProvider));
            notifier.setAuthenticatedWorker(testWorker);
            return notifier;
          }),
        ],
      );

      final sub = container.listen(tasksStreamProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final metrics = container.read(overviewMetricsProvider);
      expect(metrics.totalToday, greaterThan(0));
      expect(metrics.assignedCount, greaterThan(0));
      expect(metrics.urgentTasks, isNotEmpty);

      sub.close();
      container.dispose();
    });
  });
}
