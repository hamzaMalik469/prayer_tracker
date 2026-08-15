library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:prayers_tracker_plus/features/settings/presentation/pages/custom_prayer_times_page.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/pages/notification_settings_page.dart';
import '../../../prayer_times/presentation/providers/next_prayer_provider.dart';
import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';
import '../../domain/entities/location_settings_entity.dart';
import '../../domain/entities/prayer_settings_entity.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const _SettingsBody(),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        // ── Prayer Calculation ─────────────────────────────────────────
        _Header('Prayer Calculation'),

        ListTile(
          leading: const Icon(Icons.calculate_outlined),
          title: const Text('Calculation Method'),
          subtitle: Text(settings.prayerSettings.calculationMethod.displayName),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showSelection<CalculationMethodEntity>(
            context: context,
            title: 'Calculation Method',
            values: CalculationMethodEntity.values,
            selected: settings.prayerSettings.calculationMethod,
            labelOf: (m) => m.displayName,
            onSelected: (method) async {
              await settings.updatePrayerSettings(
                settings.prayerSettings.copyWith(calculationMethod: method),
              );
              if (!context.mounted) return;
              await _recalculate(context);
              if (!context.mounted) return;
              AppSnackbar.showSuccess(
                context,
                'Calculation method updated.',
              );
            },
          ),
        ),

        ListTile(
          leading: const Icon(Icons.mosque_outlined),
          title: const Text('Madhab'),
          // subtitle: Text(settings.prayerSettings.madhab.displayName),
          subtitle: Text(
            '${settings.prayerSettings.madhab.displayName} — affects Asr time',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showSelection<MadhabEntity>(
            context: context,
            title: 'Madhab',
            values: MadhabEntity.values,
            selected: settings.prayerSettings.madhab,
            labelOf: (m) => m.displayName,
            onSelected: (madhab) async {
              await settings.updatePrayerSettings(
                settings.prayerSettings.copyWith(madhab: madhab),
              );
              if (!context.mounted) return;
              await _recalculate(context);
              if (!context.mounted) return;
              AppSnackbar.showSuccess(context, 'Madhab updated.');
            },
          ),
        ),

        ListTile(
          leading: const Icon(Icons.north_outlined),
          title: const Text('High Latitude Rule'),
          subtitle: Text(settings.prayerSettings.highLatitudeRule.displayName),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showSelection<HighLatitudeRuleEntity>(
            context: context,
            title: 'High Latitude Rule',
            values: HighLatitudeRuleEntity.values,
            selected: settings.prayerSettings.highLatitudeRule,
            labelOf: (r) => r.displayName,
            descriptionOf: (r) => _highLatDesc(r),
            onSelected: (rule) async {
              await settings.updatePrayerSettings(
                settings.prayerSettings.copyWith(highLatitudeRule: rule),
              );
              if (!context.mounted) return;
              await _recalculate(context);
              if (!context.mounted) return;
              AppSnackbar.showSuccess(context, 'High latitude rule updated.');
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.edit_calendar_rounded),
          title: const Text('Custom Prayer Times'),
          subtitle: const Text('Override calculated times manually'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CustomPrayerTimesPage(),
            ),
          ),
        ),

        // ── Location ───────────────────────────────────────────────────
        _Header('Location'),

        ListTile(
          leading: Icon(
            settings.locationSettings.mode == LocationMode.automatic
                ? Icons.my_location_rounded
                : Icons.location_on_outlined,
            color: colorScheme.primary,
          ),
          title: Text(
            settings.locationSettings.mode == LocationMode.automatic
                ? 'Automatic Location'
                : 'Manual Location',
          ),
          subtitle: Text(
            settings.locationSettings.cityName != null &&
                    settings.locationSettings.cityName!.isNotEmpty
                ? '${settings.locationSettings.cityName} '
                    '(${settings.locationSettings.latitude.toStringAsFixed(4)}, '
                    '${settings.locationSettings.longitude.toStringAsFixed(4)})'
                : '${settings.locationSettings.latitude.toStringAsFixed(4)}, '
                    '${settings.locationSettings.longitude.toStringAsFixed(4)}',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showLocationSheet(context, settings),
        ),

        // ── Appearance ─────────────────────────────────────────────────
        _Header('Appearance'),

        ListTile(
          leading: const Icon(Icons.brightness_6_outlined),
          title: const Text('Theme'),
          subtitle: Text(_themeName(settings.themeMode)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showSelection<ThemeMode>(
            context: context,
            title: 'Theme',
            values: ThemeMode.values,
            selected: settings.themeMode,
            labelOf: (m) => _themeName(m),
            onSelected: (mode) async {
              await settings.updateThemeMode(mode);
            },
          ),
        ),

        // ── Notifications ──────────────────────────────────────────────
        _Header('Notifications'),

        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Prayer Notifications'),
          subtitle: const Text('Configure reminders for each prayer'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const NotificationSettingsPage(),
            ),
          ),
        ),

        // ── Account ────────────────────────────────────────────────────
        _Header('Account'),

        if (auth.isAuthenticated) ...[
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                (auth.user?.displayName?.isNotEmpty == true
                        ? auth.user!.displayName![0]
                        : auth.user?.email?[0] ?? 'U')
                    .toUpperCase(),
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(
              auth.user?.displayName?.isNotEmpty == true
                  ? auth.user!.displayName!
                  : 'User',
            ),
            subtitle: auth.user?.email != null ? Text(auth.user!.email) : null,
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sign Out'),
            onTap: () => _confirmSignOut(context),
          ),
          ListTile(
            leading:
                Icon(Icons.delete_outline_rounded, color: colorScheme.error),
            title: Text('Delete Account',
                style: TextStyle(color: colorScheme.error)),
            onTap: () => _confirmDeleteAccount(context),
          ),
        ] else ...[
          ListTile(
            leading: Icon(Icons.login_rounded, color: colorScheme.primary),
            title: const Text('Sign In / Create Account'),
            subtitle: const Text('Sync prayers across devices'),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.login),
          ),
        ],

        // ── Privacy ────────────────────────────────────────────────────
        _Header('Privacy & Data'),

        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('What data we collect'),
          onTap: () => _showPrivacyDialog(context),
        ),

        ListTile(
          leading: Icon(Icons.delete_sweep_outlined, color: colorScheme.error),
          title: Text('Clear Local Data',
              style: TextStyle(color: colorScheme.error)),
          subtitle: const Text('Removes locally cached data from this device'),
          onTap: () => _confirmClearLocal(context),
        ),

        // ── App info ───────────────────────────────────────────────────
        _Header('About'),

        ListTile(
          leading: const Icon(Icons.info_outline_rounded),
          title: const Text('Daily Deen'),
          subtitle: const Text('Prayer tracking for Muslims'),
        ),

        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Recalculates prayer times after any setting change.
  Future<void> _recalculate(BuildContext context) async {
    final s = context.read<SettingsProvider>();
    final timesProvider = context.read<PrayerTimesProvider>();
    final nextPrayer = context.read<NextPrayerProvider>();

    await timesProvider.calculatePrayerTimes(
      location: s.locationSettings,
      settings: s.prayerSettings,
    );

    await nextPrayer.start(
      location: s.locationSettings,
      settings: s.prayerSettings,
    );
  }

  String _themeName(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System default',
      };

  String _highLatDesc(HighLatitudeRuleEntity r) => switch (r) {
        HighLatitudeRuleEntity.none =>
          'No adjustment (recommended for most locations)',
        HighLatitudeRuleEntity.middleOfTheNight =>
          'Use this for latitudes above ~48°',
        HighLatitudeRuleEntity.seventhOfTheNight =>
          'Use this for very high latitudes',
        HighLatitudeRuleEntity.twilightAngle => 'Based on twilight angle',
      };

  // ── Location sheet ─────────────────────────────────────────────────────────

  void _showLocationSheet(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _LocationSheet(settings: settings),
    );
  }

  // ── Generic selection sheet ────────────────────────────────────────────────

  void _showSelection<T>({
    required BuildContext context,
    required String title,
    required List<T> values,
    required T selected,
    required String Function(T) labelOf,
    String? Function(T)? descriptionOf,
    required void Function(T) onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                title,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: values.map((value) {
                  final isSelected = value == selected;
                  final desc = descriptionOf?.call(value);
                  return Semantics(
                    selected: isSelected,
                    child: ListTile(
                      title: Text(
                        labelOf(value),
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      subtitle: desc != null ? Text(desc) : null,
                      trailing: isSelected
                          ? Icon(Icons.check_rounded,
                              color: colorScheme.primary)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        onSelected(value);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthProvider>().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text('Delete Account', style: TextStyle(color: colorScheme.error)),
        content: const Text(
          'This permanently deletes your account and all prayer data. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final success = await context.read<AuthProvider>().deleteAccount();
    if (!context.mounted) return;
    if (success) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    } else {
      AppSnackbar.showError(
        context,
        'Could not delete account. Please sign in again and try.',
      );
    }
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your Privacy'),
        content: const SingleChildScrollView(
          child: Text(
            'Daily Deen collects:\n\n'
            '• Prayer tracking records\n'
            '• App settings and preferences\n'
            '• Account email and display name\n\n'
            'Daily Deen does NOT collect:\n\n'
            '• Continuous location data\n'
            '• Precise location history\n'
            '• Prayer behavior for advertising\n'
            '• Any data sold to third parties\n\n'
            'Your location is used only to calculate prayer times '
            'and is stored locally on your device.\n\n'
            'You can delete all your data at any time.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearLocal(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Local Data'),
        content: const Text(
          'This removes cached data from this device. '
          'Your cloud data remains safe if you are signed in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<SettingsProvider>().updatePrayerSettings(
            const PrayerSettingsEntity.defaults(),
          );
      if (!context.mounted) return;
      AppSnackbar.showSuccess(context, 'Local data cleared.');
    }
  }
}

// ── Location Sheet ────────────────────────────────────────────────────────────

class _LocationSheet extends StatefulWidget {
  const _LocationSheet({required this.settings});

  final SettingsProvider settings;

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  late LocationMode _mode;
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isLocating = false;
  String? _statusMsg;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    final loc = widget.settings.locationSettings;
    _mode = loc.mode;
    _latController.text = loc.latitude.toString();
    _lngController.text = loc.longitude.toString();
    _cityController.text = loc.cityName ?? '';
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isLocating = true;
      _statusMsg = null;
    });

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.deniedForever) {
        setState(() {
          _isLocating = false;
          _isError = true;
          _statusMsg =
              'Permission permanently denied. Enable in device Settings.';
        });
        return;
      }

      if (perm == LocationPermission.denied) {
        setState(() {
          _isLocating = false;
          _isError = true;
          _statusMsg = 'Location permission denied.';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
        // locationSettings: const LocationSettings(
        //   accuracy: LocationAccuracy.medium,
        //   timeLimit: Duration(seconds: 15),
        // ),
      );

      setState(() {
        _isLocating = false;
        _isError = false;
        _mode = LocationMode.automatic;
        _latController.text = pos.latitude.toStringAsFixed(6);
        _lngController.text = pos.longitude.toStringAsFixed(6);
        _statusMsg = 'Location detected: ${pos.latitude.toStringAsFixed(4)}, '
            '${pos.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      setState(() {
        _isLocating = false;
        _isError = true;
        _statusMsg = 'Could not detect location. Enter manually below.';
      });
    }
  }

  Future<void> _save() async {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (lat == null || lng == null) {
      setState(() {
        _isError = true;
        _statusMsg = 'Please enter valid latitude and longitude.';
      });
      return;
    }

    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      setState(() {
        _isError = true;
        _statusMsg = 'Latitude: -90 to 90. Longitude: -180 to 180.';
      });
      return;
    }

    final newLocation = LocationSettingsEntity(
      mode: _mode,
      latitude: lat,
      longitude: lng,
      cityName: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
    );

    await widget.settings.updateLocationSettings(newLocation);

    if (!mounted) return;

    // Recalculate prayer times immediately.
    final timesProvider = context.read<PrayerTimesProvider>();
    final nextProvider = context.read<NextPrayerProvider>();

    await timesProvider.calculatePrayerTimes(
      location: newLocation,
      settings: widget.settings.prayerSettings,
    );

    if (!mounted) return;

    await nextProvider.start(
      location: newLocation,
      settings: widget.settings.prayerSettings,
    );

    if (!mounted) return;

    Navigator.pop(context);
    AppSnackbar.showSuccess(context, 'Location saved. Prayer times updated.');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              'Location',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Prayer times are calculated from your coordinates. '
              'Your location is stored only on your device.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Mode toggle
            SegmentedButton<LocationMode>(
              segments: const [
                ButtonSegment(
                  value: LocationMode.automatic,
                  label: Text('Automatic'),
                  icon: Icon(Icons.my_location_rounded, size: 16),
                ),
                ButtonSegment(
                  value: LocationMode.manual,
                  label: Text('Manual'),
                  icon: Icon(Icons.edit_location_rounded, size: 16),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Auto detect button
            if (_mode == LocationMode.automatic) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLocating ? null : _detectLocation,
                  icon: _isLocating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.my_location_rounded),
                  label:
                      Text(_isLocating ? 'Detecting…' : 'Detect My Location'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Status message
            if (_statusMsg != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: _isError
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: _isError
                          ? colorScheme.onErrorContainer
                          : colorScheme.onPrimaryContainer,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _statusMsg!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _isError
                                  ? colorScheme.onErrorContainer
                                  : colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

            // Coordinates
            TextField(
              controller: _cityController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'City name (optional)',
                hintText: 'e.g. London, Cairo, Karachi',
                prefixIcon: Icon(Icons.location_city_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: '51.5074',
                      prefixIcon: Icon(Icons.arrow_upward_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: _lngController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: '-0.1278',
                      prefixIcon: Icon(Icons.arrow_forward_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Latitude: -90 to +90   ·   Longitude: -180 to +180',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Location'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
