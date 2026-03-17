import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/model_catalog_models.dart';

void main() {
  group('HfModelModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'id': 'TheBloke/Llama-2-7B-GGUF',
        'author': 'TheBloke',
        'modelId': 'Llama-2-7B-GGUF',
        'downloads': 150000,
        'likes': 420,
        'tags': ['text-generation', 'gguf', 'llama'],
        'gated': false,
        'lastModified': '2025-06-15T10:30:00Z',
        'siblings': [
          {'rfilename': 'llama-2-7b.Q4_K_M.gguf', 'size': 4370000000},
          {'rfilename': 'llama-2-7b.Q8_0.gguf', 'size': 7160000000},
          {'rfilename': 'README.md'},
        ],
      };

      final model = HfModelModel.fromJson(json);

      expect(model.id, 'TheBloke/Llama-2-7B-GGUF');
      expect(model.author, 'TheBloke');
      expect(model.modelId, 'Llama-2-7B-GGUF');
      expect(model.downloads, 150000);
      expect(model.likes, 420);
      expect(model.tags, ['text-generation', 'gguf', 'llama']);
      expect(model.isGated, isFalse);
      expect(model.lastModified, isNotNull);
      expect(model.files.length, 3);
    });

    test('derives author and modelId from id when not in JSON', () {
      final json = {
        'id': 'meta-llama/Meta-Llama-3-8B-GGUF',
        'downloads': 0,
        'likes': 0,
        'tags': <String>[],
        'siblings': <dynamic>[],
      };

      final model = HfModelModel.fromJson(json);

      expect(model.author, 'meta-llama');
      expect(model.modelId, 'Meta-Llama-3-8B-GGUF');
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final model = HfModelModel.fromJson(json);

      expect(model.id, '');
      expect(model.author, '');
      expect(model.modelId, '');
      expect(model.downloads, 0);
      expect(model.likes, 0);
      expect(model.tags, isEmpty);
      expect(model.isGated, isFalse);
      expect(model.lastModified, isNull);
      expect(model.files, isEmpty);
    });

    test('hasGguf returns true when GGUF files present', () {
      final model = HfModelModel.fromJson({
        'id': 'test/model',
        'siblings': [
          {'rfilename': 'model.Q4_K_M.gguf'},
        ],
      });

      expect(model.hasGguf, isTrue);
    });

    test('hasGguf returns false when no GGUF files', () {
      final model = HfModelModel.fromJson({
        'id': 'test/model',
        'siblings': [
          {'rfilename': 'README.md'},
        ],
      });

      expect(model.hasGguf, isFalse);
    });

    test('hasMlx returns true when MLX files present', () {
      final model = HfModelModel.fromJson({
        'id': 'test/model',
        'siblings': [
          {'rfilename': 'mlx-model/config.json'},
        ],
      });

      expect(model.hasMlx, isTrue);
    });

    test('ggufFiles filters to only GGUF files', () {
      final model = HfModelModel.fromJson({
        'id': 'test/model',
        'siblings': [
          {'rfilename': 'model.Q4_K_M.gguf'},
          {'rfilename': 'README.md'},
          {'rfilename': 'model.Q8_0.gguf'},
          {'rfilename': 'config.json'},
        ],
      });

      expect(model.ggufFiles.length, 2);
      expect(model.ggufFiles[0].filename, 'model.Q4_K_M.gguf');
      expect(model.ggufFiles[1].filename, 'model.Q8_0.gguf');
    });

    test('handles gated models', () {
      final model = HfModelModel.fromJson({
        'id': 'meta-llama/Llama-2-7b-hf',
        'gated': true,
        'siblings': <dynamic>[],
      });

      expect(model.isGated, isTrue);
    });
  });

  group('HfModelFileModel', () {
    test('parses from JSON with rfilename and size', () {
      final json = {
        'rfilename': 'model-Q4_K_M.gguf',
        'size': 4370000000,
      };

      final file = HfModelFileModel.fromJson(json);

      expect(file.filename, 'model-Q4_K_M.gguf');
      expect(file.sizeBytes, 4370000000);
    });

    test('uses filename field as fallback', () {
      final json = {
        'filename': 'fallback-model.gguf',
      };

      final file = HfModelFileModel.fromJson(json);

      expect(file.filename, 'fallback-model.gguf');
    });

    test('handles missing fields', () {
      final json = <String, dynamic>{};

      final file = HfModelFileModel.fromJson(json);

      expect(file.filename, '');
      expect(file.sizeBytes, isNull);
    });

    test('quantLabel extracts Q4_K_M', () {
      const file = HfModelFileModel(filename: 'model-Q4_K_M.gguf');
      expect(file.quantLabel, 'Q4_K_M');
    });

    test('quantLabel extracts Q8_0', () {
      const file = HfModelFileModel(filename: 'model.Q8_0.gguf');
      expect(file.quantLabel, 'Q8_0');
    });

    test('quantLabel extracts F16', () {
      const file = HfModelFileModel(filename: 'model-F16.gguf');
      expect(file.quantLabel, 'F16');
    });

    test('quantLabel extracts IQ2_M', () {
      const file = HfModelFileModel(filename: 'model-IQ2_M.gguf');
      expect(file.quantLabel, 'IQ2_M');
    });

    test('quantLabel returns empty for non-quantized files', () {
      const file = HfModelFileModel(filename: 'README.md');
      expect(file.quantLabel, '');
    });

    test('formattedSize returns formatted bytes', () {
      const file = HfModelFileModel(
        filename: 'model.gguf',
        sizeBytes: 4370000000,
      );
      expect(file.formattedSize, isNotEmpty);
      expect(file.formattedSize, contains('GB'));
    });

    test('formattedSize returns Unknown when null', () {
      const file = HfModelFileModel(filename: 'model.gguf');
      expect(file.formattedSize, 'Unknown');
    });

    // ── P15 new fields ──────────────────────────────────────────────────
    test('parses isRecommended from JSON', () {
      final json = {
        'rfilename': 'model-Q4_K_M.gguf',
        'recommended': true,
      };

      final file = HfModelFileModel.fromJson(json);

      expect(file.isRecommended, isTrue);
    });

    test('isRecommended defaults to false', () {
      final file = HfModelFileModel.fromJson(<String, dynamic>{});
      expect(file.isRecommended, isFalse);
    });

    test('parses qualityLabel from JSON', () {
      final json = {
        'rfilename': 'model-Q4_K_M.gguf',
        'qualityLabel': 'Medium — balanced (most popular)',
      };

      final file = HfModelFileModel.fromJson(json);

      expect(file.qualityLabel, 'Medium — balanced (most popular)');
    });

    test('parses qualityRank from JSON', () {
      final json = {
        'rfilename': 'model-Q4_K_M.gguf',
        'qualityRank': 8,
      };

      final file = HfModelFileModel.fromJson(json);

      expect(file.qualityRank, 8);
    });

    test('parses estimatedRamBytes from JSON', () {
      final json = {
        'rfilename': 'model-Q4_K_M.gguf',
        'estimatedRamBytes': 8589934592,
      };

      final file = HfModelFileModel.fromJson(json);

      expect(file.estimatedRamBytes, 8589934592);
    });

    test('parses quantizationType from JSON', () {
      final json = {
        'rfilename': 'model-Q4_K_M.gguf',
        'quantizationType': 'Q4_K_M',
      };

      final file = HfModelFileModel.fromJson(json);

      expect(file.quantizationType, 'Q4_K_M');
    });

    test('estimatedRamMb converts bytes to megabytes', () {
      const file = HfModelFileModel(
        filename: 'model.gguf',
        estimatedRamBytes: 8589934592, // 8192 MB
      );

      expect(file.estimatedRamMb, closeTo(8192.0, 0.1));
    });

    test('estimatedRamMb returns null when estimatedRamBytes is null', () {
      const file = HfModelFileModel(filename: 'model.gguf');
      expect(file.estimatedRamMb, isNull);
    });

    test('fitsInRam returns true when estimatedRamBytes is null', () {
      const file = HfModelFileModel(filename: 'model.gguf');
      expect(file.fitsInRam, isTrue);
    });

    test('fitsInRam returns true when isRecommended', () {
      const file = HfModelFileModel(
        filename: 'model.gguf',
        estimatedRamBytes: 999999999999,
        isRecommended: true,
      );
      expect(file.fitsInRam, isTrue);
    });

    test('fitsInRam returns false when not recommended and RAM is known', () {
      const file = HfModelFileModel(
        filename: 'model.gguf',
        estimatedRamBytes: 999999999999,
        isRecommended: false,
      );
      expect(file.fitsInRam, isFalse);
    });

    test('quantLabel falls back to quantizationType from server', () {
      const file = HfModelFileModel(
        filename: 'model.gguf',
        quantizationType: 'Q5_K_S',
      );
      expect(file.quantLabel, 'Q5_K_S');
    });

    test('parses all P15 fields together from JSON', () {
      final json = {
        'rfilename': 'model-Q6_K.gguf',
        'size': 5000000000,
        'recommended': true,
        'qualityLabel': 'High quality',
        'qualityRank': 10,
        'estimatedRamBytes': 7516192768,
        'quantizationType': 'Q6_K',
      };

      final file = HfModelFileModel.fromJson(json);

      expect(file.filename, 'model-Q6_K.gguf');
      expect(file.sizeBytes, 5000000000);
      expect(file.isRecommended, isTrue);
      expect(file.qualityLabel, 'High quality');
      expect(file.qualityRank, 10);
      expect(file.estimatedRamBytes, 7516192768);
      expect(file.quantizationType, 'Q6_K');
    });
  });

  group('DownloadProgressModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'downloadId': 'dl-123',
        'repoId': 'TheBloke/Llama-2-7B-GGUF',
        'filename': 'model.Q4_K_M.gguf',
        'status': 'DOWNLOADING',
        'bytesDownloaded': 2000000000,
        'totalBytes': 4370000000,
        'percentComplete': 45.8,
        'speedBytesPerSecond': 50000000.0,
        'estimatedSecondsRemaining': 47,
        'errorMessage': null,
      };

      final model = DownloadProgressModel.fromJson(json);

      expect(model.downloadId, 'dl-123');
      expect(model.repoId, 'TheBloke/Llama-2-7B-GGUF');
      expect(model.filename, 'model.Q4_K_M.gguf');
      expect(model.status, 'DOWNLOADING');
      expect(model.bytesDownloaded, 2000000000);
      expect(model.totalBytes, 4370000000);
      expect(model.percentComplete, 45.8);
      expect(model.speedBytesPerSecond, 50000000.0);
      expect(model.estimatedSecondsRemaining, 47);
      expect(model.errorMessage, isNull);
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final model = DownloadProgressModel.fromJson(json);

      expect(model.downloadId, '');
      expect(model.repoId, '');
      expect(model.filename, '');
      expect(model.status, 'QUEUED');
      expect(model.bytesDownloaded, 0);
      expect(model.totalBytes, 0);
      expect(model.percentComplete, 0.0);
      expect(model.speedBytesPerSecond, 0.0);
      expect(model.estimatedSecondsRemaining, 0);
      expect(model.errorMessage, isNull);
    });

    test('isActive returns true for DOWNLOADING', () {
      const model = DownloadProgressModel(
        downloadId: 'dl-1',
        repoId: 'r',
        filename: 'f',
        status: 'DOWNLOADING',
        bytesDownloaded: 0,
        totalBytes: 0,
        percentComplete: 0,
        speedBytesPerSecond: 0,
        estimatedSecondsRemaining: 0,
      );
      expect(model.isActive, isTrue);
    });

    test('isActive returns true for QUEUED', () {
      const model = DownloadProgressModel(
        downloadId: 'dl-1',
        repoId: 'r',
        filename: 'f',
        status: 'QUEUED',
        bytesDownloaded: 0,
        totalBytes: 0,
        percentComplete: 0,
        speedBytesPerSecond: 0,
        estimatedSecondsRemaining: 0,
      );
      expect(model.isActive, isTrue);
    });

    test('isComplete returns true for COMPLETED', () {
      const model = DownloadProgressModel(
        downloadId: 'dl-1',
        repoId: 'r',
        filename: 'f',
        status: 'COMPLETED',
        bytesDownloaded: 100,
        totalBytes: 100,
        percentComplete: 100,
        speedBytesPerSecond: 0,
        estimatedSecondsRemaining: 0,
      );
      expect(model.isComplete, isTrue);
      expect(model.isActive, isFalse);
    });

    test('isFailed returns true for FAILED', () {
      const model = DownloadProgressModel(
        downloadId: 'dl-1',
        repoId: 'r',
        filename: 'f',
        status: 'FAILED',
        bytesDownloaded: 50,
        totalBytes: 100,
        percentComplete: 50,
        speedBytesPerSecond: 0,
        estimatedSecondsRemaining: 0,
        errorMessage: 'Network error',
      );
      expect(model.isFailed, isTrue);
      expect(model.errorMessage, 'Network error');
    });

    test('isCancelled returns true for CANCELLED', () {
      const model = DownloadProgressModel(
        downloadId: 'dl-1',
        repoId: 'r',
        filename: 'f',
        status: 'CANCELLED',
        bytesDownloaded: 50,
        totalBytes: 100,
        percentComplete: 50,
        speedBytesPerSecond: 0,
        estimatedSecondsRemaining: 0,
      );
      expect(model.isCancelled, isTrue);
    });
  });

  group('LocalModelFileModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'filename': 'llama-2-7b.Q4_K_M.gguf',
        'repoId': 'TheBloke/Llama-2-7B-GGUF',
        'format': 'gguf',
        'sizeBytes': 4370000000,
        'lastModified': '2025-12-01T14:30:00Z',
        'isCurrentlyLoaded': true,
      };

      final model = LocalModelFileModel.fromJson(json);

      expect(model.filename, 'llama-2-7b.Q4_K_M.gguf');
      expect(model.repoId, 'TheBloke/Llama-2-7B-GGUF');
      expect(model.format, 'gguf');
      expect(model.sizeBytes, 4370000000);
      expect(model.lastModified, isNotNull);
      expect(model.isCurrentlyLoaded, isTrue);
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final model = LocalModelFileModel.fromJson(json);

      expect(model.filename, '');
      expect(model.repoId, isNull);
      expect(model.format, 'unknown');
      expect(model.sizeBytes, 0);
      expect(model.lastModified, isNull);
      expect(model.isCurrentlyLoaded, isFalse);
    });

    test('handles nullable repoId', () {
      final json = {
        'filename': 'standalone-model.gguf',
        'format': 'gguf',
        'sizeBytes': 1000,
        'isCurrentlyLoaded': false,
      };

      final model = LocalModelFileModel.fromJson(json);

      expect(model.repoId, isNull);
    });
  });
}
