import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/page.dart';

class _FakeCatalog implements PagedSource<int> {
  int calls = 0;

  @override
  Future<Page<int>> fetchPage(PageRequest request) async {
    calls++;
    if (request.cursor == null) {
      return const Page(items: [1, 2], hasMore: true);
    }
    return const Page(items: [3], hasMore: false);
  }
}

void main() {
  test('a cursor-paged catalog terminates without fetching everything',
      () async {
    final catalog = _FakeCatalog();

    final first = await catalog.fetchPage(const PageRequest(limit: 2));
    expect(first.items, [1, 2]);
    expect(first.hasMore, true);

    final second = await catalog.fetchPage(
      const PageRequest(limit: 2, cursor: '2'),
    );
    expect(second.items, [3]);
    expect(second.hasMore, false);
    expect(catalog.calls, 2);
  });
}
