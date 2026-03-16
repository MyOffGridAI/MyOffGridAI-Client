import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/enrichment_models.dart';

void main() {
  group('ExternalApiSettingsModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'anthropicEnabled': true,
        'anthropicModel': 'claude-sonnet-4-20250514',
        'anthropicKeyConfigured': true,
        'braveEnabled': false,
        'braveKeyConfigured': false,
        'maxWebFetchSizeKb': 1024,
        'searchResultLimit': 10,
      };

      final model = ExternalApiSettingsModel.fromJson(json);

      expect(model.anthropicEnabled, isTrue);
      expect(model.anthropicModel, 'claude-sonnet-4-20250514');
      expect(model.anthropicKeyConfigured, isTrue);
      expect(model.braveEnabled, isFalse);
      expect(model.braveKeyConfigured, isFalse);
      expect(model.maxWebFetchSizeKb, 1024);
      expect(model.searchResultLimit, 10);
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final model = ExternalApiSettingsModel.fromJson(json);

      expect(model.anthropicEnabled, isFalse);
      expect(model.anthropicModel, 'claude-sonnet-4-20250514');
      expect(model.anthropicKeyConfigured, isFalse);
      expect(model.braveEnabled, isFalse);
      expect(model.braveKeyConfigured, isFalse);
      expect(model.maxWebFetchSizeKb, 512);
      expect(model.searchResultLimit, 5);
    });
  });

  group('UpdateExternalApiSettingsRequest', () {
    test('toJson includes all non-null fields', () {
      const request = UpdateExternalApiSettingsRequest(
        anthropicApiKey: 'sk-ant-123',
        anthropicModel: 'claude-sonnet-4-20250514',
        anthropicEnabled: true,
        braveApiKey: 'brave-key-456',
        braveEnabled: true,
        maxWebFetchSizeKb: 1024,
        searchResultLimit: 10,
      );

      final json = request.toJson();

      expect(json['anthropicApiKey'], 'sk-ant-123');
      expect(json['anthropicModel'], 'claude-sonnet-4-20250514');
      expect(json['anthropicEnabled'], isTrue);
      expect(json['braveApiKey'], 'brave-key-456');
      expect(json['braveEnabled'], isTrue);
      expect(json['maxWebFetchSizeKb'], 1024);
      expect(json['searchResultLimit'], 10);
    });

    test('toJson omits null key fields', () {
      const request = UpdateExternalApiSettingsRequest(
        anthropicModel: 'claude-sonnet-4-20250514',
        anthropicEnabled: false,
        braveEnabled: false,
        maxWebFetchSizeKb: 512,
        searchResultLimit: 5,
      );

      final json = request.toJson();

      expect(json.containsKey('anthropicApiKey'), isFalse);
      expect(json.containsKey('braveApiKey'), isFalse);
      expect(json['anthropicModel'], 'claude-sonnet-4-20250514');
      expect(json['anthropicEnabled'], isFalse);
      expect(json['braveEnabled'], isFalse);
    });
  });

  group('SearchResultModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'title': 'Solar Power Guide',
        'url': 'https://example.com/solar',
        'description': 'Complete guide to solar power',
        'publishedDate': '2026-01-15',
      };

      final model = SearchResultModel.fromJson(json);

      expect(model.title, 'Solar Power Guide');
      expect(model.url, 'https://example.com/solar');
      expect(model.description, 'Complete guide to solar power');
      expect(model.publishedDate, '2026-01-15');
    });

    test('handles missing optional fields', () {
      final json = {
        'title': 'Result',
        'url': 'https://example.com',
        'description': 'A result',
      };

      final model = SearchResultModel.fromJson(json);

      expect(model.publishedDate, isNull);
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final model = SearchResultModel.fromJson(json);

      expect(model.title, '');
      expect(model.url, '');
      expect(model.description, '');
    });
  });

  group('EnrichmentStatusModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'claudeAvailable': true,
        'braveAvailable': false,
        'maxWebFetchSizeKb': 2048,
        'searchResultLimit': 8,
      };

      final model = EnrichmentStatusModel.fromJson(json);

      expect(model.claudeAvailable, isTrue);
      expect(model.braveAvailable, isFalse);
      expect(model.maxWebFetchSizeKb, 2048);
      expect(model.searchResultLimit, 8);
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final model = EnrichmentStatusModel.fromJson(json);

      expect(model.claudeAvailable, isFalse);
      expect(model.braveAvailable, isFalse);
      expect(model.maxWebFetchSizeKb, 512);
      expect(model.searchResultLimit, 5);
    });
  });

  group('UpdateExternalApiSettingsRequest constructor', () {
    test('anthropicApiKey and braveApiKey default to null', () {
      const request = UpdateExternalApiSettingsRequest(
        anthropicModel: 'claude-sonnet-4-20250514',
        anthropicEnabled: false,
        braveEnabled: false,
        maxWebFetchSizeKb: 512,
        searchResultLimit: 5,
      );
      expect(request.anthropicApiKey, isNull);
      expect(request.braveApiKey, isNull);
    });
  });
}
