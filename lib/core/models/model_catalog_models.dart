/// Models for the HuggingFace model catalog and LM Studio download manager.
///
/// These models mirror the server-side DTOs in the models package.
/// [HfModelModel] maps to HfModelDto, [HfModelFileModel] maps to
/// HfModelFileDto, [DownloadProgressModel] maps to DownloadProgress,
/// and [LocalModelFileModel] maps to LocalModelFileDto.
library;

import 'package:myoffgridai_client/shared/utils/size_formatter.dart';

/// A model entry from the HuggingFace Hub catalog.
///
/// Represents a HuggingFace model repository with metadata and available files.
class HfModelModel {
  /// The full repository ID (e.g. "TheBloke/Llama-2-7B-GGUF").
  final String id;

  /// The repository author/organization.
  final String author;

  /// The model name portion of the repository ID.
  final String modelId;

  /// Total download count.
  final int downloads;

  /// Total like count.
  final int likes;

  /// Model tags (e.g. "text-generation", "gguf").
  final List<String> tags;

  /// Whether the model requires authorization to access.
  final bool isGated;

  /// The last modified timestamp.
  final DateTime? lastModified;

  /// Available files in the repository.
  final List<HfModelFileModel> files;

  /// Creates an [HfModelModel].
  const HfModelModel({
    required this.id,
    required this.author,
    required this.modelId,
    required this.downloads,
    required this.likes,
    required this.tags,
    required this.isGated,
    this.lastModified,
    required this.files,
  });

  /// Whether any GGUF files are available.
  bool get hasGguf => files.any((f) => f.filename.endsWith('.gguf'));

  /// Whether any MLX files are available.
  bool get hasMlx => files.any((f) => f.filename.contains('mlx'));

  /// Returns only the GGUF files from the file list.
  List<HfModelFileModel> get ggufFiles =>
      files.where((f) => f.filename.endsWith('.gguf')).toList();

  /// Creates an [HfModelModel] from a JSON map.
  factory HfModelModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final parts = id.split('/');
    final siblings = json['siblings'] as List<dynamic>? ?? [];

    return HfModelModel(
      id: id,
      author: json['author'] as String? ?? (parts.length > 1 ? parts[0] : ''),
      modelId: json['modelId'] as String? ?? (parts.length > 1 ? parts[1] : id),
      downloads: json['downloads'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          [],
      isGated: json['gated'] as bool? ?? false,
      lastModified: json['lastModified'] != null
          ? DateTime.tryParse(json['lastModified'] as String)
          : null,
      files: siblings
          .map((s) => HfModelFileModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A single file (quantization) available in a HuggingFace model repo.
///
/// Represents a downloadable file with size and quantization information.
class HfModelFileModel {
  /// The relative filename (e.g. "model-Q4_K_M.gguf").
  final String filename;

  /// File size in bytes (nullable — not all repos report size).
  final int? sizeBytes;

  /// Creates an [HfModelFileModel].
  const HfModelFileModel({
    required this.filename,
    this.sizeBytes,
  });

  /// Quantization label derived from filename (e.g. "Q4_K_M", "Q8_0", "F16").
  String get quantLabel {
    final match = RegExp(r'[.-](Q\d+_K_[A-Z]+|Q\d+_\d+|Q\d+|F\d+|IQ\d+_[A-Z]+)').firstMatch(filename);
    return match?.group(1) ?? '';
  }

  /// Human-readable file size.
  String get formattedSize {
    if (sizeBytes == null) return 'Unknown';
    return SizeFormatter.formatBytes(sizeBytes!);
  }

  /// Creates an [HfModelFileModel] from a JSON map.
  factory HfModelFileModel.fromJson(Map<String, dynamic> json) {
    return HfModelFileModel(
      filename: json['rfilename'] as String? ?? json['filename'] as String? ?? '',
      sizeBytes: json['size'] as int?,
    );
  }
}

/// Progress state for a model download.
///
/// Mirrors the server's DownloadProgress record. Updated in real-time
/// via SSE streaming from the download progress endpoint.
class DownloadProgressModel {
  /// The unique download identifier.
  final String downloadId;

  /// The HuggingFace repository ID.
  final String repoId;

  /// The file being downloaded.
  final String filename;

  /// The current download status.
  final String status;

  /// Bytes downloaded so far.
  final int bytesDownloaded;

  /// Total file size in bytes.
  final int totalBytes;

  /// Download completion percentage (0–100).
  final double percentComplete;

  /// Current download speed in bytes/second.
  final double speedBytesPerSecond;

  /// Estimated time remaining in seconds.
  final int estimatedSecondsRemaining;

  /// Error message if download failed (nullable).
  final String? errorMessage;

  /// Creates a [DownloadProgressModel].
  const DownloadProgressModel({
    required this.downloadId,
    required this.repoId,
    required this.filename,
    required this.status,
    required this.bytesDownloaded,
    required this.totalBytes,
    required this.percentComplete,
    required this.speedBytesPerSecond,
    required this.estimatedSecondsRemaining,
    this.errorMessage,
  });

  /// Whether the download is actively in progress.
  bool get isActive => status == 'DOWNLOADING' || status == 'QUEUED';

  /// Whether the download completed successfully.
  bool get isComplete => status == 'COMPLETED';

  /// Whether the download failed.
  bool get isFailed => status == 'FAILED';

  /// Whether the download was cancelled.
  bool get isCancelled => status == 'CANCELLED';

  /// Creates a [DownloadProgressModel] from a JSON map.
  factory DownloadProgressModel.fromJson(Map<String, dynamic> json) {
    return DownloadProgressModel(
      downloadId: json['downloadId'] as String? ?? '',
      repoId: json['repoId'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      status: json['status'] as String? ?? 'QUEUED',
      bytesDownloaded: json['bytesDownloaded'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int? ?? 0,
      percentComplete: (json['percentComplete'] as num?)?.toDouble() ?? 0.0,
      speedBytesPerSecond:
          (json['speedBytesPerSecond'] as num?)?.toDouble() ?? 0.0,
      estimatedSecondsRemaining:
          json['estimatedSecondsRemaining'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

/// A model file already downloaded to the LM Studio models directory.
///
/// Mirrors the server's LocalModelFileDto record.
class LocalModelFileModel {
  /// The file name (e.g. "model-Q4_K_M.gguf").
  final String filename;

  /// The HuggingFace repo ID derived from directory path (nullable).
  final String? repoId;

  /// The file format ("gguf", "mlx", or "unknown").
  final String format;

  /// The file size in bytes.
  final int sizeBytes;

  /// The last modification time.
  final DateTime? lastModified;

  /// Whether this model matches the active inference model.
  final bool isCurrentlyLoaded;

  /// Creates a [LocalModelFileModel].
  const LocalModelFileModel({
    required this.filename,
    this.repoId,
    required this.format,
    required this.sizeBytes,
    this.lastModified,
    required this.isCurrentlyLoaded,
  });

  /// Creates a [LocalModelFileModel] from a JSON map.
  factory LocalModelFileModel.fromJson(Map<String, dynamic> json) {
    return LocalModelFileModel(
      filename: json['filename'] as String? ?? '',
      repoId: json['repoId'] as String?,
      format: json['format'] as String? ?? 'unknown',
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      lastModified: json['lastModified'] != null
          ? DateTime.tryParse(json['lastModified'] as String)
          : null,
      isCurrentlyLoaded: json['isCurrentlyLoaded'] as bool? ?? false,
    );
  }
}
