/// Canonical Municipal Taxonomy Bridge harmonizing department identifiers
/// and taxonomy strings between Citizen Grievance Submissions and Field Worker Portals.
class MunicipalTaxonomyBridge {
  MunicipalTaxonomyBridge._();

  static const String deptSwm = 'dept-swm';
  static const String deptPwd = 'dept-pwd';
  static const String deptDrainage = 'dept-drainage';
  static const String deptElectricity = 'dept-electricity';
  static const String deptWater = 'dept-water';
  static const String deptSanitation = 'dept-sanitation';
  static const String deptGeneral = 'dept-general';

  /// Maps any department name, category, or ID from either Citizen or Worker app
  /// to its canonical municipal department ID.
  static String canonicalize(String? input) {
    if (input == null || input.trim().isEmpty) {
      return deptGeneral;
    }
    final clean = input.trim().toLowerCase();

    // Solid Waste Management (Nagar Nigam Sanitation & SWM)
    if (clean == 'dept-swm' ||
        clean.contains('solid waste') ||
        clean.contains('swm') ||
        clean.contains('garbage') ||
        clean.contains('trash') ||
        clean.contains('sanitation & swm') ||
        clean.contains('dead animal') ||
        clean.contains('waste dumping')) {
      return deptSwm;
    }

    // Roads & Footpaths (PWD / Road Engineering Wing)
    if (clean == 'dept-pwd' ||
        clean.contains('pwd') ||
        clean.contains('road') ||
        clean.contains('footpath') ||
        clean.contains('pothole') ||
        clean.contains('manhole') ||
        clean.contains('cave-in')) {
      return deptPwd;
    }

    // Stormwater & Drainage Wing
    if (clean == 'dept-drainage' ||
        clean.contains('drain') ||
        clean.contains('stormwater') ||
        clean.contains('waterlog') ||
        clean.contains('sewage')) {
      return deptDrainage;
    }

    // Electricity & Street Lighting Wing
    if (clean == 'dept-electricity' ||
        clean.contains('light') ||
        clean.contains('electric') ||
        clean.contains('lamp') ||
        clean.contains('pole') ||
        clean.contains('wiring')) {
      return deptElectricity;
    }

    // Water Supply (Uttarakhand Jal Sansthan)
    if (clean == 'dept-water' ||
        clean.contains('jal sansthan') ||
        clean.contains('water supply') ||
        clean.contains('pipeline') ||
        clean.contains('tap water')) {
      return deptWater;
    }

    // Public Health & Sanitation Cell
    if (clean == 'dept-sanitation' ||
        clean.contains('public health') ||
        clean.contains('public toilet') ||
        clean.contains('open urination')) {
      return deptSanitation;
    }

    return clean;
  }

  /// Determines if a task's department or category matches the worker's assigned department.
  ///
  /// Returns `true` if:
  /// 1. The worker has no department specified (e.g. general multi-department supervisor).
  /// 2. The task is explicitly assigned to this worker or team (checked upstream).
  /// 3. The canonical department of the task matches the canonical department of the worker.
  /// 4. As a fallback, the canonical department of the task's category matches the worker.
  static bool matchesWorkerDepartment({
    required String? workerDepartment,
    required String? taskDepartment,
    String? taskCategory,
  }) {
    if (workerDepartment == null || workerDepartment.trim().isEmpty) {
      return true; // Unassigned supervisor sees all municipal tasks
    }

    final workerCanonical = canonicalize(workerDepartment);

    final taskDeptCanonical = canonicalize(taskDepartment);
    if (workerCanonical == taskDeptCanonical) {
      return true;
    }

    if (taskCategory != null && taskCategory.trim().isNotEmpty) {
      final taskCatCanonical = canonicalize(taskCategory);
      if (workerCanonical == taskCatCanonical) {
        return true;
      }
    }

    return false;
  }
}
