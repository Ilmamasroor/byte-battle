import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/ai/companion_says.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/brand/bit_mascot.dart';
import '../../../../core/widgets/brand/confetti.dart';
import '../../../concepts/presentation/state/concept_controller.dart';
import '../../data/readiness_bank.dart';
import '../../data/readiness_store.dart';

enum _Step { intro, selfCheck, quiz, result }

enum _Claim { know, rusty, fresh }

enum _Level { solid, shaky, fresh }

/// "Toolkit check" before a journey: the learner first says what they already know (so we respect their time),
/// then proves a few of those claims with one quick question each, and finally gets a personal plan: what is
/// solid, what needs a refresher, and the refreshers themselves.
class ReadinessScreen extends StatefulWidget {
  final String conceptId;
  final String nextRoute;
  const ReadinessScreen({super.key, required this.conceptId, required this.nextRoute});

  @override
  State<ReadinessScreen> createState() => _ReadinessScreenState();
}

class _ReadinessScreenState extends State<ReadinessScreen> {
  final _concept = ConceptController();
  _Step _step = _Step.intro;
  List<Prereq> _items = const [];
  final Map<String, _Claim> _claims = {};
  final Map<String, int> _picked = {};
  List<Prereq> _quiz = const [];
  int _q = 0;
  int _confetti = 0;

  @override
  void initState() {
    super.initState();
    _concept.addListener(_conceptReady);
    _concept.load(widget.conceptId);
    _items = ReadinessBank.forConcept(null);
  }

  void _conceptReady() {
    if (!mounted) return;
    setState(() => _items = ReadinessBank.forConcept(_concept.concept?.name));
  }

  @override
  void dispose() {
    _concept.removeListener(_conceptReady);
    _concept.dispose();
    super.dispose();
  }

  String get _name => _concept.concept?.name ?? 'this concept';

  _Level _levelOf(Prereq p) {
    final c = _claims[p.id];
    if (c == _Claim.fresh || c == null) return _Level.fresh;
    final picked = _picked[p.id];
    final correct = picked == p.answer;
    if (c == _Claim.know && correct) return _Level.solid;
    return _Level.shaky;
  }

  void _toQuiz() {
    _quiz = _items.where((p) => _claims[p.id] != _Claim.fresh).toList();
    setState(() {
      _q = 0;
      _step = _quiz.isEmpty ? _Step.result : _Step.quiz;
    });
    if (_quiz.isEmpty) _finish();
  }

  Future<void> _finish() async {
    await ReadinessStore.markDone(widget.conceptId);
    if (!mounted) return;
    if (_items.every((p) => _levelOf(p) == _Level.solid)) setState(() => _confetti++);
  }

  void _go() {
    Navigator.of(context).pushReplacementNamed(widget.nextRoute, arguments: {'conceptId': widget.conceptId});
  }

