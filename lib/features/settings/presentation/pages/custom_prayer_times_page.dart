library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../prayer_times/data/datasources/prayer_times_custom_datasource.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../../prayer_times/presentation/providers/next_prayer_provider.dart';
import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';
import '../../presentation/providers/settings_provider.dart';

class CustomPrayerTimesPage extends StatefulWidget {
  const CustomPrayerTimesPage({super.key});

  @override
  State<CustomPrayerTimesPage> createState() => _CustomPrayerTimesPageState();
}

class _CustomPrayerTimesPageState extends State<CustomPrayerTimesPage> {
  final _controllers = <String, TextEditingController>{};
  bool _isLoading = true;
  bool _hasCustom = false;

  @override
  void initState() {
    super.initState();
    for (final id in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      _controllers[id] = TextEditingController();
    }
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final ds = sl<PrayerTimesCustomDataSource>();
    final times = await ds.getCustomTimes();

    if (times != null) {
      _hasCustom = true;
      for (final entry in times.entries) {
        _controllers[entry.key]?.text = entry.value;
      }
    } else {
      // Pre-fill with calculated start times as a helpful starting point
      final timesProvider = context.read<PrayerTimesProvider>();
      final today = timesProvider.todayTimes;
      if (today != null) {
        for (final prayer in today.obligatory) {
          _controllers[prayer.prayerType.identifier]?.text =
              _formatHHMM(prayer.time);
        }
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  String _formatHHMM(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    final times = <String, String>{};
    for (final entry in _controllers.entries) {
      final value = entry.value.text.trim();
      if (value.isEmpty) continue;

      final parts = value.split(':');
      if (parts.length != 2) {
        AppSnackbar.showError(context,
            'Use HH:MM 24-hr format for ${entry.key.toUpperCase()} (e.g. 13:45).');
        return;
      }
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
        AppSnackbar.showError(
            context, 'Invalid time bounds for ${entry.key.toUpperCase()}.');
        return;
      }
      times[entry.key] = value;
    }

    final ds = sl<PrayerTimesCustomDataSource>();
    await ds.saveCustomTimes(times);

    if (!mounted) return;

    // Recalculate
    final settings = context.read<SettingsProvider>();
    await context.read<PrayerTimesProvider>().calculatePrayerTimes(
          location: settings.locationSettings,
          settings: settings.prayerSettings,
        );
    if (!mounted) return;
    await context.read<NextPrayerProvider>().start(
          location: settings.locationSettings,
          settings: settings.prayerSettings,
        );

    if (!mounted) return;
    AppSnackbar.showSuccess(context, 'Mosque Jama\'ah timings saved.');
    Navigator.pop(context);
  }

  Future<void> _clearCustom() async {
    final ds = sl<PrayerTimesCustomDataSource>();
    await ds.clearCustomTimes();

    if (!mounted) return;

    final settings = context.read<SettingsProvider>();
    await context.read<PrayerTimesProvider>().calculatePrayerTimes(
          location: settings.locationSettings,
          settings: settings.prayerSettings,
        );

    if (!mounted) return;
    AppSnackbar.showSuccess(context, 'Reset to calculated timings.');
    Navigator.pop(context);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mosque Jama\'ah Times'),
        actions: [
          if (_hasCustom)
            TextButton(
              onPressed: _clearCustom,
              child:
                  Text('Reset All', style: TextStyle(color: colorScheme.error)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people_alt_rounded,
                          color: colorScheme.onPrimaryContainer, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Configure the congregational (Iqamah) times '
                          'set by your local mosque. '
                          'These timings will display beautifully on the Home Screen card list.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    height: 1.5,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Manual timings inputs
                ..._buildFields(),

                const SizedBox(height: AppSpacing.xl),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Save Jama\'ah Times'),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildFields() {
    final labels = {
      'fajr': 'Fajr Jama\'ah',
      'dhuhr': 'Dhuhr Jama\'ah',
      'asr': 'Asr Jama\'ah',
      'maghrib': 'Maghrib Jama\'ah',
      'isha': 'Isha Jama\'ah',
    };

    return labels.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: TextField(
          controller: _controllers[entry.key],
          keyboardType: TextInputType.datetime,
          decoration: InputDecoration(
            labelText: entry.value,
            hintText: 'HH:MM (24-hr format)',
            prefixIcon: Icon(_iconFor(entry.key)),
          ),
        ),
      );
    }).toList();
  }

  IconData _iconFor(String prayer) => switch (prayer) {
        'fajr' => Icons.dark_mode_outlined,
        'dhuhr' => Icons.light_mode_outlined,
        'asr' => Icons.wb_cloudy_outlined,
        'maghrib' => Icons.nights_stay_outlined,
        'isha' => Icons.bedtime_outlined,
        _ => Icons.access_time_rounded,
      };
}
