import 'dart:async';
import '../../../domain/models/worker_profile.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'firebase_auth_service.dart';

/// Mock authentication service for tests and offline development.
class MockAuthService implements AuthRepository {
  final bool simulateDelay;
  WorkerProfile? _currentProfile;
  final StreamController<WorkerProfile?> _profileController =
      StreamController<WorkerProfile?>.broadcast();

  MockAuthService({this.simulateDelay = false});

  static const String _defaultTenant = 'tenant_dehradun_01';

  // Pre-configured test workers
  static final Map<String, WorkerProfile> mockDirectory = {
    '+919999999999': const WorkerProfile(
      uid: 'mock-worker-rajesh-001',
      tenantId: _defaultTenant,
      employeeCode: 'EVR-SWM-4091',
      displayName: 'Rajesh Kumar',
      phoneNumber: '+919999999999',
      departmentId: 'dept-swm',
      departmentName: 'Solid Waste Management',
      teamId: 'crew-alpha-12',
      teamName: 'Doon Valley Sanitation Crew',
      authorizedServiceAreaIds: ['dehradun-central', 'rajpur-road', 'doon-valley'],
      supervisorName: 'Sanjay Sharma (Sanitation Officer)',
      supervisorPhone: '+919412000001',
      isActive: true,
      isContractor: false,
    ),
    '+919876543210': const WorkerProfile(
      uid: 'mock-worker-sunita-002',
      tenantId: _defaultTenant,
      employeeCode: 'EVR-WTR-2044',
      displayName: 'Sunita Sharma',
      phoneNumber: '+919876543210',
      departmentId: 'dept-water',
      departmentName: 'Water Supply & Sewerage',
      teamId: 'crew-beta-04',
      teamName: 'Jakhu Pipeline Maintenance',
      authorizedServiceAreaIds: ['ward-04', 'ward-05'],
      supervisorName: 'Anil Chauhan (Executive Engineer)',
      supervisorPhone: '+919816000002',
      isActive: true,
      isContractor: false,
    ),
    '+919111111111': const WorkerProfile(
      uid: 'mock-worker-inactive-003',
      tenantId: _defaultTenant,
      employeeCode: 'EVR-INACTIVE',
      displayName: 'Deactivated Worker',
      phoneNumber: '+919111111111',
      departmentId: 'dept-swm',
      departmentName: 'Solid Waste Management',
      isActive: false,
    ),
  };

  @override
  Stream<WorkerProfile?> watchActiveWorker() => _profileController.stream;

  @override
  Future<void> requestOtp({required String phoneNumber}) async {
    if (simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  @override
  Future<WorkerProfile> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    String? verificationId,
  }) async {
    if (simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    final normalized = FirebaseAuthService.normalizePhoneNumber(phoneNumber);

    if (otpCode.trim() != '123456') {
      throw Exception('Invalid OTP code. For test number, use 123456.');
    }

    final worker = mockDirectory[normalized];
    if (worker == null || !worker.isActive) {
      throw UnregisteredWorkerException(normalized);
    }

    _currentProfile = worker;
    _profileController.add(worker);
    return worker;
  }

  @override
  Future<bool> validateActiveSession() async {
    return _currentProfile != null && _currentProfile!.isActive;
  }

  @override
  Future<void> signOutAndPurgeCache() async {
    _currentProfile = null;
    _profileController.add(null);
  }

  void dispose() {
    _profileController.close();
  }
}