  Future<void> _skip() async {
    await ReadinessStore.markDone(widget.conceptId);
    if (mounted) _go();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).maybePop()),
        title: const Text('Toolkit check', style: AppTextStyles.heading2),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: KeyedSubtree(key: ValueKey('$_step$_q'), child: _body()),
            ),
            Positioned.fill(child: ConfettiBurst(trigger: _confetti)),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case _Step.intro:
        return _intro();
      case _Step.selfCheck:
        return _selfCheck();
      case _Step.quiz:
        return _quizQuestion();
      case _Step.result:
        return _result();
    }
  }

  Widget _pad(List<Widget> children, {Widget? bottom}) => Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
            ),
          ),
          if (bottom != null) Padding(padding: const EdgeInsets.fromLTRB(AppDimensions.screenPadding, 0, AppDimensions.screenPadding, AppDimensions.screenPadding), child: bottom),
        ],
      );

  // ── 1 Intro ───────────────────────────────────────────────────────────
  Widget _intro() {
    return _pad(
      [
        const SizedBox(height: 12),
        Text('BEFORE WE START', style: AppTextStyles.eyebrow.copyWith(color: AppColors.primary)),
        const SizedBox(height: 8),
        Text('Pack your toolkit for $_name', style: AppTextStyles.display.copyWith(fontSize: 32)),
        const SizedBox(height: 18),
        CompanionSays(
          mood: BitMood.curious,
          text: 'No exam, I promise. $_name builds on a few basics. Tell me what you already know, I will check a couple of them, and we will skip what you have got.',
        ),
        const SizedBox(height: 18),
        for (final p in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Icon(p.icon, size: 20, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(p.title, style: AppTextStyles.bodyBold)),
            ]),
          ),
      ],
      bottom: Column(
        children: [
          AppButton(label: "Let's check", icon: Icons.arrow_forward_rounded, onPressed: () => setState(() => _step = _Step.selfCheck)),
          TextButton(onPressed: _skip, child: const Text('I already know all this, skip')),
        ],
      ),
    );
  }

  // ── 2 Self check ──────────────────────────────────────────────────────
  Widget _selfCheck() {
    final done = _items.every((p) => _claims.containsKey(p.id));
    return _pad(
      [
        Text('How well do you know these?', style: AppTextStyles.display.copyWith(fontSize: 26)),
        const SizedBox(height: 6),
        Text('Be honest, it only helps you. Nobody is graded.', style: AppTextStyles.body),
        const SizedBox(height: 16),
        for (final p in _items) _ClaimCard(prereq: p, value: _claims[p.id], onPick: (c) => setState(() => _claims[p.id] = c)),
      ],
      bottom: AppButton(label: 'Next', icon: Icons.arrow_forward_rounded, onPressed: done ? _toQuiz : null),
    );
  }

  // ── 3 Quiz ────────────────────────────────────────────────────────────
  Widget _quizQuestion() {
    final p = _quiz[_q];
    final picked = _picked[p.id];
    final answered = picked != null;
    final right = picked == p.answer;
    return _pad(
      [
        Row(
          children: [
            for (var i = 0; i < _quiz.length; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Expanded(child: Container(height: 5, decoration: BoxDecoration(color: i <= _q ? AppColors.primary : AppColors.surfaceRaised, borderRadius: BorderRadius.circular(100)))),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Text('QUICK PROOF  ·  ${p.title.toUpperCase()}', style: AppTextStyles.eyebrow),
        const SizedBox(height: 8),
        Text(p.question, style: AppTextStyles.display.copyWith(fontSize: 23, fontWeight: FontWeight.w500)),
        const SizedBox(height: 18),
        for (var i = 0; i < p.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Option(
              letter: String.fromCharCode(65 + i),
              text: p.options[i],
              state: !answered ? _OptState.idle : (i == p.answer ? _OptState.correct : (i == picked ? _OptState.wrong : _OptState.dim)),
              onTap: answered ? null : () => setState(() => _picked[p.id] = i),
            ),
          ),
        if (answered) ...[
          const SizedBox(height: 4),
          CompanionSays(
            mood: right ? BitMood.cheer : BitMood.curious,
            text: right ? 'Yes! ${p.why}' : 'Not quite, and that is useful to know. ${p.why}',
          ),
        ],
      ],
      bottom: AppButton(
        label: _q == _quiz.length - 1 ? 'See my toolkit' : 'Next question',
        icon: Icons.arrow_forward_rounded,
        onPressed: answered
            ? () {
                if (_q == _quiz.length - 1) {
                  setState(() => _step = _Step.result);
                  _finish();
                } else {
                  setState(() => _q++);
                }
              }
            : null,
      ),
    );
  }

  // ── 4 Result ──────────────────────────────────────────────────────────
  Widget _result() {
    final levels = {for (final p in _items) p.id: _levelOf(p)};
    final solid = levels.values.where((l) => l == _Level.solid).length;
    final gaps = _items.where((p) => levels[p.id] != _Level.solid).toList();
    final ready = gaps.isEmpty;
    return _pad(
      [
        Text(ready ? 'Toolkit complete' : 'Your toolkit', style: AppTextStyles.display.copyWith(fontSize: 32)),
        const SizedBox(height: 4),
        Text('$solid of ${_items.length} solid', style: AppTextStyles.bodyBold.copyWith(color: ready ? AppColors.success : AppColors.primaryLight)),
        const SizedBox(height: 16),
        CompanionSays(
          mood: ready ? BitMood.cheer : BitMood.happy,
          text: ready
              ? 'You are fully equipped for $_name. Let us go!'
              : 'Good start. ${gaps.length == 1 ? 'One thing needs' : '${gaps.length} things need'} a quick refresher first. They take a minute each, and they will make $_name much easier.',
        ),
        const SizedBox(height: 16),
        for (final p in _items) _ResultRow(prereq: p, level: levels[p.id]!),
        if (gaps.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('QUICK REFRESHERS', style: AppTextStyles.eyebrow.copyWith(color: AppColors.primary)),
          const SizedBox(height: 10),
          for (final p in gaps) _Primer(prereq: p),
        ],
      ],
      bottom: AppButton(label: ready ? 'Start learning' : 'I am ready, start learning', icon: Icons.arrow_forward_rounded, onPressed: _go),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  final Prereq prereq;
  final _Claim? value;
  final ValueChanged<_Claim> onPick;
  const _ClaimCard({required this.prereq, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    Widget chip(_Claim c, String label, Color color) {
      final sel = value == c;
      return Expanded(
        child: GestureDetector(
          onTap: () => onPick(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 10),
            margin: const EdgeInsets.only(right: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sel ? color : AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sel ? color : AppColors.border),
            ),
            child: Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800, color: sel ? AppColors.onAccent : AppColors.textSecondary)),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusLg), border: Border.all(color: value == null ? AppColors.border : AppColors.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(prereq.icon, color: AppColors.primaryLight, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(prereq.title, style: AppTextStyles.bodyBold),
                Text(prereq.subtitle, style: AppTextStyles.caption),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            chip(_Claim.know, 'I know it', AppColors.success),
            chip(_Claim.rusty, 'A bit rusty', AppColors.warning),
            chip(_Claim.fresh, 'New to me', AppColors.accentCyan),
          ]),
        ],
      ),
    );
  }
}

enum _OptState { idle, correct, wrong, dim }

class _Option extends StatelessWidget {
  final String letter;
  final String text;
  final _OptState state;
  final VoidCallback? onTap;
  const _Option({required this.letter, required this.text, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _OptState.correct => AppColors.success,
      _OptState.wrong => AppColors.error,
      _ => AppColors.border,
    };
    final highlighted = state == _OptState.correct || state == _OptState.wrong;
    return Opacity(
      opacity: state == _OptState.dim ? 0.5 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: highlighted ? color.withOpacity(0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: color, width: highlighted ? 1.6 : 1),
          ),
          child: Row(children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: highlighted ? color : AppColors.surfaceRaised, borderRadius: BorderRadius.circular(9)),
              child: highlighted
                  ? Icon(state == _OptState.correct ? Icons.check_rounded : Icons.close_rounded, size: 17, color: AppColors.onAccent)
                  : Text(letter, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary))),
          ]),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final Prereq prereq;
  final _Level level;
  const _ResultRow({required this.prereq, required this.level});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (level) {
      _Level.solid => ('Solid', AppColors.success, Icons.verified_rounded),
      _Level.shaky => ('Needs a refresher', AppColors.warning, Icons.autorenew_rounded),
      _Level.fresh => ('New, we will cover it', AppColors.accentCyan, Icons.auto_awesome_rounded),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusMd), border: Border.all(color: color.withOpacity(0.45))),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(prereq.title, style: AppTextStyles.bodyBold)),
        Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _Primer extends StatefulWidget {
  final Prereq prereq;
  const _Primer({required this.prereq});

  @override
  State<_Primer> createState() => _PrimerState();
}

class _PrimerState extends State<_Primer> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.prereq;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusLg), border: Border.all(color: _open ? AppColors.primary : AppColors.border)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(p.icon, color: AppColors.primaryLight),
                const SizedBox(width: 12),
                Expanded(child: Text(p.title, style: AppTextStyles.bodyBold)),
                AnimatedRotation(turns: _open ? 0.25 : 0, duration: const Duration(milliseconds: 160), child: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint)),
              ]),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.primer, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Text(p.example, style: AppTextStyles.code.copyWith(fontSize: 12.5, color: AppColors.accentCyan)),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}
