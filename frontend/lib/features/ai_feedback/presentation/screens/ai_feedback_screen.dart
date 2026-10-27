import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../performance/data/performance_analytics.dart';
import '../../../performance/presentation/state/performance_controller.dart';
import '../../../performance/presentation/widgets/xp_chip.dart';

class _PerfRow {
  final String label;
  final String caption;
  final IconData icon;
  final Color color;
  final int? scoreOf10; // null = no evidence for this skill yet

  const _PerfRow(this.label, this.caption, this.icon, this.color, this.scoreOf10);
}

/// "Performance Diagnosis": the four skills computed from the learner's stored evidence (`GET /api/performance`)
/// and a "Detected pattern" built from the AI diagnosis (`POST /api/ai/diagnose/summary`) and the repeated
/// mistakes in the learner's Byte DNA (`GET /api/byte-dna`).
class AiFeedbackScreen extends StatefulWidget {
  const AiFeedbackScreen({super.key});

  @override
  State<AiFeedbackScreen> createState() => _AiFeedbackScreenState();
}

class _AiFeedbackScreenState extends State<AiFeedbackScreen> {
  final _controller = PerformanceController.instance;

  static const _captions = {
    'Understanding': ('Grasp concepts and logic', Icons.lightbulb_outline_rounded, AppColors.accentCyan),
    'Application': ('Use knowledge in real scenarios', Icons.code_rounded, AppColors.btnAccentPurple),
    'Debugging': ('Find and fix issues efficiently', Icons.bug_report_rounded, AppColors.btnGamificationPink),
    'Communication': ('Explain and collaborate effectively', Icons.chat_bubble_outline_rounded, AppColors.accentCyan),
  };

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _load();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    await _controller.load(force: true);
    if (!mounted || _controller.errorMessage != null) return;
    // the pattern card has its own loading state; these run in the background
    _controller.diagnose();
    _controller.loadByteDna(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final skills = PerformanceAnalytics.skills(c.records);
    final rows = [
      for (final name in PerformanceAnalytics.skillNames)
        _PerfRow(name, _captions[name]!.$1, _captions[name]!.$2, _captions[name]!.$3,
            skills[name] == null ? null : (skills[name]! * 10).round()),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('BYTE BATTLE', style: AppTextStyles.heading2),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppDimensions.spacingMd),
            child: Center(child: LiveXpChip()),
          ),
        ],
      ),
      body: SafeArea(
        child: c.isLoading && !c.loaded
            ? const LoadingView(message: 'Reading your results…')
            : c.errorMessage != null && !c.loaded
                ? ErrorView(message: c.errorMessage!, onRetry: _load)
                : c.records.isEmpty
                    ? EmptyEvidence(
                        title: 'No activity yet',
                        message: 'Finish a battle, coding challenge, debugging exercise or interview and '
                            'your diagnosis will appear here.',
                        actionLabel: 'Choose a concept',
                        onAction: () => Navigator.of(context).pushNamed(RouteNames.conceptList),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppDimensions.screenPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _header(),
                              const SizedBox(height: AppDimensions.spacingXl),
                              Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.spacingSm),
                                  Text('Your performance', style: AppTextStyles.heading2),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.spacingMd),
                              for (final row in rows)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
                                  child: _PerfCard(row: row),
                                ),
                              _pattern(),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }

  Widget _header() => Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Icon(Icons.track_changes_rounded, color: AppColors.onAccent),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Performance Diagnosis', style: AppTextStyles.heading1),
                Text(
                  "See where you're strong, find what to improve. Let's build a better you.",
                  style: AppTextStyles.body.copyWith(color: AppColors.primaryLight),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _pattern() {
    final c = _controller;
    if (c.isDiagnosing || (c.diagnosis == null && c.diagnosisError == null)) {
      return const Padding(
        padding: EdgeInsets.all(AppDimensions.spacingLg),
        child: LoadingView(message: 'The AI is analysing your pattern…'),
      );
    }
    final insight = c.diagnosis == null ? null : DiagnosisInsight.from(c.diagnosis!);
    if (insight == null) {
      return _DetectedPatternCard(
        headline: c.diagnosisError != null
            ? 'The AI diagnosis is unavailable right now. Pull down to try again.'
            : 'There is not enough evidence yet for the AI to find a pattern.',
        issueLabel: 'Next step:',
        issue: 'Complete more activities.',
      );
    }
    final mistakes = c.byteDna?.repeatedMistakes ?? const <String>[];
    return _DetectedPatternCard(
      headline: 'Your strongest area is ${insight.strongest.toLowerCase()}, '
          'while ${insight.weakest.toLowerCase()} needs the most work.',
      issueLabel: mistakes.isEmpty ? 'Focus on:' : 'Recurring issue:',
      issue: mistakes.isEmpty ? insight.weakestAdvice : mistakes.take(3).join('\n'),
    );
  }
}

class _PerfCard extends StatelessWidget {
  final _PerfRow row;
  const _PerfCard({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: row.color.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: row.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(row.icon, color: row.color, size: 18),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.label, style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
                    Text(row.caption, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Text(row.scoreOf10 == null ? 'No data' : '${row.scoreOf10! * 10}%',
                  style: AppTextStyles.heading2.copyWith(color: row.color)),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              Expanded(child: _SegmentedBar(filled: row.scoreOf10 ?? 0, color: row.color)),
              const SizedBox(width: AppDimensions.spacingSm),
              Text(row.scoreOf10 == null ? 'Not practised yet' : '${row.scoreOf10} / 10', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  final int filled;
  final Color color;
  static const int total = 10;

  const _SegmentedBar({required this.filled, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isOn = i < filled;
        return Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 3),
            decoration: BoxDecoration(
              color: isOn ? color : AppColors.background,
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            ),
          ),
        );
      }),
    );
  }
}

class _DetectedPatternCard extends StatelessWidget {
  final String headline;
  final String issueLabel;
  final String issue;
  const _DetectedPatternCard({required this.headline, required this.issueLabel, required this.issue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.btnAccentPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(Icons.psychology_alt_rounded,
                    color: AppColors.btnAccentPurple, size: 18),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Text('Detected Pattern',
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  border: Border.all(color: AppColors.accentCyan.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.accentCyan),
                    const SizedBox(width: 4),
                    Text('Personalized insight',
                        style: AppTextStyles.caption.copyWith(color: AppColors.accentCyan)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(headline, style: AppTextStyles.body),
          const SizedBox(height: AppDimensions.spacingMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.btnGamificationPink, size: 16),
                    const SizedBox(width: 6),
                    Text(issueLabel,
                        style: AppTextStyles.bodyBold
                            .copyWith(color: AppColors.btnGamificationPink, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Expanded(child: Text(issue, style: AppTextStyles.body)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
