import 'package:beecount/pages/transaction/local_quick_entry_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('com.tntlikely.beecount/system_speech');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('recognized text follows the existing draft review flow', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'recognizeChinese');
      return '今天午饭35';
    });
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: LocalQuickEntryPage()),
    ));
    await tester.tap(find.text('中文语音输入'));
    await tester.pumpAndSettle();
    expect(find.text('今天午饭35'), findsOneWidget);
    expect(find.text('生成待确认草稿'), findsOneWidget);
    await tester.tap(find.text('生成待确认草稿'));
    await tester.pumpAndSettle();
    expect(find.textContaining('¥35.00'), findsOneWidget);
  });

  testWidgets('system recognition unavailable leaves text input usable', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async =>
            throw PlatformException(code: 'UNAVAILABLE', message: '系统语音不可用'));
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: LocalQuickEntryPage()),
    ));
    await tester.tap(find.text('中文语音输入'));
    await tester.pump();
    expect(find.text('系统语音不可用'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
