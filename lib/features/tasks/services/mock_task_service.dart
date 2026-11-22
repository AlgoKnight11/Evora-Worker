import 'dart:async';
import '../../../domain/enums/worker_enums.dart';
import '../../../domain/models/worker_task.dart';
import '../repositories/task_repository.dart';

/// In-memory mock task service seeded with realistic municipal operations
/// linked to citizen CivicFlow grievance cases.
class MockTaskService implements TaskRepository {
  final bool simulateDelay;
  final List<WorkerTask> _tasks = [];
  final Map<String, Set<String>> _dismissedPoolTasks = {}; // workerUid -> set of taskIds
  final StreamController<List<WorkerTask>> _streamController =
      StreamController<List<WorkerTask>>.broadcast();

  MockTaskService({this.simulateDelay = false}) {
    _seedDefaultTasks();
  }

  void _seedDefaultTasks() {
    final now = DateTime.now();

    _tasks.addAll([
      // Task 1: Assigned CivicFlow Case (P1 Critical - Overflowing Bin)
      WorkerTask(
        id: 'task_swm_001',
        tenantId: 'tenant-shimla-01',
        sourceType: SourceType.civicFlowCase,
        civicFlowCaseId: 'case_cf_7101',
        workerUid: 'mock-worker-rajesh-001',
        teamId: 'crew-alpha-12',
        departmentId: 'dept-swm',
        departmentNameSnapshot: 'Solid Waste Management',
        wardId: 'ward-12',
        categoryId: 'bin_overflow',
        categoryNameSnapshot: 'Sanitation & Waste',
        status: TaskStatus.assigned,
        priority: TaskPriority.p1,
        title: 'Overflowing Community Garbage Bin near Mall Road',
        instructions:
            'Clear overflowed solid waste, disinfect bin perimeter with lime solution, and secure container lid.',
        safetyPrecautions: const [
          'Wear high-visibility reflective safety vest',
          'Wear heavy puncture-resistant gloves',
          'Use mechanical lifting tongs for broken glass or sharp objects',
        ],
        requiredEvidence: const ['before_photo', 'after_photo', 'checklist'],
        location: const TaskLocation(
          latitude: 31.1048,
          longitude: 77.1734,
          addressSummary: 'Mall Road, near Lower Bazaar Steps',
          landmark: 'Opposite State Bank Building',
          wardId: 'ward-12',
          wardNameSnapshot: 'Ward 12 - Mall Road Central',
        ),
        assignedByUid: 'sup_vikram_verma',
        assignedAt: now.subtract(const Duration(minutes: 45)),
        dueAt: now.add(const Duration(hours: 2, minutes: 15)),
        updatedAt: now.subtract(const Duration(minutes: 45)),
        version: 1,
      ),

      // Task 2: Accepted CivicFlow Case (P2 - Trail Litter)
      WorkerTask(
        id: 'task_swm_002',
        tenantId: 'tenant-shimla-01',
        sourceType: SourceType.civicFlowCase,
        civicFlowCaseId: 'case_cf_7102',
        workerUid: 'mock-worker-rajesh-001',
        teamId: 'crew-alpha-12',
        departmentId: 'dept-swm',
        departmentNameSnapshot: 'Solid Waste Management',
        wardId: 'ward-12',
        categoryId: 'litter_clearing',
        categoryNameSnapshot: 'Sanitation & Waste',
        status: TaskStatus.accepted,
        priority: TaskPriority.p2,
        title: 'Litter & Plastic Debris Accumulation along Heritage Trail',
        instructions:
            'Conduct sweep of tourist pedestrian footpath, segregate dry plastics into green municipal bags.',
        safetyPrecautions: const [
          'Wear reflective vest',
          'Non-slip grip boots recommended on slope',
        ],
        requiredEvidence: const ['after_photo', 'checklist'],
        location: const TaskLocation(
          latitude: 31.1062,
          longitude: 77.1751,
          addressSummary: 'Heritage Ridge Pathway, Pillar 14',
          landmark: 'Near Viewpoint Gazebo',
          wardId: 'ward-12',
          wardNameSnapshot: 'Ward 12 - Mall Road Central',
        ),
        assignedByUid: 'sup_vikram_verma',
        assignedAt: now.subtract(const Duration(hours: 1)),
        dueAt: now.add(const Duration(hours: 4, minutes: 30)),
        updatedAt: now.subtract(const Duration(minutes: 20)),
        version: 2,
      ),

      // Task 3: Unclaimed Team Pool Task (P1 Critical - Compactor Hopper Malfunction)
      WorkerTask(
        id: 'task_swm_003',
        tenantId: 'tenant-shimla-01',
        sourceType: SourceType.municipalWorkOrder,
        workOrderId: 'wo_swm_5503',
        workerUid: null, // Unclaimed pool!
        teamId: 'crew-alpha-12',
        departmentId: 'dept-swm',
        departmentNameSnapshot: 'Solid Waste Management',
        wardId: 'ward-13',
        categoryId: 'equipment_maintenance',
        categoryNameSnapshot: 'Equipment & Infrastructure',
        status: TaskStatus.assigned,
        priority: TaskPriority.p1,
        title: 'Damaged Community Waste Compactor Hopper',
        instructions:
            'Inspect jammed hydraulic safety latch on compactor unit. Cordon off area with caution tape if mechanism is unsafe.',
        safetyPrecautions: const [
          'Wear safety helmet and eye protection',
          'Ensure power lock-out before touching hopper',
        ],
        requiredEvidence: const ['before_photo', 'after_photo'],
        location: const TaskLocation(
          latitude: 31.1021,
          longitude: 77.1698,
          addressSummary: 'Cart Road Collection Station 3',
          landmark: 'Adjacent to Lift Parking Gate',
          wardId: 'ward-13',
          wardNameSnapshot: 'Ward 13 - Cart Road',
        ),
        assignedByUid: 'sup_vikram_verma',
        assignedAt: now.subtract(const Duration(minutes: 30)),
        dueAt: now.add(const Duration(hours: 1, minutes: 45)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
        version: 1,
      ),

      // Task 4: In Progress CivicFlow Case (P2 - Storm Drain Debris)
      WorkerTask(
        id: 'task_swm_004',
        tenantId: 'tenant-shimla-01',
        sourceType: SourceType.civicFlowCase,
        civicFlowCaseId: 'case_cf_7104',
        workerUid: 'mock-worker-rajesh-001',
        teamId: 'crew-alpha-12',
        departmentId: 'dept-swm',
        departmentNameSnapshot: 'Solid Waste Management',
        wardId: 'ward-12',
        categoryId: 'drainage_unblock',
        categoryNameSnapshot: 'Drainage & Sanitization',
        status: TaskStatus.inProgress,
        priority: TaskPriority.p2,
        title: 'Clogged Storm Drain Grate near Lower Bazaar Alley',
        instructions:
            'Remove clogged silt and fallen leaves obstructing drain entrance to prevent street waterlogging.',
        safetyPrecautions: const [
          'Rubber safety boots mandatory',
          'Heavy-duty waterproof gloves',
        ],
        requiredEvidence: const ['before_photo', 'after_photo', 'measurements'],
        location: const TaskLocation(
          latitude: 31.1041,
          longitude: 77.1722,
          addressSummary: 'Lower Bazaar Alley Entrance',
          landmark: 'Behind Municipal Dispensary',
          wardId: 'ward-12',
          wardNameSnapshot: 'Ward 12 - Mall Road Central',
        ),
        assignedByUid: 'sup_vikram_verma',
        assignedAt: now.subtract(const Duration(hours: 2)),
        dueAt: now.add(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(minutes: 15)),
        version: 3,
      ),

      // Task 5: Blocked Work Order (P3 Routine - Landslide Warning)
      WorkerTask(
        id: 'task_swm_005',
        tenantId: 'tenant-shimla-01',
        sourceType: SourceType.preventiveMaintenance,
        workOrderId: 'wo_swm_9912',
        workerUid: 'mock-worker-rajesh-001',
        teamId: 'crew-alpha-12',
        departmentId: 'dept-swm',
        departmentNameSnapshot: 'Solid Waste Management',
        wardId: 'ward-14',
        categoryId: 'sanitization_disinfection',
        categoryNameSnapshot: 'Sanitation & Waste',
        status: TaskStatus.blocked,
        priority: TaskPriority.p3,
        title: 'Scheduled Disinfection of Public Sanitation Point 4',
        instructions:
            'Spray antibacterial solution and wash down public washing platforms.',
        safetyPrecautions: const ['Chemical vapor respirator', 'Full protective apron'],
        requiredEvidence: const ['after_photo'],
        location: const TaskLocation(
          latitude: 31.0988,
          longitude: 77.1645,
          addressSummary: 'Circular Road, Sector 14 Ghati',
          landmark: 'Near Forest Rest House',
          wardId: 'ward-14',
          wardNameSnapshot: 'Ward 14 - Southern Sector',
        ),
        assignedByUid: 'sup_vikram_verma',
        assignedAt: now.subtract(const Duration(hours: 4)),
        dueAt: now.add(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        version: 2,
      ),

      // Task 6: Submitted for Review CivicFlow Case (P2)
      WorkerTask(
        id: 'task_swm_006',
        tenantId: 'tenant-shimla-01',
        sourceType: SourceType.civicFlowCase,
        civicFlowCaseId: 'case_cf_7106',
        workerUid: 'mock-worker-rajesh-001',
        teamId: 'crew-alpha-12',
        departmentId: 'dept-swm',
        departmentNameSnapshot: 'Solid Waste Management',
        wardId: 'ward-12',
        categoryId: 'debris_removal',
        categoryNameSnapshot: 'Sanitation & Waste',
        status: TaskStatus.submittedForReview,
        priority: TaskPriority.p2,
        title: 'Illegal Debris Dumping behind Old Bus Stand',
        instructions:
            'Load dumped construction rubble into municipal tipper truck and transport to designated landfill.',
        safetyPrecautions: const ['Steel-toe boots', 'Dust respirator mask'],
        requiredEvidence: const ['before_photo', 'after_photo'],
        location: const TaskLocation(
          latitude: 31.1035,
          longitude: 77.1685,
          addressSummary: 'Old Bus Stand Yard, Bay 2',
          landmark: 'Beside Municipal Workshop',
          wardId: 'ward-12',
          wardNameSnapshot: 'Ward 12 - Mall Road Central',
        ),
        assignedByUid: 'sup_vikram_verma',
        assignedAt: now.subtract(const Duration(hours: 6)),
        dueAt: now.add(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
        version: 4,
      ),

      // Task 7: Unclaimed Team Pool Task (P2 Campaign)
      WorkerTask(
        id: 'task_swm_007',
        tenantId: 'tenant-shimla-01',
        sourceType: SourceType.campaign,
        workOrderId: 'wo_swm_camp_01',
        workerUid: null, // Unclaimed pool!
        teamId: 'crew-alpha-12',
        departmentId: 'dept-swm',
        departmentNameSnapshot: 'Solid Waste Management',
        wardId: 'ward-12',
        categoryId: 'cleanliness_campaign',
        categoryNameSnapshot: 'Municipal Campaign',
        status: TaskStatus.assigned,
        priority: TaskPriority.p2,
        title: 'Weekly Night Market Cleanliness & Sanitization Drive',
        instructions:
            'Deploy team to wash market pavement and disinfect pedestrian walkways post-market closure.',
        safetyPrecautions: const ['High-vis vest', 'Water-resistant boots'],
        requiredEvidence: const ['after_photo', 'checklist'],
        location: const TaskLocation(
          latitude: 31.1055,
          longitude: 77.1740,
          addressSummary: 'Lakkar Bazaar Market Square',
          landmark: 'Central Wooden Art Emporium',
          wardId: 'ward-12',
          wardNameSnapshot: 'Ward 12 - Mall Road Central',
        ),
        assignedByUid: 'sup_vikram_verma',
        assignedAt: now.subtract(const Duration(hours: 1)),
        dueAt: now.add(const Duration(hours: 8)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        version: 1,
      ),
    ]);
  }

  Future<void> _maybeDelay() async {
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  List<WorkerTask> _filterForWorker({
    required String tenantId,
    required String workerUid,
    String? teamId,
  }) {
    final dismissed = _dismissedPoolTasks[workerUid] ?? {};

    return _tasks.where((task) {
      if (task.tenantId != tenantId) return false;
      if (dismissed.contains(task.id)) return false;

      // 1. Individually assigned to this worker or default demo worker in sandbox mode
      if (task.workerUid == workerUid || task.workerUid == 'mock-worker-rajesh-001') return true;

      // 2. Unclaimed pool task for worker's crew
      if (task.workerUid == null && (teamId == null || task.teamId == teamId || task.teamId == 'crew-alpha-12')) {
        return true;
      }

      return false;
    }).toList()
      ..sort((a, b) {
        // Sort: P1 before P2 before P3 before P4, then by dueAt
        final pCompare = a.priority.index.compareTo(b.priority.index);
        if (pCompare != 0) return pCompare;
        return a.dueAt.compareTo(b.dueAt);
      });
  }

  void _emitUpdatedTasks(String tenantId, String workerUid, String? teamId) {
    if (!_streamController.isClosed) {
      _streamController.add(_filterForWorker(
        tenantId: tenantId,
        workerUid: workerUid,
        teamId: teamId,
      ));
    }
  }

  @override
  Stream<List<WorkerTask>> watchTasksForWorker({
    required String tenantId,
    required String workerUid,
    String? teamId,
  }) {
    // Schedule initial emission
    Future.microtask(() => _emitUpdatedTasks(tenantId, workerUid, teamId));
    return _streamController.stream;
  }

  @override
  Future<List<WorkerTask>> getTasksForWorker({
    required String tenantId,
    required String workerUid,
    String? teamId,
  }) async {
    await _maybeDelay();
    return _filterForWorker(
      tenantId: tenantId,
      workerUid: workerUid,
      teamId: teamId,
    );
  }

  @override
  Future<WorkerTask?> getTaskById({
    required String tenantId,
    required String taskId,
  }) async {
    await _maybeDelay();
    try {
      return _tasks.firstWhere(
        (t) => t.tenantId == tenantId && t.id == taskId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> acceptTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  }) async {
    await _maybeDelay();
    final index = _tasks.indexWhere((t) => t.tenantId == tenantId && t.id == taskId);
    if (index == -1) throw Exception('Task $taskId not found');

    final existing = _tasks[index];
    if (existing.workerUid != workerUid) {
      throw Exception('Task is not assigned to current worker');
    }

    _tasks[index] = existing.copyWith(
      status: TaskStatus.accepted,
      updatedAt: DateTime.now(),
      version: existing.version + 1,
    );

    _emitUpdatedTasks(tenantId, workerUid, existing.teamId);
  }

  @override
  Future<void> declineTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
    required DeclineReason reason,
    String? note,
  }) async {
    await _maybeDelay();
    final index = _tasks.indexWhere((t) => t.tenantId == tenantId && t.id == taskId);
    if (index == -1) throw Exception('Task $taskId not found');

    final existing = _tasks[index];
    if (existing.workerUid != workerUid) {
      throw Exception('Task is not assigned to current worker');
    }

    // Moves back to reassigned queue so dispatcher can re-route
    _tasks[index] = existing.copyWith(
      status: TaskStatus.reassigned,
      updatedAt: DateTime.now(),
      version: existing.version + 1,
    );

    _emitUpdatedTasks(tenantId, workerUid, existing.teamId);
  }

  @override
  Future<void> claimTeamPoolTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  }) async {
    await _maybeDelay();
    final index = _tasks.indexWhere((t) => t.tenantId == tenantId && t.id == taskId);
    if (index == -1) throw Exception('Task $taskId not found');

    final existing = _tasks[index];

    // Atomic collision check
    if (existing.workerUid != null) {
      throw TaskAlreadyClaimedException(
        taskId: taskId,
        claimedByUid: existing.workerUid,
      );
    }

    _tasks[index] = existing.copyWith(
      workerUid: workerUid,
      status: TaskStatus.accepted,
      updatedAt: DateTime.now(),
      version: existing.version + 1,
    );

    _emitUpdatedTasks(tenantId, workerUid, existing.teamId);
  }

  @override
  Future<void> dismissPoolTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  }) async {
    await _maybeDelay();
    _dismissedPoolTasks.putIfAbsent(workerUid, () => <String>{}).add(taskId);
    final task = await getTaskById(tenantId: tenantId, taskId: taskId);
    _emitUpdatedTasks(tenantId, workerUid, task?.teamId);
  }

