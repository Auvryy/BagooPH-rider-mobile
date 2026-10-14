import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/rider_api_client.dart';
import '../../home/data/command_journal.dart' show commandUuid;
import '../data/handover_models.dart';
import '../data/handover_repository.dart';

/// Views authorized bytes in memory. No browser URL, exported document,
/// shared file or bearer-bearing third-party request is used by the viewer.
class HandoverEvidencePage extends StatefulWidget {
  const HandoverEvidencePage({
    super.key,
    required this.repository,
    required this.detail,
    required this.onFailure,
    this.documentBuilder,
  });
  final HandoverRepository repository;
  final HandoverDetail detail;
  final Future<void> Function(Object error) onFailure;
  final Widget Function(PrivateApiBytes)? documentBuilder;
  @override
  State<HandoverEvidencePage> createState() => _HandoverEvidencePageState();
}

class _HandoverEvidencePageState extends State<HandoverEvidencePage>
    with WidgetsBindingObserver {
  PrivateApiBytes? _document;
  MemoryImage? _image;
  String? _error;
  bool _loading = true, _foreground = true;
  int _generation = 0;
  final _source = commandUuid();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  void _clear() {
    _document = null;
    if (_image != null) {
      unawaited(_image!.evict());
      _image = null;
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _clear();
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.repository.evidence(widget.detail);
      if (!mounted ||
          generation != _generation ||
          !_foreground ||
          !widget.repository.isCurrent()) {
        return;
      }
      setState(() {
        _document = data;
        if (data.mimeType.startsWith('image/')) {
          _image = MemoryImage(data.bytes);
        }
      });
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(
          () => _error = error is AccountFailure
              ? error.message
              : 'Could not open private evidence. Refresh to try again.',
        );
        await widget.onFailure(error);
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      unawaited(_load());
    } else {
      _generation++;
      setState(() {
        _clear();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _generation++;
    _clear();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final document = _document;
    return Scaffold(
      key: const ValueKey('handover-evidence-page'),
      appBar: AppBar(
        title: const Text('Private evidence'),
        actions: [
          IconButton(
            tooltip: 'Refresh evidence',
            onPressed: _loading || !_foreground ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!),
                ),
              )
            : document == null
            ? const Center(
                child: Text('Return to Rider to revalidate this evidence.'),
              )
            : widget.documentBuilder != null
            ? widget.documentBuilder!(document)
            : document.mimeType == 'application/pdf'
            ? PdfViewer.data(
                document.bytes,
                sourceName: 'private-handover-$_source-$_generation',
                useProgressiveLoading: false,
                maxSizeToCacheOnMemory: 5242880,
                params: PdfViewerParams(
                  backgroundColor: RiderColors.canvas,
                  linkWidgetBuilder: (context, link, size) =>
                      const SizedBox.shrink(),
                  errorBannerBuilder:
                      (context, error, stackTrace, documentRef) => const Center(
                        child: Text(
                          'This PDF could not be displayed. Refresh or ask the reviewer to check the original document.',
                        ),
                      ),
                ),
              )
            : InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image(
                    image: _image!,
                    semanticLabel: 'Authorized handover evidence',
                    errorBuilder: (_, error, stack) =>
                        const Text('This image could not be displayed.'),
                  ),
                ),
              ),
      ),
    );
  }
}
