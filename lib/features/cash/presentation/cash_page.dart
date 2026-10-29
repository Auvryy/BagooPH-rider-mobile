import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';

import '../../../app/theme.dart';
import '../../../core/commands/parcel_validation.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../../workspace/data/workspace_models.dart';
import '../data/cash_models.dart';
import 'cash_controller.dart';
import 'financial_summary.dart';

Future<void> openCash(
  BuildContext context,
  WorkspaceController work, {
  String? accountId,
}) {
  final container = ProviderScope.containerOf(context, listen: false);
  final apiOrigin = container.read(appConfigProvider).origin;
  final owner = work.operations?.accountId;
  var closing = false;
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          void deny() {
            if (closing) return;
            closing = true;
            work.cash.revoke('Please sign in again to view cash records.');
            final route = ModalRoute.of(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted || route == null || !route.isActive) return;
              final navigator = Navigator.of(context);
              navigator.popUntil((candidate) => identical(candidate, route));
              navigator.removeRoute(route);
            });
          }

          final identity = ref.watch(
            authControllerProvider.select(
              (s) => (
                id: s.user?.id,
                approved: s.user?.approved,
                version: s.user?.operationsApiVersion,
                initializing: s.initializing,
              ),
            ),
          );
          ref.listen(
            authControllerProvider.select(
              (s) => (
                id: s.user?.id,
                approved: s.user?.approved,
                version: s.user?.operationsApiVersion,
                initializing: s.initializing,
              ),
            ),
            (previous, next) {
              if (previous != null &&
                  !previous.initializing &&
                  previous != next) {
                deny();
              }
            },
          );
          final origin = ref.watch(
            appConfigProvider.select((config) => config.origin),
          );
          ref.listen(appConfigProvider.select((config) => config.origin), (
            previous,
            next,
          ) {
            if (next != apiOrigin) deny();
          });
          if (closing ||
              origin != apiOrigin ||
              (!identity.initializing &&
                  (identity.id != owner ||
                      identity.approved != true ||
                      identity.version != 1))) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) deny();
            });
            return const SizedBox.shrink();
          }
          if (identity.initializing) {
            return const Scaffold(
              body: Center(child: Text('Checking cash access…')),
            );
          }
          return CashPageView(
            controller: work.cash,
            initialAccountId: accountId,
          );
        },
      ),
    ),
  );
}

class CashPageView extends StatefulWidget {
  const CashPageView({
    super.key,
    required this.controller,
    this.initialAccountId,
  });
  final CashController controller;
  final String? initialAccountId;
  @override
  State<CashPageView> createState() => _CashPageViewState();
}

