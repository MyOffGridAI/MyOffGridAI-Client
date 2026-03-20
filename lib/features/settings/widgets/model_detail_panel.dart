import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/model_catalog_models.dart';
import 'package:myoffgridai_client/core/services/model_catalog_service.dart';
import 'package:myoffgridai_client/features/settings/widgets/smart_quant_selector.dart';
import 'package:myoffgridai_client/shared/utils/date_formatter.dart';
import 'package:myoffgridai_client/shared/utils/size_formatter.dart';

/// Detail panel for a selected HuggingFace model file.
///
/// Shows the model name, stats, tag chips, selected quantization variant with
/// a [SmartQuantSelector], estimated RAM usage, and a download button with
/// inline progress. Used as the right panel in the two-panel Discover layout.
class ModelDetailPanel extends ConsumerStatefulWidget {
  /// The parent model repository.
  final HfModelModel model;

  /// The initially selected GGUF file.
  final HfModelFileModel initialFile;

  /// Called when the user closes this panel.
  final VoidCallback? onClose;

  /// Creates a [ModelDetailPanel].
  const ModelDetailPanel({
    super.key,
    required this.model,
    required this.initialFile,
    this.onClose,
  });

  @override
  ConsumerState<ModelDetailPanel> createState() => _ModelDetailPanelState();
}

class _ModelDetailPanelState extends ConsumerState<ModelDetailPanel> {
  late HfModelFileModel _selectedFile;
  DownloadProgressModel? _downloadProgress;
  StreamSubscription<DownloadProgressModel>? _downloadSub;

  @override
  void initState() {
    super.initState();
    _selectedFile = widget.initialFile;
  }

