/// Entity representing the result of a lookup search.
/// This is a placeholder that can be expanded later when the actual API is defined.
class LookupResult {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final DateTime createdAt;

  const LookupResult({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.createdAt,
  });
}
