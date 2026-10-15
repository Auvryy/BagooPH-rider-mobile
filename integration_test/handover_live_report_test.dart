import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/security/token_store.dart';
import 'package:bagoo_rider_mobile/features/auth/data/auth_repository.dart';
import 'package:bagoo_rider_mobile/features/handover/data/handover_intent.dart';
import 'package:bagoo_rider_mobile/features/handover/data/handover_repository.dart';
import 'package:bagoo_rider_mobile/features/handover/presentation/handover_controller.dart';
import 'package:bagoo_rider_mobile/features/handover/presentation/handover_issues_page.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdfrx/pdfrx.dart';

// Explicit operator-only acceptance. Credentials and designated identifiers come
// from a mode-600 runtime file, never source or compile-time build definitions.
// The only domain write is one missed-scan report. Reruns reconcile its original
// journal/receipt key; they cannot silently create another report.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('LIVE_HANDOVER_REPORT_CHECK');
  testWidgets('native Linux submits the designated software-test report', (
    tester,
  ) async {
    if (!Platform.isLinux) throw StateError('This acceptance targets Linux.');
    final path = Platform.environment['BAGOO_LIVE_HANDOVER_CASE'];
    if (path == null) throw StateError('Supply the private acceptance case.');
    final caseFile = File(path);
    if ((await caseFile.stat()).mode & 0x3f != 0) {
      throw StateError('The acceptance case must be private (mode 600).');
    }
    final info = Wire.object(jsonDecode(await caseFile.readAsString()));
    String value(String key) => Wire.string(info[key]);
    final config = AppConfig.environment();
    if (config.origin.scheme != 'https' ||
        config.origin.host != 'bagooph.shop' ||
        !config.handoverWritesVerified ||
        config.operationsWritesVerified) {
      throw StateError(
        'Use verified H04 HTTPS with duty/claim writes disabled.',
      );
    }
    final output = Directory(value('output_directory'));
    if (output.absolute.path != caseFile.parent.absolute.path) {
      throw StateError(
        'Keep the acceptance artifacts beside the private case.',
      );
    }
    final receiptFile = File('${output.path}/receipt.json');
    final receipt = await receiptFile.exists()
        ? Wire.object(jsonDecode(await receiptFile.readAsString()))
        : <String, dynamic>{};
    Future<void> save() => _privateWrite(
      receiptFile,
      utf8.encode(const JsonEncoder.withIndent('  ').convert(receipt)),
    );
    final auth = ApiAuthRepository(config, MemoryTokenStore());
    HandoverController? controller;
    var loggedIn = false;
    try {
      final account = await auth.login(value('email'), value('password'));
      loggedIn = true;
      if (account.id != value('account_id') ||
          !account.approved ||
          account.operationsApiVersion != 1 ||
          account.handoverApiVersion != 1) {
        throw StateError(
          'The designated approved version-1 rider is required.',
        );
      }
      final journal = _RecordedJournal(
        SecureHandoverJournal(origin: config.origin, accountId: account.id),
        (intent) async {
          receipt['command_key'] = intent.key;
          receipt['evidence_sha256'] = intent.file!.digest;
          receipt['phase'] = 'intent_saved_before_dispatch';
          await save();
        },
      );
      final repo = HandoverRepository(
        auth,
        accountId: account.id,
        journal: journal,
        isCurrent: () => loggedIn,
        writesVerified: config.handoverWritesVerified,
        sessionVersion: account.handoverApiVersion,
      );
      final home = await repo.home();
      if (!repo.canRead(home) || !repo.canWrite(home)) {
        throw StateError('Current Home must permit H04 reading and reporting.');
      }
      final task = OperationTask.fromJson(
        Wire.object(
          (await auth.authenticatedRequest(
            'rider/tasks/${value('task_id')}',
          ))['data'],
        ),
      );
      if (task.id != value('task_id') ||
          task.deliveryId != value('parcel_id') ||
          task.tracking != value('tracking') ||
          task.order != value('order') ||
          task.preview ||
          task.phase != 'pickup' ||
          task.stage != value('expected_stage') ||
          task.commercialStatus != value('expected_status') ||
          task.custodyKind != value('expected_custody') ||
          task.heldByMe) {
        throw StateError('The owned designated task changed; no report sent.');
      }
      receipt.addAll({
        'account_id': account.id,
        'task_id': task.id,
        'tracking': task.tracking,
        'operator_verified_deployment': value('deployed_revision'),
        'last_preflight_at': DateTime.now().toUtc().toIso8601String(),
      });
      await save();
      final documentFile = File('${output.path}/software-test-evidence.pdf');
      if (!await documentFile.exists()) {
        await _privateWrite(documentFile, _softwareEvidence(task, receipt));
      }
      final file = await HandoverFile.fromFile(XFile(documentFile.path));
      pdfrxFlutterInitialize();
      final document = await PdfDocument.openData(
        file.bytes,
        sourceName: 'software-test-evidence',
      );
      try {
        expect(document.pages.length, 1);
        final image = await document.pages.first.render(
          width: 306,
          height: 396,
        );
        expect(image, isNotNull);
        expect(image!.pixels.toSet().length, greaterThan(1));
        image.dispose();
      } finally {
        await document.dispose();
      }

      final pending = await repo.pending();
      if (pending != null) {
        if (pending.action != 'handover.report' ||
            pending.body['barcode'] != task.tracking ||
            pending.file?.digest != file.digest ||
            (receipt['command_key'] != null &&
                receipt['command_key'] != pending.key)) {
          throw StateError('A different retained intent needs reconciliation.');
        }
        receipt['command_key'] = pending.key;
        await save();
        await repo.reconcile(retryUnknown: true);
      } else if (receipt['command_key'] == null) {
        // Refuse a duplicate even when a different client created the report.
        final issues = await repo.list(status: 'all');
        if (issues.hasNext ||
            issues.items.any((issue) => issue.tracking == task.tracking)) {
          throw StateError(
            'Inspect existing involved reports before any write.',
          );
        }
        controller = HandoverController(repo);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildRiderTheme(),
            home: HandoverIssuesView(
              controller: controller,
              initialBarcode: task.tracking,
              pickFile: () async => XFile(documentFile.path),
            ),
          ),
        );
        await _until(
          tester,
          () => controller!.home != null && !controller.loading,
        );
        expect(controller.canWrite, true);
        await _tap(tester, 'handover-new-report');
        for (final entry in {
          'reported_holder': 'Physical holder unverified - software test',
          'reported_location':
              'Linux software test; physical location unverified',
          'notes':
              'Authorized software-test missed-scan report for the designated test parcel. '
              'The current server task records seller custody. No normal pickup scan was '
              'performed during this run. The attached PDF records software checks only; '
              'physical possession, location and receipt are unverified. Independent web review is required.',
        }.entries) {
          await _reveal(tester, 'handover-${entry.key}');
          await tester.enterText(
            find.byKey(ValueKey('handover-${entry.key}')),
            entry.value,
          );
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await _tap(tester, 'handover-pick-evidence');
        await _until(
          tester,
          () => find.text('software-test-evidence.pdf').evaluate().isNotEmpty,
        );
        await _tap(tester, 'handover-submit-report');
        await _until(tester, () => !controller!.busy && !controller.loading);
        if (await repo.pending() != null) {
          // One explicit same-key recovery, never a second UI submission.
          await repo.reconcile(retryUnknown: true);
        }
        if (receipt['command_key'] == null) {
          throw StateError('No report intent was dispatched by the form.');
        }
      }

      final key = Wire.uuid(receipt['command_key']);
      final command = Wire.object(
        (await auth.authenticatedRequest('rider/commands/$key'))['data'],
      );
      expect(command['idempotency_key'], key);
      expect(command['action'], 'handover.report');
      expect(command['resource'], 'handover-report');
      expect(command['state'], 'committed');
      final result = Wire.object(command['result']);
      receipt['result'] = result;
      receipt['phase'] = 'committed';
      await save();
      final detail = await repo.detail(Wire.id(result['issue_id']));
      expect(detail.reference, result['reference']);
      expect(detail.tracking, task.tracking);
      expect(detail.state, 'pending_review');
      expect(detail.kind, 'missed_scan');
      expect(detail.held, false);
      expect(detail.recovery, isNull);
      expect(detail.history.map((event) => event.type), ['reported']);
      for (final snapshot in [detail.original, detail.current]) {
        expect(snapshot.custodyKind, task.custodyKind);
        expect(snapshot.stage, task.stage);
        expect(snapshot.status, task.commercialStatus);
      }
      final downloaded = await repo.evidence(detail);
      expect(downloaded.mimeType, 'application/pdf');
      expect(sha256.convert(downloaded.bytes).toString(), file.digest);
      expect(downloaded.bytes, file.bytes);
      expect(await repo.pending(), isNull);
      receipt.addAll({
        'phase': 'verified',
        'verified_at': DateTime.now().toUtc().toIso8601String(),
        'evidence_bytes': file.bytes.length,
        'evidence_sha256': file.digest,
        'private_download_matches_original': true,
        'custody_unchanged': true,
        'recovery': null,
      });
      await save();
      debugPrint(
        'Verified one native Azure software-test report and private PDF.',
      );
    } on AccountFailure catch (error) {
      receipt['last_failure'] = {
        'status': error.status,
        'code': error.code,
        'request_id': error.requestId,
        'fields': error.fields,
        'unconfirmed': error.unconfirmed,
        'at': DateTime.now().toUtc().toIso8601String(),
      };
      await save();
      throw StateError('Azure acceptance failed; inspect the private receipt.');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      controller?.dispose();
      if (loggedIn) {
        await auth.logout();
        loggedIn = false;
        receipt['temporary_session_logged_out'] = true;
        await save();
      }
      // Never clear a retained uncertain domain intent in test cleanup.
    }
  }, skip: !enabled);
}

