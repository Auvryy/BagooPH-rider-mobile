import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/rider_api_client.dart';
import '../../workspace/data/workspace_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../data/trip_models.dart';

/// Private history is read afresh. No detail or image survives access loss,
/// backgrounding, or disposal; obsolete responses cannot repopulate the view.
class TripDetailController extends ChangeNotifier {
  TripDetailController({required this.work, required this.id}) {
    tripId(id);
    work.addListener(_workChanged);
  }
  final WorkspaceController work;
  final String id;
  FeatureData<RetainedTrip> detail = const FeatureData.loading();
  FeatureData<PrivateApiBytes> proof = const FeatureData.unavailable(
    'Choose a recorded proof.',
  );
  String? proofPath;
  bool foreground = true, _disposed = false, _revoked = false;
  int _generation = 0, _proofGeneration = 0;

  bool get accessible =>
      !_disposed && !_revoked && foreground && work.canReadTrips;
  void revokeAccess() {
    _revoked = true;
    _clear('This history is no longer available for your session.');
    _changed();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void _clear(String message) {
    _generation++;
    _proofGeneration++;
    detail = FeatureData.unavailable(message);
    proof = FeatureData.unavailable(message);
    proofPath = null;
  }

  void _workChanged() {
    if (!work.canReadTrips) {
      _clear('This history is no longer available for your session.');
      _changed();
    }
  }

  AccountFailure _failure(Object error) => error is AccountFailure
      ? error
      : const AccountFailure(
          'Could not verify this recorded assignment. Refresh and try again.',
        );

  Future<void> refresh() async {
    if (!accessible || work.coolingDown) return;
    final generation = ++_generation;
    clearProof();
    detail = const FeatureData.loading();
    _changed();
    try {
      final repository = work.operations;
      if (repository == null) {
        throw const AccountFailure(
          'Recorded assignment details are unavailable.',
        );
      }
      final fresh = await repository.tripDetail(id);
      if (!accessible || generation != _generation) return;
      detail = FeatureData.ready(fresh);
      _changed();
    } catch (error) {
      if (!accessible || generation != _generation) return;
      final failure = _failure(error);
      await work.reportTripFailure(failure);
      if (!accessible || generation != _generation) return;
      detail = FeatureData.failed(failure.message);
      _changed();
    }
  }

  Future<void> loadProof(String path) async {
    if (!accessible ||
        work.coolingDown ||
        detail.data?.proofPaths.contains(path) != true) {
      return;
    }
    final generation = ++_proofGeneration;
    proofPath = path;
    proof = const FeatureData.loading();
    _changed();
    try {
      final bytes = await work.operations!.tripProof(id, path);
      if (!accessible || generation != _proofGeneration) return;
      proof = FeatureData.ready(bytes);
      _changed();
    } catch (error) {
      if (!accessible || generation != _proofGeneration) return;
      final failure = _failure(error);
      await work.reportTripFailure(failure);
      if (!accessible || generation != _proofGeneration) return;
      proof = FeatureData.failed(failure.message);
      _changed();
    }
  }

  void invalidProof() {
    _proofGeneration++;
    proof = const FeatureData.failed(
      'This private image could not be displayed. Refresh the proof or contact your hub.',
    );
    _changed();
  }

  void clearProof() {
    _proofGeneration++;
    proof = const FeatureData.unavailable('Choose a recorded proof.');
    proofPath = null;
    _changed();
  }

  void setForeground(bool value) {
    if (_disposed || foreground == value) return;
    foreground = value;
    _clear('Return to Rider to revalidate this recorded assignment.');
    _changed();
    if (value) unawaited(refresh());
  }

  @override
  void dispose() {
    work.removeListener(_workChanged);
    _clear('Recorded assignment closed.');
    _disposed = true;
    super.dispose();
  }
}
