/// Mirrors the server's Spring `Page<T>` response structure.
///
/// Used for paginated list endpoints throughout the application.
class PageResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;
  final bool first;
  final bool last;
  final bool empty;

  const PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
    required this.first,
    required this.last,
    required this.empty,
  });

  /// Creates a [PageResponse] from a JSON map using the given [itemFactory]
  /// to deserialize each element in the `content` array.
  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFactory,
  ) {
    final contentList = (json['content'] as List<dynamic>?)
            ?.map((e) => itemFactory(e as Map<String, dynamic>))
            .toList() ??
        <T>[];
    return PageResponse<T>(
      content: contentList,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      number: json['number'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      first: json['first'] as bool? ?? true,
      last: json['last'] as bool? ?? true,
      empty: json['empty'] as bool? ?? contentList.isEmpty,
    );
  }
}
