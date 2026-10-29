import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/network/rider_api_client.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../home/data/command_journal.dart';
import '../../workspace/data/workspace_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../data/company_models.dart';
import '../data/company_repository.dart';
import 'company_controller.dart';

final riderCompanyControllerProvider = Provider.autoDispose
    .family<RiderCompanyController, String>((ref, id) {
      final api = ref.watch(authRepositoryProvider);
      final identity = ref.watch(
        authControllerProvider.select(
          (state) => (
            id: state.user?.id,
            approved: state.user?.approved,
            version: state.user?.companyApiVersion,
          ),
        ),
      );
      if (api is! RiderSessionApi ||
          identity.id != id ||
          identity.approved != true ||
          identity.version != 1) {
        throw StateError('Company access is unavailable for this session.');
      }
      var live = true;
      ref.onDispose(() => live = false);
      final controller = RiderCompanyController(
        RiderCompanyRepository(
          api as RiderSessionApi,
          accountId: id,
          journal: SecureCommandJournal(
            origin: ref.watch(appConfigProvider).origin,
            accountId: id,
            scope: 'company',
          ),
          isCurrent: () =>
              live &&
              ref.read(authControllerProvider).user?.id == id &&
              ref.read(authControllerProvider).user?.approved == true &&
              identical(ref.read(authRepositoryProvider), api),
        ),
        onAccessDenied: (message) =>
            ref.read(authControllerProvider.notifier).discardSession(message),
        onAssignmentChanged: () async {
          if (live) {
            await ref
                .read(workspaceControllerProvider(WorkspaceIdentity(id)))
                .refreshAll();
          }
        },
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

class RiderCompanyPage extends ConsumerStatefulWidget {
  const RiderCompanyPage({
    super.key,
    required this.accountId,
    this.applicationId,
  });
  final String accountId;
  final String? applicationId;
  @override
  ConsumerState<RiderCompanyPage> createState() => _RiderCompanyPageState();
}

class _RiderCompanyPageState extends ConsumerState<RiderCompanyPage>
    with WidgetsBindingObserver {
  RiderCompanyController? _controller;
  RiderCompanyController get controller => _controller!;
  final search = TextEditingController(), province = TextEditingController();
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;
    final resumed = state == AppLifecycleState.resumed;
    controller.setActive(resumed);
    if (resumed) {
      unawaited(controller.refresh());
    } else if (mounted) {
      final page = ModalRoute.of(context);
      Navigator.of(context).popUntil((route) => route == page);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    search.dispose();
    province.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _top() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
  });

  Future<void> _apply(RiderCompany company) async {
    final membership = controller.assignment;
    if (membership == null || !controller.canAct) return;
    var note = '';
    var acknowledged = false, submitting = false;
    try {
      await showRiderDialog<void>(
        context: context,
        builder: (dialog) => _CompanyDialogGuard(
          accountId: widget.accountId,
          controller: controller,
          child: StatefulBuilder(
            builder: (dialog, change) => AlertDialog(
              scrollable: true,
              title: Text('Request to join ${company.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'The company will receive these work profile details to review your request.',
                  ),
                  const SizedBox(height: 12),
                  for (final entry in membership.sharedProfile.entries)
                    if (entry.value != null)
                      _fact(_profileLabel(entry.key), entry.value!),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => note = value,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: 'Note (optional)',
                      hintText:
                          'Your work availability or a short introduction',
                      errorText: controller.fields['note'],
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: acknowledged,
                    onChanged: submitting
                        ? null
                        : (value) => change(() => acknowledged = value == true),
                    title: const Text(
                      'I agree to share these work details with this company.',
                    ),
                  ),
                  if (controller.notice != null)
                    Text(
                      controller.notice!,
                      style: const TextStyle(color: RiderColors.accentText),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(dialog),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: !acknowledged || submitting
                      ? null
                      : () async {
                          change(() => submitting = true);
                          final ok = await controller.submit(
                            company,
                            note: note,
                            acknowledged: acknowledged,
                          );
                          if (!dialog.mounted) return;
                          if (ok) {
                            Navigator.pop(dialog);
                          } else {
                            change(() => submitting = false);
                          }
                        },
                  child: Text(submitting ? 'Sending…' : 'Send request'),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      note = '';
      _top();
    }
  }

  Future<void> _decide(CompanyApplication request, String action) async {
    if (!controller.canAct) return;
    final accepting = action == 'company.accepted';
    final title = accepting
        ? 'Accept assignment'
        : action == 'company.declined'
        ? 'Decline offer'
        : 'Withdraw request';
    var reason = '';
    var acknowledged = false, submitting = false;
    try {
      await showRiderDialog<void>(
        context: context,
        builder: (dialog) => _CompanyDialogGuard(
          accountId: widget.accountId,
          controller: controller,
          child: StatefulBuilder(
            builder: (dialog, change) => AlertDialog(
              scrollable: true,
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    request.companyName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (accepting && request.offer != null) ...[
                    const SizedBox(height: 12),
                    ..._offerFacts(request.offer!),
                    const SizedBox(height: 12),
                    const Text(
                      'Accepting saves this assignment. It does not put you on duty.',
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: acknowledged,
                      onChanged: submitting
                          ? null
                          : (value) =>
                                change(() => acknowledged = value == true),
                      title: const Text(
                        'I have reviewed and accept this exact assignment and its working arrangements.',
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    const Text(
                      'The original request and offer will remain in your history.',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) => reason = value,
                      maxLength: 500,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Reason (optional)',
                        errorText: controller.fields['reason'],
                      ),
                    ),
                  ],
                  if (controller.notice != null)
                    Text(
                      controller.notice!,
                      style: const TextStyle(color: RiderColors.accentText),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(dialog),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: submitting || accepting && !acknowledged
                      ? null
                      : () async {
                          change(() => submitting = true);
                          final ok = await controller.decide(
                            request,
                            action,
                            acknowledged: acknowledged,
                            reason: reason,
                          );
                          if (!dialog.mounted) return;
                          if (ok) {
                            Navigator.pop(dialog);
                          } else {
                            change(() => submitting = false);
                          }
                        },
                  child: Text(submitting ? 'Saving…' : title),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      reason = '';
      _top();
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = ref.watch(authControllerProvider).user;
    if (owner?.id != widget.accountId ||
        owner?.approved != true ||
        owner?.companyApiVersion != 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final page = ModalRoute.of(context);
        if (page?.isActive == true) {
          final navigator = Navigator.of(context);
          navigator.popUntil((route) => route == page || route.isFirst);
          if (page?.isCurrent == true && navigator.canPop()) navigator.pop();
        }
      });
      return const SizedBox.shrink();
    }
    final current = ref.watch(riderCompanyControllerProvider(widget.accountId));
    if (!identical(_controller, current)) {
      _controller = current;
      Future.microtask(() async {
        await current.refresh();
        if (mounted &&
            identical(_controller, current) &&
            widget.applicationId != null) {
          await current.select(widget.applicationId!);
        }
      });
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller, membership = c.assignment, request = c.selected;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Company requests'),
            actions: [
              IconButton(
                tooltip: 'Refresh company requests',
                onPressed: c.canRefresh ? c.refresh : null,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: !c.active
              ? const Center(
                  child: Text('Return to Rider to check company details.'),
                )
              : RefreshIndicator(
                  onRefresh: c.refresh,
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (c.busy)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: LinearProgressIndicator(),
                        ),
                      if (c.notice != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            c.notice!,
                            key: const ValueKey('company-notice'),
                            style: const TextStyle(
                              color: RiderColors.accentText,
                            ),
                          ),
                        ),
                      if (c.coolingDown)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Please wait for the service cooldown before checking again.',
                          ),
                        ),
                      if (c.pendingIntent != null) ...[
                        _panel(
                          Icons.pending_actions_outlined,
                          'Saved company request',
                          [
                            const Text(
                              'The outcome of an earlier company request still needs checking. A new request stays unavailable until it is resolved.',
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: c.canRefresh
                                      ? () => c.recover()
                                      : null,
                                  child: const Text('Check original request'),
                                ),
                                if (c.unknownRequest)
                                  OutlinedButton(
                                    onPressed: c.canRefresh && c.readVerified
                                        ? () => c.recover(retryUnknown: true)
                                        : null,
                                    child: const Text('Retry original request'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!c.readVerified && !c.busy) ...[
                        const Text(
                          'Refresh this page before making a company decision.',
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: c.canRefresh ? c.refresh : null,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Refresh details'),
                          ),
                        ),
                      ],
                      if (membership != null) ...[
                        _panel(Icons.badge_outlined, 'Working assignment', [
                          _fact(
                            'Company',
                            membership.companyName ?? 'Not assigned',
                          ),
                          _fact('Hub', membership.hubName ?? 'Not assigned'),
                          if (membership.barangay != null)
                            _fact('Barangay', membership.barangay!),
                          _fact('Vehicle', membership.vehicle),
                          if (membership.blockedReason != null)
                            Text(membership.blockedReason!),
                          if (membership.provenance == 'accepted_offer')
                            const Text(
                              'Your accepted offer is retained with this assignment. Duty is managed separately from Home.',
                            ),
                          if (membership.provenance == 'existing_assignment')
                            const Text(
                              'This is your existing recorded assignment. No earlier offer acceptance is assumed.',
                            ),
                        ]),
                        const SizedBox(height: 16),
                      ],
                      if (request != null)
                        ..._requestDetail(c, request)
                      else ...[
                        _requests(c),
                        const SizedBox(height: 20),
                        if (membership?.canApply == true) _directory(c),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _requests(RiderCompanyController c) {
    final page = c.applications;
    return _panel(Icons.history_rounded, 'Your requests', [
      if (page == null)
        const Text('Request history is not loaded yet.')
      else if (page.items.isEmpty)
        const Text('You have not requested to join a company yet.')
      else ...[
        for (final request in page.items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(request.companyName),
            subtitle: Text(
              '${_status(request.effectiveStatus)}\n${request.reference}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: c.canRefresh
                ? () async {
                    await c.select(request.id);
                    _top();
                  }
                : null,
          ),
        _paging(
          page.page,
          page.lastPage,
          c.canRefresh,
          (p) => c.applicationPage(p),
        ),
      ],
    ]);
  }

  Widget _directory(RiderCompanyController c) {
    final page = c.companies;
    return _panel(Icons.business_outlined, 'Find a company', [
      const Text(
        'Only companies with open intake are listed. Coverage summaries do not guarantee a delivery route.',
      ),
      const SizedBox(height: 12),
      TextField(
        controller: search,
        decoration: const InputDecoration(
          labelText: 'Company name',
          prefixIcon: Icon(Icons.search_rounded),
        ),
        onSubmitted: c.canRefresh
            ? (_) => c.searchCompanies(search.text, province.text)
            : null,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: province,
        decoration: const InputDecoration(
          labelText: 'Service province (optional)',
        ),
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: c.canRefresh
              ? () => c.searchCompanies(search.text, province.text)
              : null,
          icon: const Icon(Icons.search_rounded),
          label: const Text('Search companies'),
        ),
      ),
      const SizedBox(height: 12),
      if (page == null)
        const Text('Company directory is not loaded yet.')
      else if (page.items.isEmpty)
        const Text(
          'No companies match these filters. Try another name or province.',
        )
      else ...[
        for (final company in page.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  company.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  company.areas.where((s) => s.isNotEmpty).join(' · ').isEmpty
                      ? 'Service areas not recorded'
                      : company.areas.where((s) => s.isNotEmpty).join(' · '),
                ),
                if (company.areasTruncated)
                  const Text(
                    'Some service areas are not included in this preview.',
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    onPressed: c.canAct ? () => _apply(company) : null,
                    child: const Text('Request to join'),
                  ),
                ),
              ],
            ),
          ),
        _paging(
          page.page,
          page.lastPage,
          c.canRefresh,
          (p) => c.companyPage(p),
        ),
      ],
    ]);
  }

  List<Widget> _requestDetail(
    RiderCompanyController c,
    CompanyApplication request,
  ) => [
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: c.canRefresh
            ? () {
                c.closeDetail();
                _top();
              }
            : null,
        icon: const Icon(Icons.arrow_back_rounded),
        label: const Text('All requests'),
      ),
    ),
    _panel(Icons.assignment_outlined, request.companyName, [
      _fact('Request', request.reference),
      _fact('Status', _status(request.effectiveStatus)),
      _fact('Submitted', _date(request.submittedAt)),
      if (request.offer case final offer?) ...[
        const Divider(height: 28),
        Text('Current offer', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ..._offerFacts(offer),
      ],
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (request.canAccept)
            FilledButton(
              onPressed: c.canAct
                  ? () => _decide(request, 'company.accepted')
                  : null,
              child: const Text('Accept assignment'),
            ),
          if (request.canDecline)
            OutlinedButton(
              onPressed: c.canAct
                  ? () => _decide(request, 'company.declined')
                  : null,
              child: const Text('Decline offer'),
            ),
          if (request.canWithdraw)
            TextButton(
              onPressed: c.canAct
                  ? () => _decide(request, 'company.withdrawn')
                  : null,
              child: const Text('Withdraw request'),
            ),
        ],
      ),
      if (request.decisions.isNotEmpty)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Decision history'),
          children: [
            for (final decision in request.decisions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_status(decision.action)),
                subtitle: Text(
                  '${_date(decision.at)}${decision.reason == null ? '' : '\n${decision.reason}'}',
                ),
              ),
          ],
        ),
      if (request.offers.length > 1)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Earlier offers'),
          children: [
            for (final offer in request.offers.where(
              (o) => o.id != request.offer?.id,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _fact('Offer', offer.reference),
                    ..._offerFacts(offer),
                  ],
                ),
              ),
          ],
        ),
      if (request.historyTruncated)
        const Text(
          'This view shows the latest history entries. Earlier records remain retained.',
        ),
    ]),
  ];
  List<Widget> _offerFacts(CompanyOffer offer) => [
    _fact('Hub', offer.hub),
    if (offer.hubCode != null) _fact('Hub code', offer.hubCode!),
    _fact('Vehicle', offer.vehicle),
    if (offer.barangay != null) _fact('Barangay', offer.barangay!),
    _fact('Working arrangements', offer.terms),
    _fact('Offer expires', _date(offer.expiresAt)),
  ];
  Widget _panel(IconData icon, String title, List<Widget> children) =>
      RiderSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: RiderColors.accentText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      );
  Widget _fact(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: RiderColors.muted),
        ),
        const SizedBox(height: 3),
        Text(value),
      ],
    ),
  );
  Widget _paging(int page, int last, bool enabled, ValueChanged<int> select) =>
      last <= 1
      ? const SizedBox.shrink()
      : Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              onPressed: enabled && page > 1 ? () => select(page - 1) : null,
              child: const Text('Previous'),
            ),
            Text('Page $page of $last'),
            OutlinedButton(
              onPressed: enabled && page < last ? () => select(page + 1) : null,
              child: const Text('Next'),
            ),
          ],
        );
  String _date(DateTime value) =>
      '${dayLabel(value)} · ${timeLabel(value)} PHT';
  String _status(String value) => value.isEmpty
      ? 'Not recorded'
      : '${value[0].toUpperCase()}${value.substring(1).replaceAll('_', ' ')}';
  String _profileLabel(String key) => switch (key) {
    'name' => 'Name',
    'email' => 'Work email',
    'phone' => 'Mobile number',
    'city' => 'City / municipality',
    'province' => 'Province',
    'vehicle_type' => 'Vehicle type',
    'approval_status' => 'Approval',
    _ => key,
  };
}

class _CompanyDialogGuard extends ConsumerWidget {
  const _CompanyDialogGuard({
    required this.accountId,
    required this.controller,
    required this.child,
  });
  final String accountId;
  final RiderCompanyController controller;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(authControllerProvider).user;
    if (owner?.id != accountId ||
        owner?.approved != true ||
        owner?.companyApiVersion != 1) {
      return const SizedBox.shrink();
    }
    if (!identical(
      ref.watch(riderCompanyControllerProvider(accountId)),
      controller,
    )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && ModalRoute.isCurrentOf(context) == true) {
          Navigator.pop(context);
        }
      });
      return const SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) =>
          controller.active ? child : const SizedBox.shrink(),
    );
  }
}