  @override
  Future<void> startTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
    double? latitude,
    double? longitude,
  }) async {
    await _maybeDelay();
    final index = _tasks.indexWhere((t) => t.tenantId == tenantId && t.id == taskId);
    if (index == -1) throw Exception('Task $taskId not found');

    final existing = _tasks[index];
    if (existing.workerUid != workerUid) {
      throw Exception('Task is not assigned to current worker');
    }

    _tasks[index] = existing.copyWith(
      status: TaskStatus.inProgress,
      startedAt: DateTime.now(),
      startedLatitude: latitude,
      startedLongitude: longitude,
      clearPaused: true,
      updatedAt: DateTime.now(),
      version: existing.version + 1,
    );

    _emitUpdatedTasks(tenantId, workerUid, existing.teamId);
  }

  @override
  Future<void> pauseTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
    String? reason,
  }) async {
    await _maybeDelay();
    final index = _tasks.indexWhere((t) => t.tenantId == tenantId && t.id == taskId);
    if (index == -1) throw Exception('Task $taskId not found');

    final existing = _tasks[index];
    if (existing.workerUid != workerUid) {
      throw Exception('Task is not assigned to current worker');
    }

    _tasks[index] = existing.copyWith(
      status: TaskStatus.accepted,
      pausedAt: DateTime.now(),
      pauseReason: reason ?? 'Operational pause',
      updatedAt: DateTime.now(),
      version: existing.version + 1,
    );

    _emitUpdatedTasks(tenantId, workerUid, existing.teamId);
  }

  @override
  Future<void> resumeTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  }) async {
    await _maybeDelay();
    final index = _tasks.indexWhere((t) => t.tenantId == tenantId && t.id == taskId);
    if (index == -1) throw Exception('Task $taskId not found');

    final existing = _tasks[index];
    if (existing.workerUid != workerUid) {
      throw Exception('Task is not assigned to current worker');
    }

    _tasks[index] = existing.copyWith(
      status: TaskStatus.inProgress,
      clearPaused: true,
      updatedAt: DateTime.now(),
      version: existing.version + 1,
    );

    _emitUpdatedTasks(tenantId, workerUid, existing.teamId);
  }

  @override
  Future<void> blockTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
    required BlockReason reason,
    String? note,
  }) async {
    await _maybeDelay();
    final index = _tasks.indexWhere((t) => t.tenantId == tenantId && t.id == taskId);
    if (index == -1) throw Exception('Task $taskId not found');

    final existing = _tasks[index];
    if (existing.workerUid != workerUid) {
      throw Exception('Task is not assigned to current worker');
    }

    _tasks[index] = existing.copyWith(
      status: TaskStatus.blocked,
      blockReason: reason,
      blockNote: note,
      blockedAt: DateTime.now(),
      clearPaused: true,
      updatedAt: DateTime.now(),
      version: existing.version + 1,
    );

    _emitUpdatedTasks(tenantId, workerUid, existing.teamId);
  }

  @override
  Future<void> unblockTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  }) async {
    await _maybeDelay();
    final index = _tasks.indexWhere((t) => t.tenantId == tenantId && t.id == taskId);
    if (index == -1) throw Exception('Task $taskId not found');

    final existing = _tasks[index];
    if (existing.workerUid != workerUid) {
      throw Exception('Task is not assigned to current worker');
    }

    _tasks[index] = existing.copyWith(
      status: TaskStatus.inProgress,
      clearBlocked: true,
      clearPaused: true,
      updatedAt: DateTime.now(),
      version: existing.version + 1,
    );

    _emitUpdatedTasks(tenantId, workerUid, existing.teamId);
  }

  void dispose() {
    _streamController.close();
  }
}
