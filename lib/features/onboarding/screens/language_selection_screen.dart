import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

/// First-launch language picker asking the worker to choose English or Hindi.
/// Selection is persisted locally and can be changed anytime in Profile & Help.
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  late Locale _selectedLocale;

  @override
  void initState() {
    super.initState();
    _selectedLocale = ref.read(localeProvider).locale;
  }

  Future<void> _onContinue() async {
    await ref.read(localeProvider.notifier).selectLanguage(_selectedLocale);
    if (mounted) {
      context.go('/overview');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isHindiSelected = _selectedLocale.languageCode == 'hi';

    return Scaffold(
      backgroundColor: EvoraColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Official EVORA Brand Header
                  Center(
                    child: Image.asset(
                      AppConstants.logoCroppedAsset,
                      height: 64,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.eco_rounded,
                        size: 56,
                        color: EvoraColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: EvoraColors.successContainer,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: EvoraColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.engineering_rounded,
                            size: 16,
                            color: EvoraColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppConstants.appName,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: EvoraColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bilingual Title & Explanation
                  Text(
                    isHindiSelected
                        ? 'अपनी भाषा चुनें'
                        : l10n.languageSelectTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isHindiSelected
                        ? 'Choose Your Language'
                        : 'अपनी भाषा चुनें',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: EvoraColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isHindiSelected
                        ? 'Evora-Workers के लिए अपनी पसंदीदा भाषा चुनें। आप इसे कभी भी प्रोफ़ाइल और सहायता में बदल सकते हैं।'
                        : l10n.languageSelectSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: EvoraColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // English Option Card
                  _LanguageOptionCard(
                    key: const Key('lang_option_en'),
                    title: 'English',
                    subtitle: 'Continue in English',
                    badgeText: 'EN',
                    selected: !isHindiSelected,
                    onTap: () {
                      setState(() {
                        _selectedLocale = SupportedWorkerLocales.english;
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // Hindi Option Card
                  _LanguageOptionCard(
                    key: const Key('lang_option_hi'),
                    title: 'हिन्दी (Hindi)',
                    subtitle: 'हिन्दी में जारी रखें',
                    badgeText: 'हि',
                    selected: isHindiSelected,
                    onTap: () {
                      setState(() {
                        _selectedLocale = SupportedWorkerLocales.hindi;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // Continue CTA
                  ElevatedButton.icon(
                    key: const Key('lang_continue_button'),
                    onPressed: _onContinue,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: Text(
                      isHindiSelected ? 'जारी रखें' : l10n.languageContinue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isHindiSelected
                        ? 'हरित विकल्प। स्वस्थ शहर।'
                        : l10n.brandTagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: EvoraColors.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? EvoraColors.successContainer.withValues(alpha: 0.65)
          : EvoraColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? EvoraColors.primary : EvoraColors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? EvoraColors.primary
                      : EvoraColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? EvoraColors.onPrimary
                        : EvoraColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: EvoraColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: EvoraColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? EvoraColors.primary : EvoraColors.outline,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
