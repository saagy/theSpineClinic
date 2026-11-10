part of 'billing_picker.dart';

const int _pageSize = 25;

class _BillingPicker<T> extends ConsumerStatefulWidget {
  const _BillingPicker({
    required this.scroll,
    required this.search,
    required this.watch,
    required this.retry,
    required this.tile,
    this.emptyCatalog = false,
    this.emptyMessage,
  });
  final ScrollController scroll;
  final String search;
  final AsyncValue<List<T>> Function(WidgetRef, String, int) watch;
  final void Function(WidgetRef, String, int) retry;
  final Widget Function(BuildContext, T) tile;
  final bool emptyCatalog;
  final String? emptyMessage;

  @override
  ConsumerState<_BillingPicker<T>> createState() => _BillingPickerState<T>();
}

class _BillingPickerState<T> extends ConsumerState<_BillingPicker<T>> {
  String _query = '';
  int _page = 0;

  void _change(String query, int page) {
    if (widget.scroll.hasClients) widget.scroll.jumpTo(0);
    setState(() {
      _query = query.trim();
      _page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final offset = _page * _pageSize;
    final result = widget.watch(ref, _query, offset);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: AppSearchBar(
            hintText: widget.search,
            onChanged: (query) => _change(query, 0),
          ),
        ),
        Expanded(
          child: result.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                billingError(error, () => widget.retry(ref, _query, offset)),
            data: (items) => items.isEmpty
                ? _empty(context)
                : Material(
                    type: MaterialType.transparency,
                    child: ListView.separated(
                      controller: widget.scroll,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p12,
                      ),
                      itemCount: items.take(_pageSize).length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: AppSizes.borderWidth),
                      itemBuilder: (context, index) =>
                          widget.tile(context, items[index]),
                    ),
                  ),
          ),
        ),
        if (_page > 0 || (result.value?.length ?? 0) > _pageSize) ...[
          const Divider(height: AppSizes.borderWidth),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: AppStrings.paginationPrevious,
                icon: const Icon(Icons.chevron_left),
                onPressed: _page == 0 ? null : () => _change(_query, _page - 1),
              ),
              Text(
                '${AppStrings.paginationPage} ${_page + 1}',
                style: AppTextStyles.captionMedium,
              ),
              IconButton(
                tooltip: AppStrings.paginationNext,
                icon: const Icon(Icons.chevron_right),
                onPressed: (result.value?.length ?? 0) <= _pageSize
                    ? null
                    : () => _change(_query, _page + 1),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _empty(BuildContext context) {
    if (_query.isNotEmpty || _page != 0) {
      return BillingEmpty(billingText.noMatches);
    }
    if (!widget.emptyCatalog) {
      return BillingEmpty(widget.emptyMessage ?? billingText.noMatches);
    }
    final canManage = BillingAccess.canManageCatalog(
      ref.watch(currentUserProvider).value,
    );
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              billingText.noActiveServices,
              style: AppTextStyles.bodyBold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.p8),
            if (canManage)
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BillingCatalogScreen(),
                      ),
                    ),
                child: Text(billingText.catalog),
              )
            else
              Text(
                billingText.askAdminForService,
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
