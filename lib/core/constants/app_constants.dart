/// Operational constants and MVP configuration defaults for Evora-Workers.
class AppConstants {
  AppConstants._();

  static const String appName = 'Evora-Workers';

  // Local persistence keys (SharedPreferences)
  static const String prefLocaleCode = 'evora_workers_locale_code';
  static const String prefHasSelectedLanguage = 'evora_workers_has_selected_language';

  // Evidence constraints (Part IV Decisions)
  static const int maxPhotoSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxPdfSizeBytes = 20 * 1024 * 1024; // 20 MB
  static const int minBeforePhotos = 0;
  static const int maxBeforePhotos = 5;
  static const int minAfterPhotos = 1;
  static const int maxAfterPhotos = 5;
  static const List<String> allowedPhotoMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];
  static const List<String> allowedDocMimeTypes = [
    'application/pdf',
  ];

  // Offline PWA cache policy
  static const Duration defaultOfflineCacheTtl = Duration(hours: 24);

  // Accessibility minimum touch target
  static const double minTouchTargetSize = 48.0;

  // Brand logo asset paths (shared with Evora-Citizen)
  static const String logoFullAsset = 'assets/images/evora_logo_transparent_clean.png';
  static const String logoCroppedAsset = 'assets/images/evora_logo_cropped_transparent.png';
  static const String leafBadgeAsset = 'assets/images/evora_leaf_badge.png';
}
