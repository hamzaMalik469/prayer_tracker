/// Synchronisation service.
///
/// Syncs unsynced local prayer records to Firestore
/// when the user is authenticated and online.
library;

import 'package:connectivity_plus/connectivity_plus.dart';

import '../helpers/guest_user_helper.dart';
import '../logging/app_logger.dart';
import '../../features/prayer_tracking/data/datasources/prayer_tracking_local_datasource.dart';
import '../../features/prayer_tracking/data/datasources/prayer_tracking_remote_datasource.dart';
import '../../features/prayer_tracking/domain/entities/prayer_record_entity.dart';
import '../../features/qada/data/datasources/qada_local_datasource.dart';
import '../../features/qada/data/datasources/qada_remote_datasource.dart';
import '../../features/qada/domain/entities/qada_record_entity.dart';

final class SyncService {
  const SyncService({
    required PrayerTrackingLocalDataSource localPrayer,
    required PrayerTrackingRemoteDataSource remotePrayer,
    required QadaLocalDataSource localQada,
    required QadaRemoteDataSource remoteQada,
  })  : _localPrayer = localPrayer,
        _remotePrayer = remotePrayer,
        _localQada = localQada,
        _remoteQada = remoteQada;

  final PrayerTrackingLocalDataSource _localPrayer;
  final PrayerTrackingRemoteDataSource _remotePrayer;
  final QadaLocalDataSource _localQada;
  final QadaRemoteDataSource _remoteQada;

  /// Syncs all unsynced local records for [userId] to Firestore.
  /// Safe to call repeatedly — already-synced records are skipped.
  Future<SyncResult> syncAll({required String userId}) async {
    // Never sync guest user data to Firestore.
    if (GuestUserHelper.isGuestId(userId)) {
      AppLogger.info(
        'Skipping sync for guest user.',
        tag: 'SyncService',
      );
      return const SyncResult(prayersSynced: 0, qadaSynced: 0, errors: 0);
    }

    // Check connectivity.
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = !connectivity.every(
      (r) => r == ConnectivityResult.none,
    );

    if (!isOnline) {
      AppLogger.info('Offline — skipping sync.', tag: 'SyncService');
      return const SyncResult(prayersSynced: 0, qadaSynced: 0, errors: 0);
    }

    int prayersSynced = 0;
    int qadaSynced = 0;
    int errors = 0;

    // ── Sync prayer records ─────────────────────────────────────────────
    try {
      final unsynced = await _localPrayer.getUnsyncedRecords(userId: userId);
      for (final record in unsynced) {
        try {
          await _remotePrayer.upsertPrayerRecord(
            userId: userId,
            date: record.date,
            prayerType: record.prayerType,
            status: record.status,
          );
          await _localPrayer.markAsSynced(recordId: record.id);
          prayersSynced++;
        } catch (e) {
          AppLogger.warning(
            'Failed to sync prayer record ${record.id}',
            error: e,
            tag: 'SyncService',
          );
          errors++;
        }
      }
    } catch (e) {
      AppLogger.error(
        'Failed to get unsynced prayer records',
        error: e,
        tag: 'SyncService',
      );
    }

    // ── Sync Qada records ───────────────────────────────────────────────
    try {
      final unsyncedQada = await _localQada.getUnsyncedRecords(userId: userId);
      for (final record in unsyncedQada) {
        try {
          if (record.isPending) {
            await _remoteQada.addRecord(
              userId: userId,
              missedDate: record.missedDate,
              prayerType: record.prayerType,
              notes: record.notes,
            );
          } else {
            await _remoteQada.completeRecord(
              userId: userId,
              qadaRecordId: record.id,
              missedDate: record.missedDate,
              prayerType: record.prayerType,
            );
          }
          await _localQada.markAsSynced(recordId: record.id);
          qadaSynced++;
        } catch (e) {
          AppLogger.warning(
            'Failed to sync Qada record ${record.id}',
            error: e,
            tag: 'SyncService',
          );
          errors++;
        }
      }
    } catch (e) {
      AppLogger.error(
        'Failed to get unsynced Qada records',
        error: e,
        tag: 'SyncService',
      );
    }

    AppLogger.info(
      'Sync complete: $prayersSynced prayers, $qadaSynced qada, $errors errors.',
      tag: 'SyncService',
    );

    return SyncResult(
      prayersSynced: prayersSynced,
      qadaSynced: qadaSynced,
      errors: errors,
    );
  }
}

final class SyncResult {
  const SyncResult({
    required this.prayersSynced,
    required this.qadaSynced,
    required this.errors,
  });

  final int prayersSynced;
  final int qadaSynced;
  final int errors;

  bool get hasErrors => errors > 0;
  int get totalSynced => prayersSynced + qadaSynced;
}
