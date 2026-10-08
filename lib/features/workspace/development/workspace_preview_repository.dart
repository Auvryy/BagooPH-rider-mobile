import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/account.dart';
import '../../home/development/home_preview_data.dart';
import '../../settings/development/settings_preview_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/workspace_models.dart';
import '../data/workspace_repository.dart';
import '../presentation/workspace_controller.dart';
import '../presentation/workspace_shell.dart';

/// Explicit debug route only; does not override authentication or token storage.
class WorkspacePreviewPage extends StatelessWidget {
  const WorkspacePreviewPage({super.key});
  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWith(
        (ref, identity) => identity.preview
            ? PreviewSettingsRepository(identity.accountId)
            : const UnavailableSettingsRepository(),
      ),
      workspaceRepositoryProvider.overrideWith(
        (ref) => PreviewWorkspaceRepository(),
      ),
    ],
    child: const RiderWorkspaceShell(
      account: RiderAccount(
        id: 'preview-rider',
        name: 'Demo Rider',
        email: 'rider@example.test',
        status: 'active',
        kycStatus: 'approved',
        approved: true,
        emailVerified: true,
      ),
      preview: true,
    ),
  );
}

class PreviewWorkspaceRepository implements WorkspaceRepository {
  int _messageNumber = 0;
  @override
  Future<FeatureData<List<RiderTask>>> tasks(TaskQueue queue) async {
    final original = HomePreviewQueue.values[queue.index];
    return FeatureData.ready(
      List.unmodifiable(
        homePreviewTasks[original]!.map(
          (t) => RiderTask(
            id: t.tracking,
            tracking: t.tracking,
            stage: t.stage,
            stop: t.stop,
            address: t.address,
            nextStep: t.nextStep,
            cashCentavos: queue == TaskQueue.delivery ? 78500 : null,
          ),
        ),
      ),
    );
  }

  @override
  Future<FeatureData<List<RiderTrip>>> trips() async => FeatureData.ready(
    List.unmodifiable(
      List.generate(14, (index) {
        final date = DateTime.utc(
          2026,
          10,
          7,
          7,
          30,
        ).subtract(Duration(days: index ~/ 3, hours: index % 3));
        return RiderTrip(
          id: 'preview-trip-$index',
          tracking: 'DEMO-T${3001 + index}',
          recipient: [
            'Sample recipient',
            'Example customer',
            'Demo buyer',
          ][index % 3],
          address: [
            'Market Street · Sample District',
            'Garden Road · Sample District',
          ][index % 2],
          outcome: index % 5 == 0 ? 'Delivery failed' : 'Delivered',
          recordedAt: date,
          payment: index.isEven ? PaymentFilter.cod : PaymentFilter.prepaid,
          cashCentavos: index.isEven ? 78500 + index * 1500 : null,
          checkpoints: [
            TripCheckpoint(
              'Assigned by destination hub',
              date.subtract(const Duration(hours: 2)),
            ),
            TripCheckpoint(
              'Departed destination hub',
              date.subtract(const Duration(hours: 1)),
            ),
            TripCheckpoint(
              index % 5 == 0 ? 'Delivery failed' : 'Delivered to buyer',
              date,
            ),
          ],
        );
      }),
    ),
  );
  @override
  Future<FeatureData<List<RiderConversation>>> conversations() async =>
      FeatureData.ready([
        RiderConversation(
          id: 'preview-pickup',
          tracking: 'DEMO-P1003',
          participant: 'Example grocery',
          phase: 'pickup',
          canSend: true,
          unreadCount: 1,
          messages: [
            RiderMessage(
              id: 'preview-m1',
              text: 'The parcel is ready at the shop counter.',
              fromRider: false,
              recordedAt: DateTime.utc(2026, 10, 7, 2, 12),
            ),
            RiderMessage(
              id: 'preview-m2',
              text: 'Thank you. I will check the parcel when I arrive.',
              fromRider: true,
              recordedAt: DateTime.utc(2026, 10, 7, 2, 14),
            ),
          ],
        ),
        RiderConversation(
          id: 'preview-delivery',
          tracking: 'DEMO-D2001',
          participant: 'Sample buyer',
          phase: 'final_mile',
          canSend: true,
          unreadCount: 2,
          messages: [
            RiderMessage(
              id: 'preview-m3',
              text: 'Please use the entrance beside the garden.',
              fromRider: false,
              recordedAt: DateTime.utc(2026, 10, 7, 3, 20),
            ),
          ],
        ),
        RiderConversation(
          id: 'preview-ended',
          tracking: 'DEMO-D1999',
          participant: 'Previous sample buyer',
          phase: 'final_mile',
          canSend: false,
          messages: [
            RiderMessage(
              id: 'preview-m4',
              text: 'Thank you for the delivery.',
              fromRider: false,
              recordedAt: DateTime.utc(2026, 10, 6, 4, 0),
            ),
          ],
        ),
      ]);
  @override
  Future<RiderMessage> send(
    String conversationId,
    String phase,
    String text,
  ) async => RiderMessage(
    id: 'preview-local-${++_messageNumber}',
    text: text,
    fromRider: true,
    recordedAt: DateTime.now().toUtc(),
    localPreview: true,
  );
  @override
  Future<void> acknowledge(
    String conversationId,
    String phase,
    String latestMessageId,
  ) async {}
}
