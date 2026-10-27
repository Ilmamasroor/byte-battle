import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/glow_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../data/performance_analytics.dart';
import '../state/performance_controller.dart';
import '../widgets/xp_chip.dart';

class _StatRow {
  final String label;
  final String value;
  final IconData icon;
  const _StatRow(this.label, this.value, this.icon);
}

class _TrendSeries {
  final String label;
  final Color color;
  final List<double?> values; // 0..100, null = no activity in that bucket

  const _TrendSeries(this.label, this.color, this.values);
}

/// "Progress / Mastery" screen: every number comes from the learner's stored evidence
/// (`GET /api/performance`, `/api/performance/summary`, `/api/learning`) and the AI diagnosis
/// (`POST /api/ai/diagnose/summary`) computed from those same records. Skills without evidence show "No data".
class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final _controller = PerformanceController.instance;
  String _range = '7D';

  static const _rangeDays = {'7D': 7, '30D': 30, '90D': 90};

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
    await _controller.diagnose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final isInitialLoad = c.isLoading && !c.loaded;
    final hasFailedWithNoData = c.errorMessage != null && !c.loaded;

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
        child: isInitialLoad
            ? const LoadingView(message: 'Crunching your performance data…')
            : hasFailedWithNoData
                ? ErrorView(message: c.errorMessage!, onRetry: _load)
                : c.records.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _load,
                        child: LayoutBuilder(
                          builder: (context, box) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: box.maxHeight,
                              child: EmptyEvidence(
                                title: 'No activity yet',
                                message: 'Finish a battle, a coding challenge, a debugging exercise or an interview '
                                    'and your progress will show up here.',
                                actionLabel: 'Choose a concept',
                                onAction: () => Navigator.of(context).pushNamed(RouteNames.conceptList),
                              ),
                            ),
                          ),
                        ),
                      )
                    : _buildContent(),
      ),
    );
  }

  String _percent(double? ratio) => ratio == null ? 'No data' : '${(ratio * 100).round()}%';

  Widget _buildContent() {
    final c = _controller;
    final records = c.records;
    final now = DateTime.now();
    final days = _rangeDays[_range]!;
    final labels = PerformanceAnalytics.trendLabels(days, now);
    final series = [
      _TrendSeries('Overall', AppColors.accentCyan, PerformanceAnalytics.trend(records, days, now).values),
      _TrendSeries('Coding', AppColors.btnAccentPurple,
          PerformanceAnalytics.trend(records, days, now, type: PerformanceAnalytics.coding).values),
      _TrendSeries('Debugging', AppColors.btnGamificationPink,
          PerformanceAnalytics.trend(records, days, now, type: PerformanceAnalytics.debugging).values),
    ];

    final battle = PerformanceAnalytics.stats(records, PerformanceAnalytics.battle);
    final coding = PerformanceAnalytics.stats(records, PerformanceAnalytics.coding);
    final debugging = PerformanceAnalytics.stats(records, PerformanceAnalytics.debugging);
    final interview = PerformanceAnalytics.stats(records, PerformanceAnalytics.interview);

    final started = c.progress.length;
    final mastered = c.progress.where((p) => p.completed).length;
    final inProgress = started - mastered;
    final thisWeek = PerformanceAnalytics.inLastDays(records, 7, now);

    final diagnosis = c.diagnosis;
    final dims = <_StatRow>[
      if (diagnosis?.conceptUnderstanding != null)
        _StatRow('Concepts', '${diagnosis!.conceptUnderstanding!.round()}%', Icons.lightbulb_outline_rounded),
      if (diagnosis?.decisionMaking != null)
        _StatRow('Decisions', '${diagnosis!.decisionMaking!.round()}%', Icons.alt_route_rounded),
      if (diagnosis?.boundaryConditions != null)
        _StatRow('Edge cases', '${diagnosis!.boundaryConditions!.round()}%', Icons.rule_rounded),
      if (diagnosis?.codingImplementation != null)
        _StatRow('Coding', '${diagnosis!.codingImplementation!.round()}%', Icons.code_rounded),
      if (diagnosis?.hintDependency != null)
        _StatRow('Hint reliance', '${diagnosis!.hintDependency!.round()}%', Icons.help_outline_rounded),
    ];
    final known = [
      diagnosis?.conceptUnderstanding,
      diagnosis?.decisionMaking,
      diagnosis?.boundaryConditions,
      diagnosis?.codingImplementation,
      if (diagnosis?.hintDependency != null) 100 - diagnosis!.hintDependency!,
    ].whereType<double>().toList();
    final aiPercent = known.isEmpty ? null : (known.reduce((a, b) => a + b) / known.length / 100).clamp(0.0, 1.0);

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: AppColors.onAccent),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Progress / Mastery', style: AppTextStyles.heading1),
                        Text('Track your learning. Build your skills. Level up.',
                            style: AppTextStyles.body.copyWith(color: AppColors.primaryLight)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.menu_book_rounded,
                      label: 'Activities Done',
                      value: '${records.length}',
                      delta: '$thisWeek this week',
                      progress: records.isEmpty ? 0 : (thisWeek / records.length).clamp(0.0, 1.0),
                      color: AppColors.accentCyan,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.donut_large_rounded,
                      label: 'In Progress',
                      value: '$inProgress',
                      delta: 'of $started started',
                      progress: started == 0 ? 0 : inProgress / started,
                      color: AppColors.btnAccentPurple,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Mastered Concepts',
                      value: '$mastered',
                      delta: 'of $started started',
                      progress: started == 0 ? 0 : mastered / started,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              GlowCard(
                padding: const EdgeInsets.all(AppDimensions.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.show_chart_rounded,
                            color: AppColors.accentCyan, size: 18),
                        const SizedBox(width: AppDimensions.spacingSm),
                        Expanded(
                          child: Text('Performance Trends', style: AppTextStyles.bodyBold),
                        ),
                        _RangeToggle(
                          selected: _range,
                          onChanged: (r) => setState(() => _range = r),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    if (series.any((s) => TrendSeries(s.values).hasData))
                      SizedBox(
                        height: 180,
                        child: _TrendChart(days: labels, series: series),
                      )
                    else
                      SizedBox(
                        height: 90,
                        child: Center(
                          child: Text('No activity in the last $days days.', style: AppTextStyles.body),
                        ),
                      ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    Wrap(
                      spacing: AppDimensions.spacingLg,
                      runSpacing: AppDimensions.spacingSm,
                      children: [
                        for (final s in series)
                          _LegendDot(
                              color: s.color,
                              label: s.label,
                              value: TrendSeries(s.values).latest),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _RingCard(
                      icon: Icons.psychology_alt_rounded,
                      title: 'AI Diagnosis',
                      subtitle: 'Estimated from all your activity.',
                      ringColor: AppColors.accentCyan,
                      percent: aiPercent,
                      emptyLabel: c.isDiagnosing ? 'Analyzing…' : (c.diagnosisError != null ? 'Unavailable' : 'No data'),
                      rows: dims.isEmpty
                          ? [
                              _StatRow(c.diagnosisError != null ? 'Tap to retry' : 'Working on it',
                                  c.isDiagnosing ? '…' : '–', Icons.refresh_rounded)
                            ]
                          : dims.take(3).toList(),
                      onTap: c.diagnosisError != null ? () => c.diagnose(force: true) : null,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: _RingCard(
                      icon: Icons.sports_martial_arts_rounded,
                      title: 'Battle Performance',
                      subtitle: 'Your battle stats at a glance.',
                      ringColor: AppColors.btnGamificationPink,
                      percent: battle.successRate,
                      percentLabel: 'Win Rate',
                      rows: [
                        _StatRow('Total Battles', '${battle.total}', Icons.emoji_events_outlined),
                        _StatRow('Won', '${battle.successes}', Icons.emoji_events_rounded),
                        _StatRow('Lost', '${battle.failures}', Icons.close_rounded),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              _MiniRingCard(
                icon: Icons.code_rounded,
                title: 'Coding Performance',
                subtitle: 'Write better. Solve faster.',
                color: AppColors.accentCyan,
                percent: coding.averageAccuracy,
                rows: [
                  _StatRow('Avg. Score',
                      coding.averageScore == null ? '–' : '${coding.averageScore!.round()}/100', Icons.star_border_rounded),
                  _StatRow('Challenges Solved', '${coding.successes} / ${coding.total}', Icons.check_rounded),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              _MiniRingCard(
                icon: Icons.bug_report_outlined,
                title: 'Debugging Performance',
                subtitle: 'Find it. Fix it. Level up.',
                color: AppColors.btnAccentPurple,
                percent: debugging.averageAccuracy,
                rows: [
                  _StatRow(
                      'Avg. Fix Time',
                      debugging.averageSecondsOfSuccesses == null
                          ? '–'
                          : PerformanceAnalytics.clock(debugging.averageSecondsOfSuccesses!),
                      Icons.timer_outlined),
                  _StatRow('Bugs Resolved', '${debugging.successes} / ${debugging.total}', Icons.check_rounded),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              _MiniRingCard(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Explanation Performance',
                subtitle: 'Think. Explain. Teach.',
                color: AppColors.success,
                percent: interview.averageAccuracy,
                rows: [
                  _StatRow('Avg. Score',
                      interview.averageScore == null ? '–' : '${interview.averageScore!.round()}/100', Icons.star_border_rounded),
                  _StatRow('Interviews', '${interview.total}', Icons.list_alt_rounded),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spacingLg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.btnAccentPurple],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.onAccent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.psychology_alt_rounded, color: AppColors.onAccent),
                    ),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Overall success rate',
                              style: AppTextStyles.bodyBold.copyWith(color: AppColors.onAccent)),
                          const SizedBox(height: 2),
                          Text(
                            c.summary == null
                                ? 'Not available.'
                                : '${_percent(c.summary!.successRate)} of ${c.summary!.totalActivities} activities passed, '
                                    'average score ${c.summary!.averageScore.round()}/100.',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.onAccent.withOpacity(0.85)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String delta;
  final double progress;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.delta,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingSm + 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(label, style: AppTextStyles.caption, maxLines: 2),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.heading1.copyWith(fontSize: 22)),
          Text(delta, style: AppTextStyles.caption.copyWith(color: AppColors.success)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _RangeToggle({required this.selected, required this.onChanged});

  static const _options = ['7D', '30D', '90D'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in _options)
            InkWell(
              onTap: () => onChanged(o),
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: o == selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
                child: Text(
                  o,
                  style: AppTextStyles.caption.copyWith(
                    color: o == selected ? AppColors.onAccent : AppColors.textHint,
                    fontWeight: o == selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final double? value;

  const _LegendDot({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(value == null ? 'No data' : '${value!.round()}%', style: AppTextStyles.bodyBold),
          ],
        ),
      ],
    );
  }
}

/// Lightweight multi-series line chart, hand-painted with
/// [CustomPainter] so the app doesn't need a third-party charting
/// dependency just for this one screen.
class _TrendChart extends StatelessWidget {
  final List<String> days;
  final List<_TrendSeries> series;

  const _TrendChart({required this.days, required this.series});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrendChartPainter(days: days, series: series),
      size: Size.infinite,
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<String> days;
  final List<_TrendSeries> series;

  _TrendChartPainter({required this.days, required this.series});

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 28.0;
    const bottomPad = 20.0;
    final chartWidth = size.width - leftPad;
    final chartHeight = size.height - bottomPad;

    final gridPaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    final labelStyle = TextStyle(color: AppColors.textHint, fontSize: 10);

    for (var i = 0; i <= 4; i++) {
      final y = chartHeight - (chartHeight * i / 4);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: '${i * 25}', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    final stepX = days.length > 1 ? chartWidth / (days.length - 1) : 0.0;
    for (var i = 0; i < days.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: days[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = leftPad + stepX * i;
      tp.paint(canvas, Offset(x - tp.width / 2, chartHeight + 4));
    }

    for (final s in series) {
      // only buckets that have data are drawn; the line bridges empty buckets
      final points = <Offset>[
        for (var i = 0; i < s.values.length; i++)
          if (s.values[i] != null)
            Offset(leftPad + stepX * i,
                chartHeight - (chartHeight * (s.values[i]! / 100)).clamp(0, chartHeight).toDouble()),
      ];
      if (points.isEmpty) continue;

      if (points.length > 1) {
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        final fillPath = Path()
          ..moveTo(points.first.dx, chartHeight)
          ..lineTo(points.first.dx, points.first.dy);
        for (final pt in points.skip(1)) {
          path.lineTo(pt.dx, pt.dy);
          fillPath.lineTo(pt.dx, pt.dy);
        }
        fillPath
          ..lineTo(points.last.dx, chartHeight)
          ..close();

        canvas.drawPath(
          fillPath,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [s.color.withOpacity(0.18), s.color.withOpacity(0.0)],
            ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight)),
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = s.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      }
      for (final pt in points) {
        canvas.drawCircle(pt, 3, Paint()..color = s.color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) => true;
}

class _RingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color ringColor;
  final double? percent;
  final String? percentLabel;
  final String emptyLabel;
  final VoidCallback? onTap;
  final List<_StatRow> rows;

  const _RingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ringColor,
    required this.percent,
    required this.rows,
    this.percentLabel,
    this.emptyLabel = 'No data',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: ringColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ringColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(icon, size: 17, color: ringColor),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                        maxLines: 2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTextStyles.caption),
          const SizedBox(height: AppDimensions.spacingMd),
          Center(
            child: SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 88,
                    height: 88,
                    child: CircularProgressIndicator(
                      value: percent ?? 0,
                      strokeWidth: 8,
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation(ringColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(percent == null ? '–' : '${(percent! * 100).round()}%', style: AppTextStyles.heading2),
                      if (percent == null)
                        Text(emptyLabel, style: AppTextStyles.caption)
                      else if (percentLabel != null)
                        Text(percentLabel!, style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(r.icon, size: 13, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Expanded(child: Text(r.label, style: AppTextStyles.caption)),
                  Text(r.value, style: AppTextStyles.bodyBold.copyWith(fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    ),
    );
  }
}

class _MiniRingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final double? percent;
  final List<_StatRow> rows;

  const _MiniRingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.percent,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
            ],
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: percent ?? 0,
                    strokeWidth: 6,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Text(percent == null ? '–' : '${(percent! * 100).round()}%',
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(r.icon, size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(r.label, style: AppTextStyles.caption),
                      const SizedBox(width: 4),
                      Text(r.value, style: AppTextStyles.bodyBold.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
