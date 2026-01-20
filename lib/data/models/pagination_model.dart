/// Pagination Model
///
/// Represents pagination data from API responses.
/// Based on actual API response structure.
class Pagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;
  final bool? hasMorePages;

  const Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
    this.hasMorePages,
  });

  /// Create Pagination from JSON
  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 15,
      total: json['total'] as int? ?? 0,
      from: json['from'] as int?,
      to: json['to'] as int?,
      hasMorePages: json['has_more_pages'] as bool?,
    );
  }

  /// Convert Pagination to JSON
  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
      'from': from,
      'to': to,
      'has_more_pages': hasMorePages,
    };
  }

  /// Check if there are more pages
  bool get hasMore => hasMorePages ?? (currentPage < lastPage);

  /// Check if this is the first page
  bool get isFirstPage => currentPage == 1;

  /// Check if this is the last page
  bool get isLastPage => currentPage >= lastPage;

  /// Get next page number (or null if no more pages)
  int? get nextPage => hasMore ? currentPage + 1 : null;

  /// Get previous page number (or null if on first page)
  int? get previousPage => currentPage > 1 ? currentPage - 1 : null;

  @override
  String toString() =>
      'Pagination(page: $currentPage/$lastPage, total: $total)';
}
