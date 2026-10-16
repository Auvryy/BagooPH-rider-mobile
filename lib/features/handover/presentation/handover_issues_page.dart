import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/ui/argon_widgets.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../home/presentation/task_stage_label.dart';
import '../data/handover_intent.dart';
import '../data/handover_models.dart';
import 'handover_controller.dart';
import 'handover_entry.dart';
import 'handover_evidence_page.dart';

class HandoverIssuesPage extends ConsumerWidget {
  const HandoverIssuesPage({super.key, this.initialBarcode});
  final String? initialBarcode;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(handoverControllerProvider);
    return HandoverIssuesView(
      key: ObjectKey(controller),
      controller: controller,
      initialBarcode: initialBarcode,
    );
  }
}

class HandoverIssuesView extends StatefulWidget {
  const HandoverIssuesView({
    super.key,
    required this.controller,
    this.initialBarcode,
    this.pickFile,
  });
  final HandoverController controller;
  final String? initialBarcode;
  final Future<XFile?> Function()? pickFile;
  @override
  State<HandoverIssuesView> createState() => _HandoverIssuesViewState();
}

class _HandoverIssuesViewState extends State<HandoverIssuesView>
    with WidgetsBindingObserver {
  final _barcode = TextEditingController(),
      _holder = TextEditingController(),
      _location = TextEditingController(),
      _notes = TextEditingController(),
      _ackBarcode = TextEditingController(),
      _ackNotes = TextEditingController();
  bool _reporting = false, _choosing = false, _possession = false;
  HandoverFile? _file;
  String? _fileName, _fileError, _authority;
  HandoverController get work => widget.controller;
  @override
  void initState() {
    super.initState();
    _barcode.text = widget.initialBarcode ?? '';
    WidgetsBinding.instance.addObserver(this);
    work.addListener(_changed);
    unawaited(Future.microtask(work.refresh));
  }

  void _changed() {
    if (!mounted) return;
    final grant = work.selected?.recovery;
    final authority = grant == null
        ? null
        : '${work.selected!.id}/${grant.id}/${grant.version}/${grant.sourceToken}/${grant.hubId}';
    if (authority != _authority) {
      _authority = authority;
      _possession = false;
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _possession = false;
    work.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    work.removeListener(_changed);
    for (final c in [
      _barcode,
      _holder,
      _location,
      _notes,
      _ackBarcode,
      _ackNotes,
    ]) {
      c.dispose();
    }
    _file = null;
    super.dispose();
  }

  void _back() {
    if (_reporting) {
      setState(() {
        _reporting = false;
        _file = null;
        _fileName = null;
        _fileError = null;
      });
    } else if (work.selectedId != null) {
      work.closeDetail();
      _ackBarcode.clear();
      _ackNotes.clear();
      _possession = false;
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _choose() async {
    if (_choosing || !work.canWrite) return;
    setState(() {
      _choosing = true;
      _fileError = null;
    });
    try {
      final file = widget.pickFile != null
          ? await widget.pickFile!()
          : await openFile(
              acceptedTypeGroups: const [
                XTypeGroup(
                  label: 'Handover evidence',
                  extensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
                  mimeTypes: [
                    'image/jpeg',
                    'image/png',
                    'image/webp',
                    'application/pdf',
                  ],
                  uniformTypeIdentifiers: ['public.image', 'com.adobe.pdf'],
                ),
              ],
            );
      if (file == null || !mounted || work.repository?.isCurrent() != true) {
        return;
      }
      final evidence = await HandoverFile.fromFile(file);
      if (mounted && work.repository?.isCurrent() == true) {
        setState(() {
          _file = evidence;
          _fileName = file.name;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _fileError = error is AccountFailure
              ? error.message
              : 'Could not read the selected evidence. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _choosing = false);
    }
  }

  Future<void> _report() async {
    if (_file == null) {
      setState(() => _fileError = 'Choose actual evidence before reporting.');
      return;
    }
    final committed = await work.report(
      barcode: _barcode.text,
      holder: _holder.text,
      location: _location.text,
      notes: _notes.text,
      file: _file!,
    );
    if (committed && mounted) {
      setState(() {
        _reporting = false;
        _file = null;
        _fileName = null;
        _fileError = null;
        _holder.clear();
        _location.clear();
        _notes.clear();
      });
    }
  }

  Future<void> _acknowledge() async {
    final committed = await work.acknowledge(
      barcode: _ackBarcode.text,
      notes: _ackNotes.text,
      possessionVerified: _possession,
    );
    if (mounted) {
      setState(() => _possession = false);
      if (committed) {
        _ackBarcode.clear();
        _ackNotes.clear();
      }
    }
  }

  Future<void> _evidence(HandoverDetail detail) async {
    final repo = work.repository;
    if (repo == null || !work.canRead || work.loading || work.busy) return;
    work.setVisible(false);
    _possession = false;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => HandoverSessionGuard(
            accountId: repo.accountId,
            child: HandoverEvidencePage(
              repository: repo,
              detail: detail,
              onFailure: work.handleFailure,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) work.setVisible(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = work.selected;
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => _back(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: PopScope(
            canPop: !_reporting && work.selectedId == null,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _back();
            },
            child: Scaffold(
              key: const ValueKey('handover-page'),
              appBar: AppBar(
                title: Text(
                  _reporting
                      ? 'Report missed scan'
                      : work.selectedId == null
                      ? 'Handover issues'
                      : 'Handover issue',
                ),
                toolbarHeight:
                    (MediaQuery.textScalerOf(context).scale(20) * 1.4 + 16)
                        .clamp(56.0, 96.0),
                leading: IconButton(
                  key: const ValueKey('handover-back'),
                  tooltip: 'Back',
                  onPressed: _back,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                actions: [
                  IconButton(
                    key: const ValueKey('handover-refresh'),
                    tooltip: 'Refresh handover records',
                    onPressed:
                        work.busy ||
                            work.loading ||
                            work.coolingDown ||
                            _choosing
                        ? null
                        : work.refresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              body: RiderCanvas(
                child: SafeArea(
                  top: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 840),
                      child: ListView(
                        key: const ValueKey('handover-scroll'),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        children: [
                          if (work.loading || work.detailLoading || work.busy)
                            const LinearProgressIndicator(
                              semanticsLabel: 'Checking handover records',
                            ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const LiquidGlassOrb(size: 34, blurSigma: 10),
                              DieCutStickerWidget.speechBubble(
                                text: 'CUSTODY CHECK',
                                backgroundColor: RiderColors.rose,
                                textColor: RiderColors.accentText,
                                rotationDegrees: 0,
                                leadingIcon: Icons.fact_check_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: RiderColors.muted,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  work.availability,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          if (work.failure != null) ...[
                            const SizedBox(height: 12),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                work.failure!.message,
                                key: const ValueKey('handover-error'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                          if (work.notice != null) ...[
                            const SizedBox(height: 12),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                work.notice!,
                                key: const ValueKey('handover-notice'),
                              ),
                            ),
                          ],
                          if (work.coolingDown)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Wait for the refresh cooldown before trying again.',
                              ),
                            ),
                          if (work.pendingIntent != null) ...[
                            const SizedBox(height: 16),
                            _pending(),
                          ],
                          const SizedBox(height: 16),
                          if (_reporting)
                            _reportForm()
                          else if (work.selectedId != null) ...[
                            if (detail != null)
                              _detail(detail)
                            else if (!work.loading && !work.detailLoading)
                              const Text(
                                'This handover issue is unavailable. Return to the list or refresh.',
                              ),
                          ] else
                            _list(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => RiderSurface(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
  Widget _pending() => _section('Saved handover request', [
    Text(
      work.pendingIntent!.action == 'handover.report'
          ? 'Original missed-scan report'
          : 'Original possession acknowledgement',
    ),
    const SizedBox(height: 8),
    const Text(
      'Keep the original intent and evidence until its outcome is confirmed. No new request replaces it.',
    ),
    const SizedBox(height: 12),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        TextButton(
          key: const ValueKey('handover-check-saved'),
          onPressed: work.canRead && !work.busy && !work.loading
              ? work.reconcile
              : null,
          child: const Text('Check saved request'),
        ),
        TextButton(
          key: const ValueKey('handover-retry-original'),
          onPressed:
              work.canRead &&
                  !work.busy &&
                  !work.loading &&
                  work.repository!.canWrite(work.home!) &&
                  work.repository!.now().difference(
                        work.pendingIntent!.createdAt,
                      ) <
                      const Duration(days: 7)
              ? () => work.reconcile(retry: true)
              : null,
          child: const Text('Retry original request'),
        ),
      ],
    ),
  ]);
  Widget _list() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.initialBarcode != null) ...[
        SelectableText('Selected parcel: ${widget.initialBarcode}'),
        const SizedBox(height: 12),
      ],
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          key: const ValueKey('handover-new-report'),
          onPressed: work.canWrite
              ? () => setState(() => _reporting = true)
              : null,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Report missed scan'),
        ),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        key: const ValueKey('handover-status'),
        initialValue: work.status,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Issue status'),
        items: const [
          DropdownMenuItem(value: 'open', child: Text('Open issues')),
          DropdownMenuItem(value: 'recovered', child: Text('Recovered')),
          DropdownMenuItem(value: 'dismissed', child: Text('Dismissed')),
          DropdownMenuItem(value: 'all', child: Text('All involved issues')),
        ],
        onChanged: work.canRead && !work.loading && !work.busy
            ? (value) {
                if (value != null) work.changeStatus(value);
              }
            : null,
      ),
      const SizedBox(height: 16),
      if (!work.loading && work.page != null && work.items.isEmpty)
        const RiderSurface(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.fact_check_outlined,
                size: 32,
                color: RiderColors.muted,
              ),
              SizedBox(height: 12),
              Text(
                'No involved handover issues in this status.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      if (work.failure != null && work.items.isNotEmpty)
        const Text(
          'These are the last checked records. Refresh before acting.',
        ),
      for (final issue in work.items)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RiderSurface(
            child: InkWell(
              key: ValueKey('handover-issue-${issue.id}'),
              onTap: work.canRead && !work.loading && !work.busy
                  ? () => work.open(issue.id)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: RiderColors.rose,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            size: 22,
                            color: RiderColors.accentText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            handoverStateLabel(issue.state),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: RiderColors.muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      issue.tracking,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      issue.reference,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      issue.held
                          ? 'Recovery hold active'
                          : 'No active recovery hold',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: issue.held
                            ? RiderColors.accentText
                            : RiderColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      if (work.page?.hasNext == true)
        TextButton(
          key: const ValueKey('handover-more'),
          onPressed:
              work.canRead && !work.loading && !work.loadingMore && !work.busy
              ? work.more
              : null,
          child: Text(work.loadingMore ? 'Loading more…' : 'Load more issues'),
        ),
    ],
  );
  Widget _field(
    String key,
    String label,
    TextEditingController controller, {
    int lines = 1,
    int? limit,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      key: ValueKey('handover-$key'),
      controller: controller,
      enabled: !work.busy && work.active && work.pendingIntent == null,
      maxLines: lines,
      maxLength: limit,
      decoration: InputDecoration(
        labelText: label,
        errorText: work.failure?.fields[key],
        errorMaxLines: 4,
      ),
    ),
  );
  Widget _reportForm() => _section('Record what happened', [
    const Text(
      'Report an actual missed scan. Reporting changes no custody, stock, cash or hold.',
    ),
    const SizedBox(height: 16),
    _field('barcode', 'Actual waybill', _barcode, limit: 255),
    _field('reported_holder', 'Observed holder', _holder, limit: 100),
    _field('reported_location', 'Observed location', _location, limit: 255),
    _field('notes', 'What happened', _notes, lines: 4, limit: 1000),
    const Text('Evidence: JPG/JPEG/PNG/WEBP/PDF · maximum 5 MB'),
    const SizedBox(height: 8),
    if (_fileName != null) Text(_fileName!),
    if (_fileError != null || work.failure?.fields['evidence'] != null)
      Text(
        _fileError ?? work.failure!.fields['evidence']!,
        key: const ValueKey('handover-evidence-error'),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: const ValueKey('handover-pick-evidence'),
        onPressed: work.canWrite && !_choosing ? _choose : null,
        icon: const Icon(Icons.attach_file_rounded),
        label: Text(
          _choosing
              ? 'Choosing evidence…'
              : _file == null
              ? 'Choose evidence'
              : 'Replace evidence',
        ),
      ),
    ),
    const SizedBox(height: 16),
    FilledButton(
      key: const ValueKey('handover-submit-report'),
      onPressed: work.canWrite && !_choosing ? _report : null,
      child: Text(work.busy ? 'Checking report…' : 'Submit missed-scan report'),
    ),
  ]);
  Widget _detail(HandoverDetail detail) {
    final grant = detail.recovery;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section(handoverStateLabel(detail.state), [
          SelectableText(detail.tracking),
          const SizedBox(height: 8),
          SelectableText(detail.reference),
          const SizedBox(height: 12),
          Text(
            detail.held ? 'Recovery hold active' : 'No active recovery hold',
          ),
          const SizedBox(height: 8),
          const Text(
            'Only actual authorized hub receipt clears a recovery hold.',
          ),
        ]),
        const SizedBox(height: 16),
        _section('Reported observations', [
          Text('Observed holder: ${detail.reportedHolder}'),
          const SizedBox(height: 8),
          Text('Observed location: ${detail.reportedLocation}'),
          const SizedBox(height: 8),
          SelectableText(detail.notes),
          const SizedBox(height: 12),
          TextButton.icon(
            key: const ValueKey('handover-view-evidence'),
            onPressed: work.canRead && !work.loading && !work.busy
                ? () => _evidence(detail)
                : null,
            icon: const Icon(Icons.description_outlined),
            label: const Text('View private evidence'),
          ),
        ]),
        const SizedBox(height: 16),
        _section('Recorded custody', [
          Text('Original: ${detail.original.custodyLabel}'),
          Text(
            'Original stage: ${taskStageLabel(detail.original.stage ?? 'unknown')}',
          ),
          const SizedBox(height: 12),
          Text('Current: ${detail.current.custodyLabel}'),
          Text(
            'Current stage: ${taskStageLabel(detail.current.stage ?? 'unknown')}',
          ),
        ]),
        const SizedBox(height: 16),
        if (grant == null)
          _section('Recovery', [
            const Text(
              'No independently authorized recovery is available. Review and authorization take place in the web portals.',
            ),
          ])
        else
          _section('Authorized receiving route', [
            SelectableText(grant.reference),
            const SizedBox(height: 8),
            Text('Mode: ${grant.mode.replaceAll('_', ' ')}'),
            const SizedBox(height: 12),
            Text('Receiving hub: ${grant.hubName}'),
            SelectableText(grant.hubAddress ?? 'Receiving address unavailable'),
            const SizedBox(height: 8),
            Text('Grant expires: ${grant.expiresAt.toLocal()}'),
            if (grant.manifestReference != null)
              SelectableText('Original manifest: ${grant.manifestReference}'),
            if (grant.linkedReference != null)
              SelectableText('Linked recovery: ${grant.linkedReference}'),
            const SizedBox(height: 12),
            if (grant.acknowledged)
              const Text(
                'Possession acknowledgement recorded. Keep the parcel until the named hub records receipt.',
              )
            else if (!grant.holderIsMe)
              const Text(
                'The named holder must acknowledge this parcel. You cannot acknowledge for another person.',
              )
            else if (!grant.canAcknowledge(work.repository!.now()))
              Text(
                grant.blocker ?? 'This grant is closed, expired or unavailable. Refresh for current instructions.',
              )
            else ...[
              const Text(
                'Acknowledge only after checking the actual waybill and physically holding this parcel.',
              ),
              const SizedBox(height: 16),
              _field(
                'ack-barcode',
                'Matching actual waybill',
                _ackBarcode,
                limit: 255,
              ),
              if (work.failure?.fields['barcode'] != null)
                Text(work.failure!.fields['barcode']!),
              _field(
                'ack-notes',
                'Possession notes',
                _ackNotes,
                lines: 3,
                limit: 1000,
              ),
              if (work.failure?.fields['notes'] != null)
                Text(work.failure!.fields['notes']!),
              CheckboxListTile(
                key: const ValueKey('handover-possession'),
                contentPadding: EdgeInsets.zero,
                value: _possession,
                onChanged: work.canWrite
                    ? (value) => setState(() => _possession = value == true)
                    : null,
                title: const Text('I physically hold this exact parcel'),
                subtitle: const Text(
                  'This records possession. The hold stays until actual hub receipt.',
                ),
              ),
              if (work.failure?.fields['possession_verified'] != null)
                Text(work.failure!.fields['possession_verified']!),
              const SizedBox(height: 12),
              FilledButton(
                key: const ValueKey('handover-acknowledge'),
                onPressed: work.canWrite && _possession ? _acknowledge : null,
                child: const Text('Acknowledge possession'),
              ),
            ],
          ]),
        const SizedBox(height: 16),
        _section('Recorded history', [
          for (final event in detail.history)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${event.type.replaceAll('_', ' ')} · ${event.role}'),
                  Text(event.at.toLocal().toString()),
                  const SizedBox(height: 4),
                  SelectableText(event.notes),
                ],
              ),
            ),
        ]),
      ],
    );
  }
}
