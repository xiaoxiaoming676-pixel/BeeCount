/// Conservative, offline quick entry. It proposes drafts but never writes them.
/// Money is parsed as integer CNY cents; ambiguous clauses require review.
class LocalBillDraft {
  const LocalBillDraft({required this.source, this.amountMinor, this.time,
    this.note = '', this.type = 'expense', this.issue});

  final String source;
  final int? amountMinor;
  final DateTime? time;
  final String note;
  final String type;
  final String? issue;

  bool get canSave => amountMinor != null && amountMinor! > 0 &&
      time != null && issue == null && type != 'transfer';
}

class LocalBillDraftParser {
  static final _money = RegExp(
    r'(?:[¥￥]\s*)?([0-9]{1,3}(?:[,，][0-9]{3})+(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?|[零〇一二两三四五六七八九十百千万]+)(?:\s*(?:块钱|块|元)([0-9一二两三四五六七八九])?)?');

  static int? parseMinor(String input) {
    final formatted = input.trim().replaceAll(RegExp(r'[¥￥元\s]'), '');
    // A mistyped separator such as 1,2 must not silently become 12 yuan.
    if (formatted.contains(RegExp(r'[,，]')) &&
        !RegExp(r'^\d{1,3}(?:[,，]\d{3})+(?:\.\d{1,2})?$').hasMatch(formatted)) {
      return null;
    }
    final raw = formatted.replaceAll(RegExp(r'[,，]'), '');
    if (raw.isEmpty || raw.startsWith('-')) return null;
    final parts = raw.split('.');
    if (parts.length > 2 || (parts.length == 2 && parts[1].length > 2)) return null;
    if (RegExp(r'^\d+$').hasMatch(parts[0])) {
      final whole = int.tryParse(parts[0]);
      if (whole == null || whole > 1000000000) return null;
      final cents = parts.length == 1 ? 0 : int.tryParse(parts[1].padRight(2, '0'));
      return cents == null ? null : whole * 100 + cents;
    }
    if (parts.length != 1) return null;
    final units = {'十': 10, '百': 100, '千': 1000, '万': 10000};
    final digits = {'零': 0, '〇': 0, '一': 1, '二': 2, '两': 2,
      '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9};
    var total = 0, section = 0, digit = 0, previousUnit = 1;
    var hasUnit = false, zeroAfterUnit = false;
    for (final char in raw.split('')) {
      if (digits.containsKey(char)) {
        digit = digits[char]!;
        if (digit == 0) zeroAfterUnit = true;
        continue;
      }
      final unit = units[char];
      if (unit == null) return null;
      hasUnit = true;
      if (unit == 10000) {
        section = (section + digit) * unit;
        total += section;
        section = 0;
      } else {
        section += (digit == 0 ? 1 : digit) * unit;
      }
      previousUnit = unit;
      zeroAfterUnit = false;
      digit = 0;
    }
    if (!hasUnit && raw.length > 1) return null;
    // 千二百 = 1200, 百二 = 120; explicit smaller unit has already been added.
    if (digit > 0 && previousUnit >= 100 && !zeroAfterUnit) {
      digit *= previousUnit ~/ 10;
    }
    return (total + section + digit) * 100;
  }

  static List<LocalBillDraft> parse(String text, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final clauses = text.split(RegExp(r'(?<=[。；;、，,])(?!(?:\d{3}(?:\D|$)))'));
    final result = <LocalBillDraft>[];
    DateTime? inheritedDate;
    for (final original in clauses) {
      final clause = original.trim().replaceAll(RegExp(r'^[，,。、；;\s]+|[，,。、；;\s]+$'), '');
      if (clause.isEmpty) continue;
      DateTime? date;
      if (clause.contains('昨天')) {
        date = DateTime(today.year, today.month, today.day - 1);
      } else if (clause.contains('今天')) {
        date = DateTime(today.year, today.month, today.day);
      } else if (clause.contains('前天')) {
        date = DateTime(today.year, today.month, today.day - 2);
      } else {
        date = inheritedDate;
      }
      final unclearDate = RegExp(r'上周|上个月|前几天|某天|大前天|明天|后天|\d+月\d+日').hasMatch(clause);
      if (date != null) inheritedDate = date;
      final matches = _money.allMatches(clause).toList();
      // Date tokens and multiple numeric fields are deliberately left for review.
      final match = matches.length == 1 ? matches.single : null;
      final yuan = match?.group(1) ?? '';
      var cents = parseMinor(yuan);
      final fractional = match?.group(2);
      if (fractional != null && cents != null) {
        final fraction = parseMinor(fractional);
        cents += (fraction ?? 0) ~/ 10;
      }
      final type = RegExp(r'转账|转给|提现|充值|还款').hasMatch(clause)
          ? 'transfer' : RegExp(r'收入|工资|收款|到账').hasMatch(clause)
              ? 'income' : 'expense';
      final note = match == null ? clause :
          (clause.substring(0, match.start) + clause.substring(match.end))
              .replaceAll(RegExp(r'今天|昨天|前天'), '').trim();
      final issue = unclearDate ? '日期不明确，请手动选择' :
          matches.length != 1 || cents == null || cents <= 0 ? '金额不明确，请手动核对' :
          date == null ? '日期未说明，请手动选择' :
          type == 'transfer' ? '转账需指定双方账户，请用传统表单' : null;
      result.add(LocalBillDraft(source: clause, amountMinor: cents, time: date,
          note: note, type: type, issue: issue));
    }
    return result;
  }
}
