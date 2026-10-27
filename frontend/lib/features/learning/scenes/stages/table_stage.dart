import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import 'stage_common.dart';

/// SQL / data stage: the query with the clause being explained lit, the source tables with the rows in play
/// highlighted, and the result table building up underneath.
class TableStage extends StatelessWidget {
  final Map<String, dynamic> s;
  const TableStage({super.key, required this.s});

  static const _keywords = [
    'SELECT',
    'FROM',
    'LEFT JOIN',
    'INNER JOIN',
    'JOIN',
    'ON',
    'WHERE',
    'GROUP BY',
    'HAVING',
    'ORDER BY',
    'LIMIT',
    'CREATE INDEX',
    'BEGIN',
    'COMMIT',
    'UPDATE',
    'SET',
    'INSERT'
  ];

  @override
  Widget build(BuildContext context) {
    final q = asMap(s['query']);
    final tables = asList(s['tables']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (str(q['text']).isNotEmpty) ...[_query(str(q['text']), str(q['focus'])), const SizedBox(height: 10)],
        for (final t in tables) ...[_table(asMap(t), AppColors.accentCyan), const SizedBox(height: 10)],
        if (s['result'] is Map) _table({...asMap(s['result']), 'name': 'Result'}, AppColors.success),
      ],
    );
  }

  Widget _query(String text, String focus) {
    final re = RegExp('(${_keywords.map(RegExp.escape).join('|')})', caseSensitive: false);
    final parts = <(String, String)>[]; // (keyword, clause text)
    var last = 0;
    String kw = '';
    for (final m in re.allMatches(text)) {
      if (m.start > last) parts.add((kw, text.substring(last, m.start)));
      kw = m.group(0)!.toUpperCase();
      last = m.start;
    }
    parts.add((kw, text.substring(last)));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Wrap(children: [
        for (final p in parts)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.only(right: 4, bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
                color: focus.isNotEmpty && p.$1 == focus.toUpperCase() ? AppColors.primary.withOpacity(0.25) : Colors.transparent, borderRadius: BorderRadius.circular(6)),
            child: Text(p.$2.trim(),
                style: AppTextStyles.code.copyWith(
                    fontSize: 12.5,
                    color: focus.isNotEmpty && p.$1 == focus.toUpperCase() ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: focus.isNotEmpty && p.$1 == focus.toUpperCase() ? FontWeight.w800 : FontWeight.w400)),
          ),
      ]),
    );
  }

  Widget _table(Map<String, dynamic> t, Color color) {
    final cols = asList(t['cols']).map(str).toList();
    final rows = asList(t['rows']);
    final hl = asList(t['hl']).whereType<num>().map((e) => e.toInt()).toSet();
    final dim = asList(t['dim']).whereType<num>().map((e) => e.toInt()).toSet();
    final hlCols = asList(t['hlCols']).whereType<num>().map((e) => e.toInt()).toSet();
    return StageCard(
      title: str(t['name']),
      icon: Icons.table_chart_rounded,
      color: color,
      lit: hl.isNotEmpty,
      child: Column(children: [
        Row(children: [
          for (var c = 0; c < cols.length; c++)
            Expanded(
                child: Text(cols[c],
                    style: AppTextStyles.code.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: hlCols.contains(c) ? AppColors.primary : AppColors.textHint)))
        ]),
        const Divider(height: 10, color: AppColors.border),
        if (rows.isEmpty) Padding(padding: const EdgeInsets.all(6), child: Text('no rows', style: AppTextStyles.caption)),
        for (var i = 0; i < rows.length; i++)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: dim.contains(i) ? 0.35 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(color: hl.contains(i) ? color.withOpacity(0.2) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                for (var c = 0; c < asList(rows[i]).length; c++)
                  Expanded(
                      child: Text(str(asList(rows[i])[c]),
                          style: AppTextStyles.code.copyWith(
                              fontSize: 11.5,
                              color: hl.contains(i) ? AppColors.textPrimary : AppColors.textSecondary,
                              fontWeight: hl.contains(i) && hlCols.contains(c) ? FontWeight.w800 : FontWeight.w400))),
              ]),
            ),
          ),
      ]),
    );
  }
}
