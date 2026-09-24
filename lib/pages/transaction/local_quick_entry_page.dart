import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../ai/core/bill_info.dart';
import '../../providers.dart';
import '../../services/billing/bill_creation_service.dart';
import '../../services/billing/local_bill_draft_parser.dart';

/// Offline text entry: no transaction is written until each draft is confirmed.
class LocalQuickEntryPage extends ConsumerStatefulWidget {
  const LocalQuickEntryPage({super.key});

  @override
  ConsumerState<LocalQuickEntryPage> createState() => _LocalQuickEntryPageState();
}

class _DraftEdit {
  _DraftEdit(LocalBillDraft draft)
      : source = draft.source,
        amount = draft.amountMinor == null ? '' :
            (draft.amountMinor! / 100).toStringAsFixed(2),
        time = draft.time,
        note = draft.note,
        type = draft.type,
        warning = draft.issue;
  final String source;
  String amount;
  DateTime? time;
  String note;
  String type;
  String? warning;
  bool saving = false;
}

class _LocalQuickEntryPageState extends ConsumerState<LocalQuickEntryPage> {
  static const _speech = MethodChannel('com.tntlikely.beecount/system_speech');
  final _text = TextEditingController();
  final _drafts = <_DraftEdit>[];
  bool _recognizing = false;

  Future<void> _recognizeSpeech() async {
    if (_recognizing) return;
    setState(() => _recognizing = true);
    try {
      final transcript = await _speech.invokeMethod<String>('recognizeChinese');
      if (!mounted) return;
      if (transcript == null || transcript.trim().isEmpty) {
        throw PlatformException(code: 'EMPTY_RESULT', message: '没有识别到内容，请使用文字输入');
      }
      _text.text = [_text.text.trim(), transcript.trim()]
          .where((part) => part.isNotEmpty).join('、');
      _text.selection = TextSelection.collapsed(offset: _text.text.length);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('语音已转为文字，请生成草稿并逐笔核对'),
      ));
    } on PlatformException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message ?? '系统语音识别不可用，请使用文字输入'),
      ));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('语音识别不可用，请使用文字输入'),
      ));
    } finally {
      if (mounted) setState(() => _recognizing = false);
    }
  }

  @override
  void dispose() { _text.dispose(); super.dispose(); }

  Future<void> _edit(_DraftEdit draft) async {
    final amount = TextEditingController(text: draft.amount);
    final note = TextEditingController(text: draft.note);
    var time = draft.time;
    var type = draft.type;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, update) => AlertDialog(
        title: const Text('核对账单'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(draft.source),
          TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '金额（元）')),
          TextField(controller: note, decoration: const InputDecoration(labelText: '备注 / 用途')),
          DropdownButton<String>(value: type, isExpanded: true, items: const [
            DropdownMenuItem(value: 'expense', child: Text('支出')),
            DropdownMenuItem(value: 'income', child: Text('收入')),
            DropdownMenuItem(value: 'transfer', child: Text('转账（请用传统表单）')),
          ], onChanged: (value) => update(() => type = value!)),
          TextButton(onPressed: () async {
            final selected = await showDatePicker(context: context,
                initialDate: time ?? DateTime.now(), firstDate: DateTime(2000),
                lastDate: DateTime.now());
            if (selected != null) update(() => time = selected);
          }, child: Text(time == null ? '选择发生日期' :
              '${time!.year}-${time!.month}-${time!.day}')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('确认草稿')),
        ],
      )),
    );
    if (accepted == true && mounted) {
      setState(() {
        draft.amount = amount.text;
        draft.note = note.text.trim();
        draft.time = time;
        draft.type = type;
        draft.warning = null;
      });
    }
    amount.dispose(); note.dispose();
  }

  Future<void> _save(_DraftEdit draft) async {
    final cents = LocalBillDraftParser.parseMinor(draft.amount);
    if (cents == null || cents <= 0 || draft.time == null || draft.type == 'transfer' ||
        draft.warning != null) {
      setState(() => draft.warning = '请核对金额、日期与交易类型；转账请用传统表单');
      return;
    }
    setState(() => draft.saving = true);
    try {
      final id = await BillCreationService(ref.read(repositoryProvider)).createFromBill(
        bill: BillInfo(amount: cents / 100, time: draft.time, note: draft.note,
            type: draft.type == 'income' ? BillType.income : BillType.expense,
            currency: 'CNY'),
        ledgerId: ref.read(currentLedgerIdProvider),
      );
      if (!mounted) return;
      if (id == null) throw StateError('账单未保存');
      setState(() => _drafts.remove(draft));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已保存 1 笔（编号 $id）')));
    } catch (_) {
      if (mounted) setState(() => draft.warning = '保存失败，草稿已保留，请重试');
    } finally {
      if (mounted) setState(() => draft.saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('文字记账 · 本地解析')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      TextField(controller: _text, maxLines: 3,
          decoration: const InputDecoration(hintText: '今天午饭35、打车18块5、昨天水果26',
              labelText: '描述消费或收入')),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: _recognizing ? null : _recognizeSpeech,
        icon: const Icon(Icons.mic_none),
        label: Text(_recognizing ? '等待系统语音识别…' : '中文语音输入')),
      FilledButton(onPressed: () => setState(() {
        _drafts..clear()..addAll(LocalBillDraftParser.parse(_text.text).map(_DraftEdit.new));
      }), child: const Text('生成待确认草稿')),
      const Text('逐笔核对后保存；不确定金额或日期不会自动入账。系统语音不可用时可直接输入文字。'),
      for (final draft in _drafts) Card(child: ListTile(
        title: Text('${draft.amount.isEmpty ? "金额待填" : "¥${draft.amount}"} · ${draft.note.isEmpty ? draft.source : draft.note}'),
        subtitle: Text(draft.warning ?? '${draft.type == 'income' ? '收入' : draft.type == 'transfer' ? '转账' : '支出'} · ${draft.time?.toLocal().toString().split(' ').first ?? '日期待选'}'),
        onTap: draft.saving ? null : () => _edit(draft),
        trailing: TextButton(onPressed: draft.saving ? null : () => _save(draft), child: const Text('保存')),
      )),
    ]),
  );
}