  @override
  void didUpdateWidget(ModelDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.id != widget.model.id ||
        oldWidget.initialFile.filename != widget.initialFile.filename) {
      _selectedFile = widget.initialFile;
      _cancelDownloadSubscription();
    }
  }

  @override
  void dispose() {
    _cancelDownloadSubscription();
    super.dispose();
  }

  void _cancelDownloadSubscription() {
    _downloadSub?.cancel();
    _downloadSub = null;
  }

  /// Starts a download and subscribes to progress updates.
  Future<void> _startDownload() async {
    try {
      final service = ref.read(modelCatalogServiceProvider);
      final result = await service.startDownload(
        repoId: widget.model.id,
        filename: _selectedFile.filename,
      );
      final downloadId = result['downloadId'] as String;

      setState(() {
        _downloadProgress = DownloadProgressModel(
          downloadId: downloadId,
          repoId: widget.model.id,
          filename: _selectedFile.filename,
          status: 'QUEUED',
          bytesDownloaded: 0,
          totalBytes: result['estimatedSizeBytes'] as int? ?? 0,
          percentComplete: 0,
          speedBytesPerSecond: 0,
          estimatedSecondsRemaining: 0,
        );
      });

      _downloadSub = service.streamDownloadProgress(downloadId).listen(
        (progress) {
          if (mounted) setState(() => _downloadProgress = progress);
        },
        onError: (_) {
          if (mounted) setState(() => _downloadProgress = null);
          _cancelDownloadSubscription();
        },
        onDone: () {
          if (_downloadProgress?.isComplete == true) {
            ref.invalidate(localModelsProvider);
          }
          _cancelDownloadSubscription();
        },
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start download')),
        );
      }
    }
  }

  /// Cancels the active download.
  Future<void> _cancelDownload() async {
    if (_downloadProgress == null) return;
    try {
      final service = ref.read(modelCatalogServiceProvider);
      await service.cancelDownload(_downloadProgress!.downloadId);
      _cancelDownloadSubscription();
      if (mounted) setState(() => _downloadProgress = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel download')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dimText = colorScheme.onSurface.withValues(alpha: 0.6);
    final ggufFiles = widget.model.ggufFiles;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.model.id,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                    iconSize: 20,
                  ),
              ],
            ),
            Text(
              widget.model.author,
              style: TextStyle(fontSize: 12, color: dimText),
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                Icon(Icons.download_outlined, size: 14, color: dimText),
                const SizedBox(width: 4),
                Text(
                  '${SizeFormatter.formatCount(widget.model.downloads)} downloads',
                  style: TextStyle(fontSize: 12, color: dimText),
                ),
                const SizedBox(width: 16),
                Icon(Icons.favorite_border, size: 14, color: dimText),
                const SizedBox(width: 4),
                Text(
                  '${SizeFormatter.formatCount(widget.model.likes)} likes',
                  style: TextStyle(fontSize: 12, color: dimText),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Updated timestamp
            if (widget.model.lastModified != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Updated ${DateFormatter.formatRelative(widget.model.lastModified!)}',
                  style: TextStyle(fontSize: 11, color: dimText),
                ),
              ),
            const SizedBox(height: 4),

            // Tag chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (widget.model.pipelineTag != null)
                  _DetailTagChip(
                    label: widget.model.pipelineTag!,
                    color: colorScheme.primaryContainer,
                    textColor: colorScheme.onPrimaryContainer,
                  ),
                _DetailTagChip(
                  label: 'GGUF',
                  color: colorScheme.tertiaryContainer,
                  textColor: colorScheme.onTertiaryContainer,
                ),
                if (widget.model.isGated)
                  _DetailTagChip(
                    label: 'Gated',
                    color: colorScheme.errorContainer,
                    textColor: colorScheme.onErrorContainer,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Section divider
            Row(
              children: [
                Expanded(child: Divider(color: dimText.withValues(alpha: 0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Download Options',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: dimText,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: dimText.withValues(alpha: 0.3))),
              ],
            ),
            const SizedBox(height: 12),

            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quantization selector
                    Text(
                      'Select Quantization',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    SmartQuantSelector(
                      files: ggufFiles,
                      selected: _selectedFile,
                      onSelected: (file) =>
                          setState(() => _selectedFile = file),
                    ),
                    const SizedBox(height: 16),

                    // Selected file details
                    _DetailRow(
                      label: 'File',
                      value: _selectedFile.filename,
                    ),
                    _DetailRow(
                      label: 'Size',
                      value: _selectedFile.formattedSize,
                    ),
                    if (_selectedFile.qualityLabel != null)
                      _DetailRow(
                        label: 'Quality',
                        value: _selectedFile.qualityLabel!,
                      ),
                    if (_selectedFile.estimatedRamMb != null)
                      _DetailRow(
                        label: 'Est. RAM',
                        value:
                            '${_selectedFile.estimatedRamMb!.toStringAsFixed(0)} MB',
                      ),
                    if (_selectedFile.isRecommended)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              'Recommended for your system',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Download button or progress (pinned at bottom)
            if (_downloadProgress != null)
              _DownloadProgressSection(
                progress: _downloadProgress!,
                onCancel: _cancelDownload,
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startDownload,
                  icon: const Icon(Icons.download),
                  label: Text(
                      'Download ${_selectedFile.formattedSize}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A small styled chip for the detail panel tags.
class _DetailTagChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _DetailTagChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

/// A label-value detail row.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline download progress with cancel button.
class _DownloadProgressSection extends StatelessWidget {
  final DownloadProgressModel progress;
  final VoidCallback onCancel;

  const _DownloadProgressSection({
    required this.progress,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (progress.isComplete) {
      return Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          const Text('Download complete'),
        ],
      );
    }

    if (progress.isFailed) {
      return Row(
        children: [
          Icon(Icons.error, color: colorScheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              progress.errorMessage ?? 'Download failed',
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress.percentComplete / 100,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${progress.percentComplete.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 11),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onCancel,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${SizeFormatter.formatBytes(progress.bytesDownloaded)} / ${SizeFormatter.formatBytes(progress.totalBytes)}'
          '${progress.speedBytesPerSecond > 0 ? ' · ${SizeFormatter.formatBytes(progress.speedBytesPerSecond.round())}/s' : ''}',
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
