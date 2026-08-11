/// Location configuration entity.
library;

import 'package:equatable/equatable.dart';

enum LocationMode {
  automatic,
  manual,
}

final class LocationSettingsEntity extends Equatable {
  const LocationSettingsEntity({
    required this.mode,
    required this.latitude,
    required this.longitude,
    this.cityName,
  });

  const LocationSettingsEntity.defaults()
      : mode = LocationMode.automatic,
        latitude = 21.3891,
        longitude = 39.8579,
        cityName = 'Makkah';

  final LocationMode mode;
  final double latitude;
  final double longitude;
  final String? cityName;

  bool get hasValidCoordinates => latitude != 0.0 || longitude != 0.0;

  LocationSettingsEntity copyWith({
    LocationMode? mode,
    double? latitude,
    double? longitude,
    String? cityName,
  }) {
    return LocationSettingsEntity(
      mode: mode ?? this.mode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName ?? this.cityName,
    );
  }

  @override
  List<Object?> get props => [mode, latitude, longitude, cityName];
}
