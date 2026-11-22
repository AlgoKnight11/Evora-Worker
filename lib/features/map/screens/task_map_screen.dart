import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../core/widgets/evora_status_badge.dart';
import '../../../domain/enums/worker_enums.dart';
import '../../../domain/models/worker_task.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../routes/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tasks/providers/task_providers.dart';

enum MapFilterScope { all, assigned, urgent }

/// Task Map & Work Area View (`/map`):
/// Displays assigned municipal task pins, authorized service area wards,
/// one-tap external Google Maps navigation launcher, and a resilient offline
/// textual turn-by-turn fallback route for areas without mobile data.
class TaskMapScreen extends ConsumerStatefulWidget {
  const TaskMapScreen({super.key});

  @override
  ConsumerState<TaskMapScreen> createState() => _TaskMapScreenState();
}

class _TaskMapScreenState extends ConsumerState<TaskMapScreen> {
  int _selectedTab = 0; // 0: Visual Map, 1: Turn-by-Turn Route
  MapFilterScope _scope = MapFilterScope.all;
  String? _selectedTaskId;

  Future<void> _launchExternalMaps(double lat, double lng) async {
    final googleMapsDirectionsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    final geoUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');

    try {
      if (await canLaunchUrl(googleMapsDirectionsUri)) {
        await launchUrl(
          googleMapsDirectionsUri,
          mode: LaunchMode.externalApplication,
        );
      } else if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(
          googleMapsDirectionsUri,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      debugPrint('[TaskMapScreen] Failed to launch Google Maps: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(authNotifierProvider).profile;
    final tasksAsync = ref.watch(tasksStreamProvider);
    final workerUid = profile?.uid ?? '';

    final allTasks = tasksAsync.value ?? [];

    // Apply filtering
    final filteredTasks = allTasks.where((task) {
      if (task.status == TaskStatus.submittedForReview) return false;
      return switch (_scope) {
        MapFilterScope.all => true,
        MapFilterScope.assigned => task.workerUid == workerUid,
        MapFilterScope.urgent =>
          task.priority == TaskPriority.p1 || task.isOverdue,
      };
    }).toList();

    // Ensure selected task is valid
    if (_selectedTaskId == null && filteredTasks.isNotEmpty) {
      _selectedTaskId = filteredTasks.first.id;
    } else if (filteredTasks.isNotEmpty &&
        !filteredTasks.any((t) => t.id == _selectedTaskId)) {
      _selectedTaskId = filteredTasks.first.id;
    }

    final selectedTask = filteredTasks
        .where((t) => t.id == _selectedTaskId)
        .firstOrNull;

    final wards = profile?.authorizedServiceAreaIds ?? ['ward-12', 'ward-13', 'ward-14'];
    final criticalCount = allTasks.where((t) => t.priority == TaskPriority.p1).length;
    final overdueCount = allTasks.where((t) => t.isOverdue).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101914) : EvoraColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Service Area & Metrics Header Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2E25) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.share_location_rounded,
                            size: 18, color: EvoraColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${l10n.mapServiceAreaLabel}: ${wards.map((w) => w.toUpperCase().replaceAll('-', ' ')).join(', ')}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : EvoraColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MetricPill(
                          key: const Key('pill_total_pins'),
                          label: l10n.mapTotalTasks,
                          count: filteredTasks.length,
                          color: EvoraColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _MetricPill(
                          key: const Key('pill_critical_pins'),
                          label: l10n.mapCriticalTasks,
                          count: criticalCount,
                          color: EvoraColors.error,
                        ),
                        const SizedBox(width: 8),
                        _MetricPill(
                          key: const Key('pill_overdue_pins'),
                          label: l10n.mapOverdueTasks,
                          count: overdueCount,
                          color: EvoraColors.warmOchre,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. View Mode Tabs (Visual Map vs Turn-by-Turn Route) & Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  // Tab toggle
                  Expanded(
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2922) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              key: const Key('tab_map_visual'),
                              onTap: () => setState(() => _selectedTab = 0),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedTab == 0
                                      ? (isDark ? const Color(0xFF2E3E33) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  l10n.mapTabVisual,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _selectedTab == 0
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _selectedTab == 0
                                        ? EvoraColors.primary
                                        : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              key: const Key('tab_map_directions'),
                              onTap: () => setState(() => _selectedTab = 1),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedTab == 1
                                      ? (isDark ? const Color(0xFF2E3E33) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  l10n.mapTabDirections,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _selectedTab == 1
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _selectedTab == 1
                                        ? EvoraColors.primary
                                        : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Scope Filter Popup
                  PopupMenuButton<MapFilterScope>(
                    key: const Key('btn_map_filter_menu'),
                    initialValue: _scope,
                    onSelected: (scope) => setState(() => _scope = scope),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2E25) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: _scope != MapFilterScope.all
                                ? EvoraColors.primary
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            switch (_scope) {
                              MapFilterScope.all => l10n.mapFilterAll,
                              MapFilterScope.assigned => l10n.mapFilterAssigned,
                              MapFilterScope.urgent => l10n.mapFilterUrgent,
                            },
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _scope != MapFilterScope.all
                                  ? EvoraColors.primary
                                  : (isDark ? Colors.white : EvoraColors.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        key: const Key('filter_scope_all'),
                        value: MapFilterScope.all,
                        child: Text(l10n.mapFilterAll),
                      ),
                      PopupMenuItem(
                        key: const Key('filter_scope_assigned'),
                        value: MapFilterScope.assigned,
                        child: Text(l10n.mapFilterAssigned),
                      ),
                      PopupMenuItem(
                        key: const Key('filter_scope_urgent'),
                        value: MapFilterScope.urgent,
                        child: Text(l10n.mapFilterUrgent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 3. Tab Body
            Expanded(
              child: filteredTasks.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_off_rounded,
                                size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            Text(
                              l10n.mapNoAssignedTasks,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : EvoraColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _selectedTab == 0
                      ? _buildVisualMapView(
                          context, filteredTasks, selectedTask, isDark, l10n)
                      : _buildTurnByTurnRouteView(
                          context, filteredTasks, isDark, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualMapView(
    BuildContext context,
    List<WorkerTask> tasks,
    WorkerTask? selectedTask,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        // Visual Map Surface with Coordinate Plotting
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                key: const Key('container_interactive_map'),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14241B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Stack(
                  children: [
                    // Grid & Map Coordinate Canvas
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MapCanvasPainter(isDark: isDark),
                      ),
                    ),

                    // Compass North indicator
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black : Colors.white)
                              .withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.navigation_rounded,
                                size: 14, color: EvoraColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'N',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : EvoraColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Plot Interactive Task Pins
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: tasks.asMap().entries.map((entry) {
                            final index = entry.key;
                            final task = entry.value;
                            final isSelected = task.id == selectedTask?.id;

                            // Compute deterministic coordinate offset inside the box
                            final double xRatio = ((task.location.longitude * 1000) % 80 + 10) / 100;
                            final double yRatio = ((task.location.latitude * 1000) % 70 + 15) / 100;

                            final posX = xRatio * (constraints.maxWidth - 44);
                            final posY = yRatio * (constraints.maxHeight - 54);

                            return Positioned(
                              left: posX,
                              top: posY,
                              child: GestureDetector(
                                key: Key('task_pin_${task.id}'),
                                onTap: () =>
                                    setState(() => _selectedTaskId = task.id),
                                child: _TaskPinWidget(
                                  task: task,
                                  index: index + 1,
                                  isSelected: isSelected,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Selected Pin Preview Card at Bottom
        if (selectedTask != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Container(
              key: const Key('card_selected_task_preview'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2E25) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      TaskStatusBadge(status: selectedTask.status),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: selectedTask.priority == TaskPriority.p1
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: selectedTask.priority == TaskPriority.p1
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          selectedTask.priority.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: selectedTask.priority == TaskPriority.p1
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        selectedTask.wardId.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: EvoraColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedTask.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : EvoraColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          selectedTask.location.landmark ??
                              selectedTask.location.addressSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          key: const Key('btn_map_navigate'),
                          onPressed: () => _launchExternalMaps(
                            selectedTask.location.latitude,
                            selectedTask.location.longitude,
                          ),
                          icon: const Icon(Icons.navigation_rounded, size: 16),
                          label: Text(
                            l10n.mapLaunchExternalNavigation,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EvoraColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          key: const Key('btn_map_view_details'),
                          onPressed: () {
                            context.go(WorkerRoutes.taskDetail(selectedTask.id));
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? Colors.white
                                : EvoraColors.onSurface,
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : const Color(0xFFCBD5E1),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTurnByTurnRouteView(
    BuildContext context,
    List<WorkerTask> tasks,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return ListView.separated(
      key: const Key('list_turn_by_turn_route'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final stopNumber = index + 1;

        return Container(
          key: Key('route_stop_$stopNumber'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2E25) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: EvoraColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$stopNumber',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.mapStepTitle(stopNumber, task.title),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : EvoraColors.onSurface,
                          ),
                        ),
                        if (task.location.landmark != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            l10n.mapStepLandmark(task.location.landmark!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  TaskStatusBadge(status: task.status),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.explore_outlined,
                        size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'GPS (${task.location.latitude.toStringAsFixed(4)}, ${task.location.longitude.toStringAsFixed(4)}) • ${task.wardId}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: Key('btn_route_navigate_$stopNumber'),
                      onPressed: () => _launchExternalMaps(
                        task.location.latitude,
                        task.location.longitude,
                      ),
                      icon: const Icon(Icons.directions_rounded, size: 16),
                      label: Text(
                        l10n.mapLaunchExternalNavigation,
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EvoraColors.primary,
                        side: const BorderSide(color: EvoraColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: Key('btn_route_detail_$stopNumber'),
                    tooltip: 'View Details',
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    color: EvoraColors.primary,
                    onPressed: () {
                      context.go(WorkerRoutes.taskDetail(task.id));
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _MetricPill({
    super.key,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskPinWidget extends StatelessWidget {
  final WorkerTask task;
  final int index;
  final bool isSelected;

  const _TaskPinWidget({
    required this.task,
    required this.index,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final pinColor = task.priority == TaskPriority.p1
        ? const Color(0xFFDC2626)
        : task.priority == TaskPriority.p2
            ? const Color(0xFFEA580C)
            : EvoraColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 40 : 32,
          height: isSelected ? 40 : 32,
          decoration: BoxDecoration(
            color: pinColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: pinColor.withValues(alpha: isSelected ? 0.45 : 0.25),
                blurRadius: isSelected ? 8 : 4,
                spreadRadius: isSelected ? 2 : 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: TextStyle(
              fontSize: isSelected ? 14 : 11.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        Icon(
          Icons.arrow_drop_down_rounded,
          size: 18,
          color: pinColor,
        ),
      ],
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  final bool isDark;

  _MapCanvasPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 1;

    // Draw coordinate grid lines
    const double step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw municipal ward boundary dashed polygon
    final boundaryPaint = Paint()
      ..color = EvoraColors.primary.withValues(alpha: isDark ? 0.35 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.20)
      ..lineTo(size.width * 0.85, size.height * 0.15)
      ..lineTo(size.width * 0.88, size.height * 0.78)
      ..lineTo(size.width * 0.20, size.height * 0.82)
      ..close();

    canvas.drawPath(path, boundaryPaint);
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