class _RecordedJournal implements HandoverJournal {
  _RecordedJournal(this.delegate, this.record);
  final HandoverJournal delegate;
  final Future<void> Function(HandoverIntent) record;
  @override
  Future<HandoverIntent?> read() => delegate.read();
  @override
  Future<void> write(HandoverIntent intent) async {
    await delegate.write(intent);
    await record(intent);
  }

  @override
  Future<void> clear() => delegate.clear();
}

Future<void> _privateWrite(File file, List<int> bytes) async {
  await file.writeAsBytes(bytes, flush: true);
  final result = await Process.run('chmod', ['600', file.path]);
  if (result.exitCode != 0) {
    throw StateError('Cannot protect acceptance artifact.');
  }
}

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  final elapsed = Stopwatch()..start();
  while (!ready()) {
    if (elapsed.elapsed > const Duration(seconds: 45)) {
      throw StateError(
        'Native acceptance timed out; preserve the original intent.',
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  await tester.pump();
}

Future<void> _reveal(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('handover-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(target);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String key) async {
  await _reveal(tester, key);
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pump();
}

Uint8List _softwareEvidence(OperationTask task, Map<String, dynamic> receipt) {
  final lines = [
    'BAGOO - SOFTWARE TEST EVIDENCE',
    'Authorized controlled missed-scan API test; not a parcel photograph.',
    '',
    'Generated after fresh native Linux HTTPS account, Home and task reads.',
    'Observed UTC: ${receipt['last_preflight_at']}',
    'Operator-confirmed Azure revision:',
    receipt['operator_verified_deployment'] as String,
    'Approved rider account ID: ${receipt['account_id']}',
    'Task: ${task.id}',
    'Waybill: ${task.tracking}',
    'Order: ${task.order}',
    'Server commercial status: ${task.commercialStatus}',
    'Server operational stage: ${task.stage}',
    'Server recorded custody: ${task.custodyKind}',
    'Account operations API: 1; handover API: 1.',
    'Home allows involved handover reads and missed-scan reporting.',
    '',
    'This run has not performed a normal pickup scan.',
    'Physical holder, physical location and actual receipt are UNVERIFIED.',
    'No physical missed-scan observation or possession is certified here.',
    'This PDF records software-test facts for independent web review.',
    'Reporting must leave custody unchanged, no hold and recovery null.',
    'Review, recovery authorization and hub receipt remain separate.',
  ];
  String literal(String text) => text
      .replaceAll('\\', '\\\\')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)');
  final content =
      'BT /F1 11 Tf 14 TL 40 750 Td\n'
      '${lines.map((line) => '(${literal(line)}) Tj T*').join('\n')}\nET\n';
  final objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
        '/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    '<< /Length ${ascii.encode(content).length} >>\nstream\n${content}endstream',
  ];
  var pdf = '%PDF-1.4\n';
  final offsets = <int>[];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(ascii.encode(pdf).length);
    pdf += '${i + 1} 0 obj\n${objects[i]}\nendobj\n';
  }
  final xref = ascii.encode(pdf).length;
  pdf += 'xref\n0 ${objects.length + 1}\n0000000000 65535 f \n';
  for (final offset in offsets) {
    pdf += '${offset.toString().padLeft(10, '0')} 00000 n \n';
  }
  pdf +=
      'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n'
      'startxref\n$xref\n%%EOF\n';
  return Uint8List.fromList(ascii.encode(pdf));
}
