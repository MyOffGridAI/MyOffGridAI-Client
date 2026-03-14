/// Represents a document in the Knowledge Vault.
///
/// Mirrors the server's KnowledgeDocumentDto. The [status] field uses
/// enum values: PENDING, PROCESSING, INDEXED, FAILED.
class KnowledgeDocumentModel {
  final String id;
  final String filename;
  final String? displayName;
  final String? mimeType;
  final int fileSizeBytes;
  final String status;
  final String? errorMessage;
  final int chunkCount;
  final String? uploadedAt;
  final String? processedAt;

  const KnowledgeDocumentModel({
    required this.id,
    required this.filename,
    this.displayName,
    this.mimeType,
    required this.fileSizeBytes,
    required this.status,
    this.errorMessage,
    required this.chunkCount,
    this.uploadedAt,
    this.processedAt,
  });

  /// Creates a [KnowledgeDocumentModel] from a JSON map.
  factory KnowledgeDocumentModel.fromJson(Map<String, dynamic> json) {
    return KnowledgeDocumentModel(
      id: json['id'] as String,
      filename: json['filename'] as String? ?? '',
      displayName: json['displayName'] as String?,
      mimeType: json['mimeType'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      status: json['status'] as String? ?? 'PENDING',
      errorMessage: json['errorMessage'] as String?,
      chunkCount: json['chunkCount'] as int? ?? 0,
      uploadedAt: json['uploadedAt'] as String?,
      processedAt: json['processedAt'] as String?,
    );
  }

  /// Whether the document is currently being processed.
  bool get isProcessing => status == 'PROCESSING';

  /// Whether the document has been fully indexed.
  bool get isIndexed => status == 'INDEXED';

  /// Whether processing failed.
  bool get isFailed => status == 'FAILED';
}

/// Result of a semantic knowledge search.
///
/// Mirrors the server's KnowledgeSearchResultDto.
class KnowledgeSearchResultModel {
  final String chunkId;
  final String documentId;
  final String documentName;
  final String content;
  final int? pageNumber;
  final int chunkIndex;
  final double similarityScore;

  const KnowledgeSearchResultModel({
    required this.chunkId,
    required this.documentId,
    required this.documentName,
    required this.content,
    this.pageNumber,
    required this.chunkIndex,
    required this.similarityScore,
  });

  /// Creates a [KnowledgeSearchResultModel] from a JSON map.
  factory KnowledgeSearchResultModel.fromJson(Map<String, dynamic> json) {
    return KnowledgeSearchResultModel(
      chunkId: json['chunkId'] as String,
      documentId: json['documentId'] as String,
      documentName: json['documentName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      pageNumber: json['pageNumber'] as int?,
      chunkIndex: json['chunkIndex'] as int? ?? 0,
      similarityScore: (json['similarityScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