class _CashPageViewState extends State<CashPageView>
    with WidgetsBindingObserver {
  CashController get c => widget.controller;
  ModalRoute<dynamic>? _route;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    c.selectedId = widget.initialAccountId;
    _search.text = c.query;
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
    if (mounted) c.setVisible(_foreground && (_route?.isCurrent ?? true));
  });
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    c.setForeground(_foreground);
    _sync();
  }

  @override
  void dispose() {
    c.setVisible(false);
    _route?.secondaryAnimation?.removeStatusListener(_routeChanged);
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _top() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final data = c.active ? c.page : null;
      final detail = c.active ? c.detail : null;
      final children = <Widget>[
        Text(
          'Your cash responsibility',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'COD collection, hub receipt and platform reconciliation are separate records. An offer keeps cash in your held balance until the hub receives it.',
          style: TextStyle(color: RiderColors.muted),
        ),
        const SizedBox(height: 20),
        if (c.loading)
          const LinearProgressIndicator(
            semanticsLabel: 'Refreshing cash records',
          ),
        if (c.notice != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(
                c.notice!,
                style: TextStyle(
                  color: c.failure == null
                      ? RiderColors.ink
                      : RiderColors.accentText,
                ),
              ),
            ),
          ),
        if (c.coolingDown)
          const Text(
            'The service asked us to wait. Refresh and offers will be available after its cooldown.',
          ),
        if (c.pending != null)
          _panel(context, 'Saved work request', [
            Text(
              c.pending!.isCash
                  ? 'An original cash offer is unconfirmed. Its recipient, amount, reference and request key are retained.'
                  : 'Finish checking the original ordinary work request before offering cash.',
            ),
            if (c.pending!.isCash) ...[
              _fact(context, 'Cash account', c.pending!.resource.substring(5)),
              _fact(
                context,
                'Offered pesos',
                c.pending!.body['amount'] as String,
              ),
              _fact(
                context,
                'Recipient ID',
                c.pending!.body['recipient_id'] as String,
              ),
              _fact(
                context,
                'Handover reference',
                c.pending!.body['evidence_reference'] as String,
              ),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: c.canRefresh ? () => c.recover() : null,
                  child: const Text('Check original request'),
                ),
                if (c.pending!.isCash)
                  OutlinedButton(
                    onPressed:
                        c.canRefresh && c.repository?.cashWritesVerified == true
                        ? () => c.recover(retryUnknown: true)
                        : null,
                    child: const Text('Retry original offer'),
                  ),
              ],
            ),
          ]),
        if (data != null) ...[
          RiderEarningsSummary(
            earnings: detail?.earnings ?? data.earnings,
            title: detail == null
                ? 'Your earnings'
                : 'Earnings for this parcel',
          ),
          if (data.shift case final shift?) ...[
            const SizedBox(height: 12),
            RiderShiftSummaryPanel(shift: shift),
          ],
          const SizedBox(height: 12),
          _panel(context, 'Cash still held by you', [
            Text(
              cashPeso(data.held),
              key: const ValueKey('cash-total-held'),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const Text(
              'Across all your retained cash journals, including accounts outside this search or page.',
              style: TextStyle(color: RiderColors.muted),
            ),
            const SizedBox(height: 12),
            Text('${data.unresolved} accounts with an unresolved difference'),
          ]),
          if (detail == null) ...[
            TextField(
              key: const ValueKey('cash-search'),
              controller: _search,
              enabled: c.canRefresh,
              decoration: const InputDecoration(
                labelText: 'Search parcel reference',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                unawaited(c.search(value));
                _top();
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: c.canRefresh ? () => c.search(_search.text) : null,
                  child: const Text('Search'),
                ),
                if (c.query.isNotEmpty)
                  TextButton(
                    onPressed: c.canRefresh
                        ? () {
                            _search.clear();
                            unawaited(c.search(''));
                          }
                        : null,
                    child: const Text('Clear search'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Cash records · page ${data.page} of ${data.lastPage}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (data.items.isEmpty)
              const Text(
                'No cash records match this search. The summary above still covers all your journals.',
              ),
            for (final row in data.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RiderSurface(
                  child: InkWell(
                    key: ValueKey('cash-account-${row.id}'),
                    borderRadius: BorderRadius.circular(20),
                    onTap: c.canRefresh
                        ? () {
                            unawaited(c.select(row.id));
                            _top();
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.tracking,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_label(row.status)} · ${row.hub}',
                            style: const TextStyle(color: RiderColors.muted),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 24,
                            runSpacing: 8,
                            children: [
                              _compact(
                                context,
                                'Held by you',
                                cashPeso(row.held),
                              ),
                              _compact(
                                context,
                                'Hub received from you',
                                cashPeso(row.remitted),
                              ),
                            ],
                          ),
                          if (row.pending != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'Awaiting hub receipt · ${cashPeso(row.pending!.cents)}',
                              ),
                            ),
                          const SizedBox(height: 12),
                          const Text(
                            'Open journal →',
                            style: TextStyle(
                              color: RiderColors.accentText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (data.page > 1)
                  OutlinedButton(
                    onPressed: c.canRefresh ? c.refresh : null,
                    child: const Text('Back to first page'),
                  ),
                if (data.hasMore)
                  OutlinedButton(
                    onPressed: c.canRefresh
                        ? () {
                            unawaited(c.more());
                            _top();
                          }
                        : null,
                    child: const Text('Next page'),
                  ),
              ],
            ),
          ] else ...[
            TextButton.icon(
              onPressed: c.canRefresh
                  ? () {
                      unawaited(c.select(null));
                      _top();
                    }
                  : null,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('All cash records'),
            ),
            _panel(context, detail.tracking, [
              Text(
                '${detail.order} · ${detail.hub}',
                style: const TextStyle(color: RiderColors.muted),
              ),
              Text(detail.company),
              const SizedBox(height: 16),
              _fact(context, 'Held by you', cashPeso(detail.held)),
              _fact(context, 'Received from you', cashPeso(detail.remitted)),
              _fact(
                context,
                'Collected from buyer',
                cashPeso(detail.collected),
              ),
              _fact(
                context,
                'Platform reconciled',
                cashPeso(detail.reconciled),
              ),
              _fact(context, 'Excess recorded', cashPeso(detail.excess)),
              _fact(context, 'Journal status', _label(detail.status)),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Source amounts and references'),
                children: [
                  _fact(context, 'Expected COD', cashPeso(detail.expected)),
                  _fact(context, 'Product subtotal', cashPeso(detail.subtotal)),
                  _fact(context, 'Discount', cashPeso(detail.discount)),
                  _fact(context, 'Shipping', cashPeso(detail.shipping)),
                  _fact(context, 'Cash reference', detail.reference),
                  _fact(context, 'Source', _label(detail.sourceKind)),
                  _fact(context, 'Journal sequence', detail.version),
                  _fact(context, 'Latest event', detail.sourceEvent),
                  _fact(context, 'Recorded', _time(detail.recordedAt)),
                ],
              ),
            ]),
            if (detail.pending case final pending?)
              _panel(context, 'Awaiting hub receipt', [
                Text(
                  '${cashPeso(pending.cents)} offered to ${pending.recipientName}',
                ),
                _fact(context, 'Offer reference', pending.reference),
                Text('Recorded holder: ${pending.holderName}'),
                const Text(
                  'This is an offer, not a confirmed remittance. Only the recipient’s separate receipt changes the held and received balances.',
                ),
              ]),
            if (c.repository?.cashWritesVerified != true)
              _panel(context, 'Cash offers unavailable', [
                const Text(
                  'You can review real cash records. Offers are awaiting service acceptance verification.',
                ),
              ])
            else if (detail.canOffer && detail.pending == null)
              _CashOfferForm(
                key: ValueKey('cash-offer-${detail.id}'),
                controller: c,
                account: detail,
              ),
            if (detail.holders.isNotEmpty)
              _panel(context, 'Recorded holders', [
                for (final holder in detail.holders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${holder.name} · ${_label(holder.stage)}\n${cashPeso(holder.cents)}${holder.restricted ? ' · access restricted' : ''}',
                    ),
                  ),
              ]),
            if (detail.discrepancies.isNotEmpty)
              _panel(context, 'Recorded differences', [
                for (final difference in detail.discrepancies)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${cashPeso(difference.cents)} · ${difference.resolvedBy == null ? 'Unresolved' : 'Resolved'}\nSource ${difference.source}${difference.resolvedBy == null ? '' : '\nResolution ${difference.resolvedBy}'}',
                    ),
                  ),
              ]),
            Text(
              'Journal history',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (detail.history.isEmpty)
              const Text('No journal history was returned.'),
            for (final event in detail.history)
              _panel(context, _label(event.kind), [
                Text('${event.actorName} · ${_label(event.actorRole)}'),
                Text(
                  _time(event.recordedAt),
                  style: const TextStyle(color: RiderColors.muted),
                ),
                if (event.amount != null)
                  _fact(context, 'Amount', cashPeso(event.amount!)),
                if (event.expected != null)
                  _fact(context, 'Expected', cashPeso(event.expected!)),
                if (event.received != null)
                  _fact(context, 'Received', cashPeso(event.received!)),
                if (event.discrepancy != null)
                  _fact(context, 'Difference', cashPeso(event.discrepancy!)),
                if (event.fromStage != null || event.toStage != null)
                  Text(
                    '${_label(event.fromStage ?? 'source')} → ${_label(event.toStage ?? 'recorded')}',
                  ),
                if (event.evidence != null)
                  _fact(context, 'Handover reference', event.evidence!),
                if (event.reason != null)
                  _fact(context, 'Reason', event.reason!),
                _fact(context, 'Event', event.reference),
                if (event.source != null)
                  _fact(context, 'Original source', event.source!),
                if (event.provenance != null)
                  _fact(context, 'Provenance', _label(event.provenance!)),
              ]),
          ],
        ],
      ];
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cash & remittance'),
          actions: [
            IconButton(
              tooltip: 'Refresh cash records',
              onPressed: c.canRefresh ? c.refresh : null,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                itemCount: children.length,
                itemBuilder: (_, index) => children[index],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _panel(BuildContext context, String title, List<Widget> children) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RiderSurface(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
Widget _compact(BuildContext context, String label, String value) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(label, style: const TextStyle(color: RiderColors.muted)),
    Text(value, style: Theme.of(context).textTheme.titleMedium),
  ],
);
Widget _fact(BuildContext context, String label, String value) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: _compact(context, label, value),
);
String _label(String value) => value.replaceAll('_', ' ');
String _time(DateTime time) =>
    '${dayLabel(time)} · ${timeLabel(time)} (Manila)';

class _CashOfferForm extends StatefulWidget {
  const _CashOfferForm({
    super.key,
    required this.controller,
    required this.account,
  });
  final CashController controller;
  final CashAccount account;
  @override
  State<_CashOfferForm> createState() => _CashOfferFormState();
}

class _CashOfferFormState extends State<_CashOfferForm> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(), _evidence = TextEditingController();
  String? _recipient;
  bool _review = false;
  void _privacy() {
    if (!widget.controller.active) {
      _amount.clear();
      _evidence.clear();
      _recipient = null;
      _review = false;
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_privacy);
  }

  @override
  void didUpdateWidget(_CashOfferForm old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_privacy);
      widget.controller.addListener(_privacy);
    }
    if (!old.account.sameOfferTerms(widget.account)) {
      _amount.clear();
      _evidence.clear();
      _recipient = null;
      _review = false;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_privacy);
    _amount.dispose();
    _evidence.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final a = widget.account;
    final error = c.failure;
    return _panel(
      context,
      _review ? 'Review cash offer' : 'Offer cash to your hub',
      [
        const Text(
          'Use the current hub recipient and the reference on your actual cash handover. The hub confirms receipt separately.',
        ),
        const SizedBox(height: 16),
        if (a.recipients.isEmpty)
          const Text(
            'No eligible hub recipient was returned. Refresh or contact your hub.',
          )
        else if (_review) ...[
          _fact(
            context,
            'Recipient',
            a.recipients.firstWhere((r) => r.id == _recipient).name,
          ),
          _fact(
            context,
            'Offered amount',
            cashPeso(pesoInputCents(_amount.text, field: 'amount')),
          ),
          _fact(context, 'Handover reference', _evidence.text.trim()),
          const Text(
            'Offering does not confirm that the hub received cash. Your held amount remains unchanged until receipt.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('cash-confirm-offer'),
            onPressed: c.canOffer
                ? () async {
                    final ok = await c.offer(
                      recipientId: _recipient!,
                      amount: _amount.text,
                      evidenceReference: _evidence.text,
                    );
                    if (mounted && ok) {
                      setState(() {
                        _review = false;
                        _amount.clear();
                        _evidence.clear();
                        _recipient = null;
                      });
                    } else if (mounted &&
                        c.failure?.fields.isNotEmpty == true) {
                      setState(() => _review = false);
                    }
                  }
                : null,
            child: Text(
              c.working ? 'Checking original offer…' : 'Confirm cash offer',
            ),
          ),
          TextButton(
            onPressed: c.working ? null : () => setState(() => _review = false),
            child: const Text('Edit offer'),
          ),
        ] else
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Permitted hub recipient'),
                RadioGroup<String>(
                  groupValue: _recipient,
                  onChanged: (value) {
                    if (c.canOffer) setState(() => _recipient = value);
                  },
                  child: Column(
                    children: [
                      for (final recipient in a.recipients)
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: recipient.id,
                          enabled: c.canOffer,
                          title: Text(recipient.name),
                        ),
                    ],
                  ),
                ),
                if (error?.fields['recipient_id'] != null)
                  Text(
                    error!.fields['recipient_id']!,
                    style: const TextStyle(color: RiderColors.accentText),
                  ),
                TextFormField(
                  key: const ValueKey('cash-offer-amount'),
                  controller: _amount,
                  enabled: c.canOffer,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount in pesos',
                    hintText: 'For example, 125.50',
                    helperText: 'Still held by you: ${cashPeso(a.held)}',
                    helperMaxLines: 3,
                    errorText: error?.fields['amount'],
                  ),
                  validator: (value) {
                    try {
                      final amount = pesoInputCents(
                        value ?? '',
                        field: 'amount',
                      );
                      if (amount <= BigInt.zero || amount > a.held) {
                        return 'Use a positive amount within your held cash.';
                      }
                      return null;
                    } catch (_) {
                      return 'Use pesos with at most two decimals, without commas.';
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('cash-offer-evidence'),
                  controller: _evidence,
                  enabled: c.canOffer,
                  maxLength: 120,
                  decoration: InputDecoration(
                    labelText: 'Handover reference',
                    hintText: 'Your actual receipt or handover reference',
                    hintMaxLines: 3,
                    errorText: error?.fields['evidence_reference'],
                  ),
                  validator: (value) {
                    try {
                      cashEvidence(value ?? '');
                      return null;
                    } catch (_) {
                      return 'Enter a plain reference of 3–120 characters.';
                    }
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const ValueKey('cash-review-offer'),
                  onPressed: c.canOffer
                      ? () {
                          if (_form.currentState!.validate() &&
                              _recipient != null) {
                            FocusScope.of(context).unfocus();
                            setState(() => _review = true);
                          } else if (_recipient == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Choose a permitted hub recipient.',
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                  child: const Text('Review cash offer'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
