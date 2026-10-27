import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:totalsolution/screens/auth/login_screen.dart' show NotificationService;

void main() {
  testWidgets('Slow polling does not overlap; disposed responses are ignored', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final result = Completer<int>();
    var requests = 0;
    final counts = <int>[];
    final service = NotificationService(fetchUnreadCount: (_) {
      requests++;
      return result.future;
    });
    service.init('D1', onUnreadCountChanged: counts.add);
    await tester.pump(const Duration(seconds: 15));
    expect(requests, 1);
    service.dispose();
    result.complete(8);
    await tester.pump();
    expect(counts, isEmpty);
    await tester.pump(const Duration(seconds: 10));
    expect(requests, 1);
  });

  testWidgets('Polling pauses in background and refreshes on resume', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    var requests = 0;
    final service = NotificationService(fetchUnreadCount: (_) async => ++requests);
    service.init('D1');
    await tester.pump();
    expect(requests, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 20));
    expect(requests, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(requests, 2);
    service.dispose();
  });

  testWidgets('Changing distributors ignores the previous account response', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final first = Completer<int>();
    final counts = <int>[];
    final service = NotificationService(fetchUnreadCount: (id) async {
      if (id == 'D1') return first.future;
      return 2;
    });
    service.init('D1', onUnreadCountChanged: counts.add);
    service.init('D2', onUnreadCountChanged: counts.add);
    first.complete(99);
    await tester.pump();
    expect(counts, isEmpty);
    await tester.pump(const Duration(seconds: 5));
    expect(counts, [2]);
    service.dispose();
  });
}
