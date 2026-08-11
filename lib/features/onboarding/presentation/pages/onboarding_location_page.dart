library;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../settings/domain/entities/location_settings_entity.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/onboarding_provider.dart';

class OnboardingLocationPage extends StatefulWidget {
  const OnboardingLocationPage({super.key});

  @override
  State<OnboardingLocationPage> createState() => _OnboardingLocationPageState();
}

class _OnboardingLocationPageState extends State<OnboardingLocationPage> {
  bool _isLocating = false;
  String? _locationError;
  String? _locationSuccess;

  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _cityController = TextEditingController();
  bool _showManual = false;

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _requestLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
      _locationSuccess = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permission was permanently denied. '
              'Please enable it in your device settings, '
              'or enter your location manually below.';
          _isLocating = false;
          _showManual = true;
        });
        return;
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Location permission denied. '
              'Please grant permission or enter location manually.';
          _isLocating = false;
          _showManual = true;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15)
          // locationSettings: const LocationSettings(
          //   accuracy: LocationAccuracy.medium,
          //   timeLimit: Duration(seconds: 15),
          // ),
          );

      final locationSettings = LocationSettingsEntity(
        mode: LocationMode.automatic,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      await context
          .read<SettingsProvider>()
          .updateLocationSettings(locationSettings);

      context.read<OnboardingProvider>().markLocationConfigured();

      setState(() {
        _isLocating = false;
        _locationSuccess = 'Location detected: '
            '${position.latitude.toStringAsFixed(4)}, '
            '${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      setState(() {
        _isLocating = false;
        _locationError = 'Could not detect location. '
            'Please enter your location manually.';
        _showManual = true;
      });
    }
  }

  Future<void> _saveManualLocation() async {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (lat == null || lng == null) {
      setState(() {
        _locationError = 'Please enter valid latitude and longitude values.';
      });
      return;
    }

    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      setState(() {
        _locationError = 'Latitude must be between -90 and 90. '
            'Longitude must be between -180 and 180.';
      });
      return;
    }

    final locationSettings = LocationSettingsEntity(
      mode: LocationMode.manual,
      latitude: lat,
      longitude: lng,
      cityName: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
    );

    await context
        .read<SettingsProvider>()
        .updateLocationSettings(locationSettings);

    if (!mounted) return;
    context.read<OnboardingProvider>().markLocationConfigured();

    setState(() {
      _locationError = null;
      _locationSuccess = 'Location saved manually.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Your Location',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Prayer times are calculated from your location. '
            'Your precise location is never shared.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Auto detect
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLocating ? null : _requestLocation,
              icon: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: AppLoadingIndicator(size: 18),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(
                _isLocating ? 'Detecting…' : 'Use My Location',
              ),
            ),
          ),

          if (_locationSuccess != null) ...[
            const SizedBox(height: AppSpacing.md),
            _StatusCard(
              message: _locationSuccess!,
              isError: false,
            ),
          ],

          if (_locationError != null) ...[
            const SizedBox(height: AppSpacing.md),
            _StatusCard(
              message: _locationError!,
              isError: true,
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: () => setState(() => _showManual = !_showManual),
            child: Text(
              _showManual ? 'Hide manual entry' : 'Enter location manually',
            ),
          ),

          if (_showManual) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City name (optional)',
                hintText: 'e.g. London',
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
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: '51.5074',
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
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: '-0.1278',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _saveManualLocation,
                child: const Text('Save Manual Location'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            isError ? colorScheme.errorContainer : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: isError
                ? colorScheme.onErrorContainer
                : colorScheme.onPrimaryContainer,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isError
                        ? colorScheme.onErrorContainer
                        : colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
