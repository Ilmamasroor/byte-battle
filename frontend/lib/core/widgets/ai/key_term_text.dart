import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

/// Text with the important words picked out: code-ish words in `backticks`, numbers, and any of [terms]
/// (case-insensitive) become highlighted chips-in-text. This is what turns a paragraph from the AI into
/// something the eye can scan.
class KeyTermText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final List<String> terms;
  final Color highlight;

  const KeyTermText({
    super.key,
    required this.text,
    required this.style,
    this.terms = const [],
    this.highlight = AppColors.primaryLight,
  });

  static const _defaultTerms = [
    'race condition', 'data race', 'thread', 'threads', 'synchronized', 'synchronization', 'lock', 'deadlock',
    'shared', 'atomic', 'volatile', 'mutex', 'class', 'object', 'method', 'variable', 'loop', 'array', 'interface',
    'inheritance', 'polymorphism', 'lost update', 'critical section',
  ];

  @override
  Widget build(BuildContext context) {
    final all = {..._defaultTerms, ...terms.map((t) => t.toLowerCase())}.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final pattern = RegExp(
      '`[^`]+`|\\b(?:${all.map(RegExp.escape).join('|')})\\b|\\b\\d+\\b',
      caseSensitive: false,
    );
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > cursor) spans.add(TextSpan(text: text.substring(cursor, m.start)));
      var word = m.group(0)!;
      final isCode = word.startsWith('`');
      if (isCode) word = word.substring(1, word.length - 1);
      spans.add(TextSpan(
        text: word,
        style: TextStyle(
          color: highlight,
          fontWeight: FontWeight.w800,
          fontFamily: isCode ? 'JetBrainsMono' : null,
          backgroundColor: isCode ? AppColors.surfaceRaised : null,
        ),
      ));
      cursor = m.end;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
    return RichText(text: TextSpan(style: style, children: spans));
  }
}
