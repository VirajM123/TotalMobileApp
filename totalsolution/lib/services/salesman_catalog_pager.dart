class CatalogPage<T> {
  final List<T> items;
  final int page;
  final int total;
  final bool hasMore;

  const CatalogPage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });
}

String? salesmanFullDataSectionForIndex(int index) => switch (index) {
  0 => 'dashboard',
  1 => 'orders',
  _ => null,
};

String? salesmanBrowseCatalogForIndex(int index) => switch (index) {
  4 => 'products',
  5 => 'customers',
  _ => null,
};

bool salesmanCatalogResponseIsComplete(Map<String, dynamic> data) =>
    data['customers'] is List &&
    data['products'] is List &&
    data['customerPage'] == null &&
    data['productPage'] == null &&
    data['hasMore'] != true;

class SalesmanCatalogPager<T> {
  SalesmanCatalogPager({required String Function(T) idFor}) : _idFor = idFor;

  final String Function(T) _idFor;
  List<T> _items = [];
  String? _queryKey;
  Object? _error;
  int _generation = 0;
  int _page = 0;
  int? _total;
  bool _hasMore = true;
  bool _isLoading = false;

  List<T> get items => List.unmodifiable(_items);
  String? get queryKey => _queryKey;
  Object? get error => _error;
  int get page => _page;
  int? get total => _total;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  void reset(String queryKey) {
    if (_queryKey == queryKey) return;
    restart(queryKey);
  }

  void restart(String queryKey) {
    _generation++;
    _queryKey = queryKey;
    _items = [];
    _error = null;
    _page = 0;
    _total = null;
    _hasMore = true;
    _isLoading = false;
  }

  Future<void> loadNext({
    required String queryKey,
    required Future<CatalogPage<T>> Function(int page) fetchPage,
  }) async {
    reset(queryKey);
    if (_isLoading || !_hasMore) return;

    final generation = _generation;
    final requestedPage = _page + 1;
    _isLoading = true;
    _error = null;

    try {
      final result = await fetchPage(requestedPage);
      if (generation != _generation) return;
      if (result.page != requestedPage) {
        throw FormatException(
          'Catalog returned page ${result.page}; expected $requestedPage',
        );
      }
      final merged = <String, T>{
        if (requestedPage > 1)
          for (final item in _items) _idFor(item): item,
      };
      for (final item in result.items) {
        merged[_idFor(item)] = item;
      }
      _items = merged.values.toList();
      _page = result.page;
      _total = result.total;
      _hasMore = result.hasMore;
    } catch (error) {
      if (generation == _generation) _error = error;
      rethrow;
    } finally {
      if (generation == _generation) _isLoading = false;
    }
  }
}
