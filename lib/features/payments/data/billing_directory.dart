part of 'billing_repository_impl.dart';

mixin _BillingDirectory implements BillingRepository {
  SupabaseService get _service;
  Future<Result<T>> _guard<T>(Future<T> Function() operation);

  @override
  Future<Result<List<BillingItem>>> catalog(
    String query, {
    required bool activeOnly,
    int offset = 0,
    int limit = 100,
    List<String> excluded = const [],
  }) => _guard(() async {
    final rows = await _service.guardQuery(() {
      var request = _service
          .from('billing_items')
          .select()
          .eq('kind', 'service');
      if (activeOnly) request = request.eq('active', true);
      if (excluded.isNotEmpty) request = request.not('id', 'in', excluded);
      if (query.trim().isNotEmpty) {
        request = request.ilike('name', '%${query.trim()}%');
      }
      return request
          .order('name')
          .order('id')
          .range(offset, offset + limit - 1);
    });
    return rows.map(BillingItem.fromJson).toList();
  });

  @override
  Future<Result<List<BillingItem>>> items(List<String> ids) => _guard(() async {
    final rows = await _service.guardQuery(
      () => _service
          .from('billing_items')
          .select()
          .eq('kind', 'service')
          .eq('active', true)
          .inFilter('id', ids),
    );
    return rows.map(BillingItem.fromJson).toList();
  });

  @override
  Future<Result<List<BillingParty>>> lookup(
    BillingLookup kind,
    String query,
    int offset,
    int limit,
  ) => _guard(() async {
    final rows = await _service.rpc<List<Object?>>(
      'billing_lookup_page',
      params: {
        'p_kind': kind.name,
        'p_query': query,
        'p_offset': offset,
        'p_limit': limit,
      },
    );
    return billingRows(rows).map(BillingParty.fromJson).toList();
  });
}
