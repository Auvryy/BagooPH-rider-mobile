import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../home/data/operations_models.dart';
import '../../home/presentation/stop_guidance.dart';
import '../../workspace/presentation/workspace_controller.dart';
import 'messages_page.dart';

Future<void> openTaskMessages(
  BuildContext context,
  WorkspaceController work,
  OperationTask task,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        ref.listen(
          authControllerProvider.select(
            (session) => (
              id: session.user?.id,
              approved: session.user?.approved,
              version: session.user?.operationsApiVersion,
              initialized: !session.initializing,
            ),
          ),
          (previous, next) {
            if (previous == null || !previous.initialized || previous == next) {
              return;
            }
            work.messages.revoke(
              'Please sign in again to open parcel messages.',
            );
            final route = ModalRoute.of(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted && route != null && route.isActive) {
                final navigator = Navigator.of(context);
                navigator.popUntil((candidate) => identical(candidate, route));
                navigator.removeRoute(route);
              }
            });
          },
        );
        return _TaskMessagesPage(work: work, reviewed: task);
      },
    ),
  ),
);

class _TaskMessagesPage extends StatefulWidget {
  const _TaskMessagesPage({required this.work, required this.reviewed});
  final WorkspaceController work;
  final OperationTask reviewed;
  @override
  State<_TaskMessagesPage> createState() => _TaskMessagesPageState();
}

class _TaskMessagesPageState extends State<_TaskMessagesPage> {
  final _resolver = Object();
  bool _loading = true, _ready = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  Future<void> _load() async {
    final chat = widget.work.messages;
    setState(() {
      _loading = true;
      _error = null;
    });
    chat.setSurfaceActive(_resolver, true);
    try {
      final fresh = await widget.work.revalidateSelectedStop(
        widget.reviewed.id,
      );
      if (!mounted || !chat.active) return;
      if (fresh == null || !sameReviewedStop(widget.reviewed, fresh)) {
        throw const AccountFailure(
          'This stop changed. Return to its details and refresh.',
        );
      }
      final threadId = await chat.findForTask(fresh);
      if (!mounted || !chat.active) return;
      if (threadId == null) {
        throw const AccountFailure(
          'No active parcel chat was found in the returned conversations. Open Messages to refresh or load more.',
        );
      }
      final checked = await widget.work.revalidateSelectedStop(fresh.id);
      if (!mounted || !chat.active) return;
      if (checked == null || !sameReviewedStop(fresh, checked)) {
        throw const AccountFailure(
          'The assignment changed while opening chat. Return to the stop and refresh.',
        );
      }
      await chat.selectConversation(threadId);
      await chat.refresh();
      if (mounted && chat.active) setState(() => _ready = true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is AccountFailure ? error.message : 'This parcel conversation could not be verified. Refresh and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        // Let the mounted Messages surface acquire visibility before releasing
        // the resolver; otherwise its new selection would be cancelled.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scheduleMicrotask(() => chat.setSurfaceActive(_resolver, false));
        });
      }
    }
  }

  @override
  void dispose() {
    widget.work.messages.setSurfaceActive(_resolver, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: _ready ? null : AppBar(title: const Text('Parcel messages')),
    body: SafeArea(
      child: _ready
          ? MessagesPage(
              controller: widget.work,
              preview: false,
              active: true,
              threadOnly: true,
              onBack: () => Navigator.of(context).maybePop(),
            )
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_loading)
                      const CircularProgressIndicator(
                        semanticsLabel: 'Checking parcel conversation',
                      )
                    else ...[
                      Text(
                        _error ?? 'Refresh this conversation.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: widget.work.messages.coolingDown
                            ? null
                            : _load,
                        child: const Text('Try again'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    ),
  );
}
