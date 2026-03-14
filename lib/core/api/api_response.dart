/// Mirrors the server's `ApiResponse<T>` envelope.
///
/// Every API response from MyOffGridAI-Server is wrapped in this structure,
/// providing consistent success/failure signaling and optional metadata.
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? timestamp;
  final String? requestId;
  final int? totalElements;
  final int? page;
  final int? size;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.timestamp,
    this.requestId,
    this.totalElements,
    this.page,
    this.size,
  });

  /// Creates an [ApiResponse] from a JSON map using the given [fromJsonT]
  /// factory to deserialize the `data` field.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      timestamp: json['timestamp'] as String?,
      requestId: json['requestId'] as String?,
      totalElements: json['totalElements'] as int?,
      page: json['page'] as int?,
      size: json['size'] as int?,
    );
  }
}
