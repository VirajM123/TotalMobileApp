import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:totalsolution/services/salesman_catalog_pager.dart';

class _Record {
  final String id;

  const _Record(this.id);
}

void main() {
  group('Salesman catalog section loading', () {
    test(
      'customer and product browse sections do not request full masters',
      () {
        expect(salesmanBrowseCatalogForIndex(5), 'customers');
        expect(salesmanBrowseCatalogForIndex(4), 'products');
        expect(salesmanFullDataSectionForIndex(5), isNull);
        expect(salesmanFullDataSectionForIndex(4), isNull);
        expect(salesmanFullDataSectionForIndex(2), isNull);
      },
    );

    test(
      'only an unpaginated complete catalog can satisfy full-master use',
      () {
        expect(
          salesmanCatalogResponseIsComplete({
            'customers': const [],
            'products': const [],
          }),
          isTrue,
        );
        expect(
          salesmanCatalogResponseIsComplete({
            'customers': const [],
            'products': const [],
            'customerPage': {'page': 1, 'total': 1000, 'hasMore': true},
          }),
          isFalse,
        );
        expect(
          salesmanCatalogResponseIsComplete({
            'customers': const [],
            'productPage': {'page': 1, 'total': 1000, 'hasMore': true},
          }),
          isFalse,
        );
        expect(
          salesmanCatalogResponseIsComplete({
            'customers': const [],
            'products': const [],
            'hasMore': true,
          }),
          isFalse,
        );
      },
    );
  });

  group('SalesmanCatalogPager', () {
    test(
      'opening each browse section issues one page-one request only',
      () async {
        for (final index in [4, 5]) {
          final pager = SalesmanCatalogPager<_Record>(
            idFor: (record) => record.id,
          );
          final requestedPages = <int>[];
          final fullMasterSection = salesmanFullDataSectionForIndex(index);
          final browseSection = salesmanBrowseCatalogForIndex(index);

          expect(fullMasterSection, isNull);
          expect(browseSection, isNotNull);
          await pager.loadNext(
            queryKey: '',
            fetchPage: (page) async {
              requestedPages.add(page);
              return CatalogPage(
                items: [_Record('$browseSection-$page')],
                page: page,
                total: 1,
                hasMore: false,
              );
            },
          );

          expect(requestedPages, [1]);
          expect(pager.items, hasLength(1));
        }
      },
    );

    test('loads all pages and retains records without duplicates', () async {
      final pager = SalesmanCatalogPager<_Record>(idFor: (item) => item.id);
      final calls = <int>[];

      Future<CatalogPage<_Record>> fetchPage(int page) async {
        calls.add(page);
        return switch (page) {
          1 => CatalogPage(
            items: [for (var i = 0; i < 200; i++) _Record('customer-$i')],
            page: 1,
            total: 401,
            hasMore: true,
          ),
          2 => CatalogPage(
            items: [
              _Record('customer-199'),
              for (var i = 200; i < 400; i++) _Record('customer-$i'),
            ],
            page: 2,
            total: 401,
            hasMore: true,
          ),
          _ => CatalogPage(
            items: [_Record('customer-400')],
            page: 3,
            total: 401,
            hasMore: false,
          ),
        };
      }

      await pager.loadNext(queryKey: '', fetchPage: fetchPage);
      expect(pager.page, 1);
      expect(pager.hasMore, isTrue);
      expect(pager.items, hasLength(200));

      await pager.loadNext(queryKey: '', fetchPage: fetchPage);
      expect(pager.page, 2);
      expect(pager.items, hasLength(400));
      expect(pager.items[199].id, 'customer-199');

      await pager.loadNext(queryKey: '', fetchPage: fetchPage);
      expect(pager.page, 3);
      expect(pager.items, hasLength(401));
      expect(pager.hasMore, isFalse);

      await pager.loadNext(queryKey: '', fetchPage: fetchPage);
      expect(calls, [1, 2, 3]);
    });

    test('deduplicates simultaneous requests for the same page', () async {
      final pager = SalesmanCatalogPager<_Record>(idFor: (item) => item.id);
      final response = Completer<CatalogPage<_Record>>();
      var calls = 0;

      Future<CatalogPage<_Record>> fetchPage(int page) {
        calls++;
        return response.future;
      }

      final first = pager.loadNext(queryKey: 'search', fetchPage: fetchPage);
      await pager.loadNext(queryKey: 'search', fetchPage: fetchPage);
      expect(calls, 1);
      response.complete(
        const CatalogPage(
          items: [_Record('one')],
          page: 1,
          total: 1,
          hasMore: false,
        ),
      );
      await first;
      expect(pager.items.single.id, 'one');
    });

    test(
      'resets page on query or filter changes and ignores stale responses',
      () async {
        final pager = SalesmanCatalogPager<_Record>(idFor: (item) => item.id);
        final staleResponse = Completer<CatalogPage<_Record>>();
        var calls = 0;

        final staleLoad = pager.loadNext(
          queryKey: '["","all"]',
          fetchPage: (_) {
            calls++;
            return staleResponse.future;
          },
        );
        pager.reset('["","inactive"]');
        await pager.loadNext(
          queryKey: '["","inactive"]',
          fetchPage: (page) async {
            calls++;
            return CatalogPage(
              items: [_Record('new-$page')],
              page: page,
              total: 1,
              hasMore: false,
            );
          },
        );
        staleResponse.complete(
          const CatalogPage(
            items: [_Record('old')],
            page: 1,
            total: 1,
            hasMore: false,
          ),
        );
        await staleLoad;

        expect(calls, 2);
        expect(pager.page, 1);
        expect(pager.items.map((item) => item.id), ['new-1']);
        expect(pager.queryKey, '["","inactive"]');
      },
    );

    test(
      'retries a failed first-page request without advancing the page',
      () async {
        final pager = SalesmanCatalogPager<_Record>(idFor: (item) => item.id);
        var calls = 0;

        await expectLater(
          pager.loadNext(
            queryKey: '',
            fetchPage: (_) async {
              calls++;
              throw StateError('offline');
            },
          ),
          throwsA(isA<StateError>()),
        );
        expect(pager.page, 0);
        expect(pager.error, isA<StateError>());

        await pager.loadNext(
          queryKey: '',
          fetchPage: (page) async {
            calls++;
            return CatalogPage(
              items: const [_Record('recovered')],
              page: page,
              total: 1,
              hasMore: false,
            );
          },
        );

        expect(calls, 2);
        expect(pager.page, 1);
        expect(pager.error, isNull);
        expect(pager.items.single.id, 'recovered');
      },
    );

    test(
      'keeps a successful empty result distinct from a failed request',
      () async {
        final pager = SalesmanCatalogPager<_Record>(idFor: (item) => item.id);
        await pager.loadNext(
          queryKey: '["none","all"]',
          fetchPage: (page) async => CatalogPage(
            items: const [],
            page: page,
            total: 0,
            hasMore: false,
          ),
        );

        expect(pager.error, isNull);
        expect(pager.page, 1);
        expect(pager.total, 0);
        expect(pager.hasMore, isFalse);
        expect(pager.items, isEmpty);
      },
    );

    test(
      'filter changes restart at page one and discard prior pages',
      () async {
        final pager = SalesmanCatalogPager<_Record>(idFor: (item) => item.id);
        final requestedPages = <int>[];

        Future<CatalogPage<_Record>> fetchPage(int page) async {
          requestedPages.add(page);
          return CatalogPage(
            items: [_Record('page-$page')],
            page: page,
            total: 2,
            hasMore: page == 1,
          );
        }

        await pager.loadNext(queryKey: '', fetchPage: fetchPage);
        await pager.loadNext(queryKey: '', fetchPage: fetchPage);
        pager.restart('');
        await pager.loadNext(queryKey: '', fetchPage: fetchPage);

        expect(requestedPages, [1, 2, 1]);
        expect(pager.page, 1);
        expect(pager.items.map((item) => item.id), ['page-1']);
      },
    );

    test('handles a 12,500-record catalog using page transitions', () async {
      const total = 12500;
      const pageSize = 200;
      final pager = SalesmanCatalogPager<_Record>(idFor: (item) => item.id);
      var requests = 0;

      Future<CatalogPage<_Record>> fetchPage(int page) async {
        requests++;
        final start = (page - 1) * pageSize;
        final end = (start + pageSize).clamp(0, total);
        return CatalogPage(
          items: [for (var i = start; i < end; i++) _Record('record-$i')],
          page: page,
          total: total,
          hasMore: end < total,
        );
      }

      while (pager.page == 0 || pager.hasMore) {
        await pager.loadNext(queryKey: 'large', fetchPage: fetchPage);
      }

      expect(pager.items, hasLength(total));
      expect(pager.items.first.id, 'record-0');
      expect(pager.items.last.id, 'record-12499');
      expect(pager.total, total);
      expect(requests, 63);
    });
  });
}
