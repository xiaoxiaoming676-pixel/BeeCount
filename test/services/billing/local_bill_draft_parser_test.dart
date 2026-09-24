import 'package:flutter_test/flutter_test.dart';
import 'package:beecount/services/billing/local_bill_draft_parser.dart';

void main() {
  test('three editable drafts with date inheritance and cents', () {
    final drafts = LocalBillDraftParser.parse(
      '今天午饭35、打车18块5、昨天水果26', now: DateTime(2026, 9, 24, 18),
    );
    expect(drafts, hasLength(3));
    expect(drafts.map((d) => d.amountMinor), [3500, 1850, 2600]);
    expect(drafts.map((d) => d.time), [DateTime(2026, 9, 24),
      DateTime(2026, 9, 24), DateTime(2026, 9, 23)]);
    expect(drafts.every((d) => d.canSave), isTrue);
  });

  test('precise money and shorthand numerals', () {
    expect(LocalBillDraftParser.parseMinor('¥1,200.00'), 120000);
    expect(LocalBillDraftParser.parseMinor('千二百'), 120000);
    expect(LocalBillDraftParser.parseMinor('一百零二'), 10200);
    expect(LocalBillDraftParser.parseMinor('18.5'), 1850);
    expect(LocalBillDraftParser.parseMinor('18.555'), isNull);
    expect(LocalBillDraftParser.parseMinor('1,2'), isNull);
  });

  test('uncertain dates and transfers cannot silently save', () {
    final drafts = LocalBillDraftParser.parse('上个月交了80、转账100、今天买了东西',
        now: DateTime(2026, 9, 24));
    expect(drafts, hasLength(3));
    expect(drafts.every((d) => !d.canSave), isTrue);
    expect(drafts[1].type, 'transfer');
    expect(drafts[2].amountMinor, isNull);
  });

  test('multiple amounts in one clause are rejected for manual review', () {
    final draft = LocalBillDraftParser.parse('今天午饭35和打车18',
        now: DateTime(2026, 9, 24)).single;
    expect(draft.canSave, isFalse);
  });
}
