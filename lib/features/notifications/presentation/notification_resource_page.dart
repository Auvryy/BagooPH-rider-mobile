import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/rider_api_client.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../data/notification_models.dart';
import 'notification_format.dart';
import 'notifications_controller.dart';

/// Only the linked, freshly authorized record is shown. Cash operations remain
/// with their own feature; this view exposes no offer/receive/reconcile action.
class NotificationResourcePage extends StatefulWidget {
  const NotificationResourcePage({
    super.key,
    required this.controller,
    required this.target,
    required this.initial,
  });
  final NotificationsController controller;
  final NotificationTarget target;
  final NotificationDestination initial;
  @override
  State<NotificationResourcePage> createState() =>
      _NotificationResourcePageState();
}

class _NotificationResourcePageState extends State<NotificationResourcePage>
    with WidgetsBindingObserver {
  final _surface = Object();
  NotificationDestination? _data;
  RiderReadCancellation? _read;
  bool _foreground = true, _loading = false;
  String? _error;
  ModalRoute<dynamic>? _route;
  NotificationsController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    _data = widget.initial;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route != route) {
      _route?.secondaryAnimation?.removeStatusListener(_routeChanged);
      _route = route;
      _route?.secondaryAnimation?.addStatusListener(_routeChanged);
    }
    _sync();
  }

  void _routeChanged(AnimationStatus _) => _sync();
  void _sync() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final visible = _foreground && (_route?.isCurrent ?? true);
    c.setSurfaceActive(_surface, visible);
    if (!visible) {
      _read?.cancel();
      _read = null;
      setState(() {
        _data = null;
        _loading = false;
      });
    } else if (_data == null && !_loading && _error == null) {
      unawaited(_refresh());
    }
  });
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _read?.cancel();
    _read = null;
    setState(() {
      _data = null;
      _error = null;
      _loading = false;
    });
    c.setForeground(_foreground);
    _sync();
  }

  Future<void> _refresh() async {
    if (!_foreground ||
        !(_route?.isCurrent ?? true) ||
        _loading ||
        c.coolingDown ||
        !c.active) {
      return;
    }
    final read = RiderReadCancellation();
    _read?.cancel();
    _read = read;
    setState(() {
      _loading = true;
      _data = null;
      _error = null;
    });
    try {
      final data = await c.repository.resolve(
        widget.target,
        cancellation: read,
      );
      if (mounted &&
          _foreground &&
          !read.cancelled &&
          c.active &&
          (_route?.isCurrent ?? true)) {
        setState(() => _data = data);
      }
    } catch (error) {
      if (mounted && _foreground && !read.cancelled) {
        await c.reportTargetFailure(error);
        if (mounted) {
          setState(
            () => _error = error is AccountFailure && error.status == 404
                ? 'This linked record is no longer available. Return to the notification.'
                : 'This record could not be verified. Refresh and try again.',
          );
        }
      }
    } finally {
      if (mounted && identical(_read, read)) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _read?.cancel();
    c.setSurfaceActive(_surface, false);
    _route?.secondaryAnimation?.removeStatusListener(_routeChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final data = _foreground && c.active && (_route?.isCurrent ?? true)
          ? _data
          : null;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.target.kind == 'cash' ? 'Cash record' : 'Account status',
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh linked record',
              onPressed: _foreground && c.active && !_loading && !c.coolingDown
                  ? _refresh
                  : null,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (data == null)
                    RiderSurface(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_loading)
                            const LinearProgressIndicator(
                              semanticsLabel: 'Rechecking linked record',
                            ),
                          Text(_error ?? 'Revalidating this linked record…'),
                        ],
                      ),
                    ),
                  if (data case NotificationCashDestination(:final cash))
                    RiderSurface(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            cash.tracking,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your recorded cash responsibility',
                            style: TextStyle(color: RiderColors.muted),
                          ),
                          const SizedBox(height: 24),
                          _fact(
                            'Still held by you',
                            notificationPeso(cash.heldCents),
                          ),
                          _fact(
                            'Received from you',
                            notificationPeso(cash.remittedCents),
                          ),
                          _fact(
                            'Platform reconciled',
                            notificationPeso(cash.reconciledCents),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Recorded ${notificationTime(cash.recordedAt)}',
                            style: const TextStyle(color: RiderColors.muted),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Collection, recipient receipt and platform reconciliation are separate. Earnings are unavailable.',
                          ),
                        ],
                      ),
                    ),
                  if (data case NotificationAccountDestination(:final account))
                    RiderSurface(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            account.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(account.email),
                          const SizedBox(height: 24),
                          _fact(
                            'Account',
                            account.approved
                                ? 'Approved rider'
                                : 'Approval required',
                          ),
                          _fact(
                            'Email',
                            account.emailVerified
                                ? 'Verified'
                                : 'Verification required',
                          ),
                          if (account.feedback != null) ...[
                            const SizedBox(height: 16),
                            Text(account.feedback!),
                          ],
                          const SizedBox(height: 16),
                          const Text(
                            'Open Profile from the main navigation to review your account details.',
                            style: TextStyle(color: RiderColors.muted),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  Widget _fact(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: RiderColors.muted)),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    ),
  );
}
