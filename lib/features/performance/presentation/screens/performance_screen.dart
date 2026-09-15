import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/glow_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/presentation/state/auth_controller.dart';
import '../../data/models/performance_model.dart';
import '../state/diagnosis_summary_controller.dart';

class _StatRow {
  final String label;
  final String value;
  final IconData icon;
  const _StatRow(this.label, this.value, this.icon);
}

class _TrendSeries {
  final String label;
  final Color color;
  final List<double> values; // 0..100, one per day

  const _TrendSeries(this.label, this.color, this.values);
}

/// "Progress / Mastery" screen — the full analytics dashboard behind
/// the compact performance summaries elsewhere in the app: concept
/// counts, a 7/30/90-day performance trend chart, application/battle
/// rings, and per-skill performance rings, plus a "Coming Soon" CAI
/// Metric teaser. Matches the reference "Progress / Mastery" screen.
class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  @override
  void initState() {
    super.initState();
    Helpers.noApiYet(
      'PerformanceScreen',
      note: 'skill rings are now LIVE via POST /api/ai/diagnose/summary '
          '(DiagnosisSummaryController); concept counts, the 7/30/90-day '
          'trend chart and battle win/loss are still hardcoded — there is '
          'no backend endpoint for those yet',
    );
    _load();
  }

  /// `POST /api/ai/diagnose/summary`, via [DiagnosisSummaryController].
  ///
  /// The backend expects a list of the learner's past
  /// [DiagnosisActivityModel] attempts (accuracy, score, hints used,
  /// etc.) to aggregate into skill scores. This app doesn't have an
  /// activity-history store yet (no local DB / backend log of past
  /// attempts), so — same convention [CodingScreen] already uses for its
  /// `POST /api/ai/coding-feedback` call — we submit representative
  /// sample activity data and let the *real* AI endpoint compute the
  /// *real* aggregate scores from it. Swap [_sampleActivities] for real
  /// stored attempts once an activity-history feature exists.
  Future<void> _load({bool force = false}) async {
    final userId = AuthController.instance.currentUser?.id ?? '';
    await DiagnosisSummaryController.instance.summarizeActivities(
      activities: _sampleActivities(userId),
      force: force,
    );
    if (!mounted) return;
    setState(() {});
  }

  List<DiagnosisActivityModel> _sampleActivities(String userId) => [
        DiagnosisActivityModel(
          userId: userId,
          activityType: 'CODING',
          accuracy: 0.78,
          score: 78,
          attemptCount: 2,
          timeSpentSeconds: 420,
          hintsUsed: 1,
          testCasesPassed: 4,
          testCasesTotal: 5,
          success: true,
        ),
        DiagnosisActivityModel(
          userId: userId,
          activityType: 'DEBUGGING',
          accuracy: 0.71,
          score: 71,
          attemptCount: 3,
          timeSpentSeconds: 384,
          hintsUsed: 2,
          testCasesPassed: 3,
          testCasesTotal: 5,
          success: true,
        ),
        DiagnosisActivityModel(
          userId: userId,
          activityType: 'BATTLE',
          accuracy: 0.68,
          score: 68,
          attemptCount: 1,
          timeSpentSeconds: 150,
          hintsUsed: 0,
          testCasesPassed: 0,
          testCasesTotal: 0,
          success: true,
        ),
      ];

  /// Some backends return these diagnosis scores as `0..1`, others as
  /// `0..100`. Normalize defensively so the rings (which expect `0..1`)
  /// render correctly either way.
  double _asPercent(double value) {
    final v = value > 1 ? value / 100 : value;
    return v.clamp(0.0, 1.0);
  }

  // Still hardcoded — no backend endpoint yet for concept counts or the
  // historical trend chart (see PerformanceScreen's Helpers.noApiYet note
  // above).
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _series = [
    _TrendSeries('Overall', AppColors.accentCyan, [40, 52, 48, 42, 58, 72, 78]),
    _TrendSeries('Coding', AppColors.btnAccentPurple, [30, 42, 45, 38, 52, 66, 82]),
    _TrendSeries('Problem Solving', AppColors.btnGamificationPink, [15, 30, 25, 18, 35, 48, 75]),
  ];

  String _range = '7D';

  @override
  Widget build(BuildContext context) {
    final controller = DiagnosisSummaryController.instance;
    final summary = controller.summary;
    final isInitialLoad = controller.isLoading && summary == null;
    final hasFailedWithNoData = controller.errorMessage != null && summary == null;

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
            child: Center(child: _XpChip(xp: 840)),
          ),
        ],
      ),
      body: SafeArea(
        child: isInitialLoad
            ? const LoadingView(message: 'Crunching your performance data…')
            : hasFailedWithNoData
                ? ErrorView(
                    message: controller.errorMessage!,
                    onRetry: () => _load(force: true),
                  )
                : _buildContent(summary),
      ),
    );
  }

  Widget _buildContent(DiagnosisSummaryResultModel? summary) {
    // Live scores from POST /api/ai/diagnose/summary when available;
    // sensible fallback percentages (matching the old hardcoded values)
    // while a summary hasn't loaded yet (e.g. request still in flight on
    // first build, or it failed but we still have nothing to show).
    final application = summary != null ? _asPercent(summary.decisionMaking) : 0.72;
    final coding = summary != null ? _asPercent(summary.codingImplementation) : 0.76;
    final debugging = summary != null ? _asPercent(summary.boundaryConditions) : 0.71;
    final explanation = summary != null ? _asPercent(summary.conceptUnderstanding) : 0.74;

    return RefreshIndicator(
      onRefresh: () => _load(force: true),
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
                    child: const Icon(Icons.bar_chart_rounded, color: AppColors.white),
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
                children: const [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.menu_book_rounded,
                      label: 'Concepts Learned',
                      value: '24',
                      delta: '+5 this week',
                      progress: 0.6,
                      color: AppColors.accentCyan,
                    ),
                  ),
                  SizedBox(width: AppDimensions.spacingSm),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.donut_large_rounded,
                      label: 'In Progress',
                      value: '8',
                      delta: '+2 this week',
                      progress: 0.3,
                      color: AppColors.btnAccentPurple,
                    ),
                  ),
                  SizedBox(width: AppDimensions.spacingSm),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Mastered Concepts',
                      value: '16',
                      delta: '+3 this week',
                      progress: 0.75,
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
                    SizedBox(
                      height: 180,
                      child: _TrendChart(days: _days, series: _series),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    Row(
                      children: [
                        for (final s in _series) ...[
                          _LegendDot(color: s.color, label: s.label, value: s.values.last),
                          const SizedBox(width: AppDimensions.spacingLg),
                        ],
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
                      icon: Icons.smartphone_rounded,
                      title: 'Application Improvement',
                      subtitle: 'Build real-world skills, one step at a time.',
                      ringColor: AppColors.accentCyan,
                      percent: application,
                      rows: const [
                        _StatRow('Core Logic', '80%', Icons.code_rounded),
                        _StatRow('UI/UX', '65%', Icons.palette_outlined),
                        _StatRow('Integration', '70%', Icons.link_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: _RingCard(
                      icon: Icons.sports_martial_arts_rounded,
                      title: 'Battle Performance',
                      subtitle: 'Your battle stats at a glance.',
                      ringColor: AppColors.btnGamificationPink,
                      percent: 0.68,
                      percentLabel: 'Win Rate',
                      rows: const [
                        _StatRow('Total Battles', '42', Icons.emoji_events_outlined),
                        _StatRow('Won', '29', Icons.emoji_events_rounded),
                        _StatRow('Lost', '13', Icons.close_rounded),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MiniRingCard(
                      icon: Icons.code_rounded,
                      title: 'Coding Performance',
                      subtitle: 'Write better. Solve faster.',
                      color: AppColors.accentCyan,
                      percent: coding,
                      rows: const [
                        _StatRow('Avg. Score', '78/100', Icons.star_border_rounded),
                        _StatRow('Problems Solved', '48', Icons.check_rounded),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MiniRingCard(
                      icon: Icons.bug_report_outlined,
                      title: 'Debugging Performance',
                      subtitle: 'Find it. Fix it. Level up.',
                      color: AppColors.btnAccentPurple,
                      percent: debugging,
                      rows: const [
                        _StatRow('Avg. Fix Time', '6.4 min', Icons.timer_outlined),
                        _StatRow('Bugs Resolved', '37', Icons.check_rounded),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MiniRingCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Explanation Performance',
                      subtitle: 'Think. Explain. Teach.',
                      color: AppColors.success,
                      percent: explanation,
                      rows: const [
                        _StatRow('Clarity', '80%', Icons.star_border_rounded),
                        _StatRow('Structure', '68%', Icons.list_alt_rounded),
                      ],
                    ),
                  ),
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
                        color: AppColors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.psychology_alt_rounded, color: AppColors.white),
                    ),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('CAI Metric',
                                  style: AppTextStyles.bodyBold
                                      .copyWith(color: AppColors.white)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(AppDimensions.radiusPill),
                                ),
                                child: Text('Coming Soon',
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.white)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your AI Collaboration Index — how well you learn, '
                            'build and improve with Byte Battle AI.',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.white.withOpacity(0.85)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.white),
                  ],
                ),
              ),
            ],
          ),
      ),
    );
  }
}

class _XpChip extends StatelessWidget {
  final int xp;
  const _XpChip({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 14, color: AppColors.accentCyan),
          const SizedBox(width: 4),
          Text('$xp XP', style: AppTextStyles.caption),
        ],
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
                    color: o == selected ? AppColors.white : AppColors.textHint,
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
  final double value;

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
            Text('${value.round()}%', style: AppTextStyles.bodyBold),
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
      final path = Path();
      final fillPath = Path();
      for (var i = 0; i < s.values.length; i++) {
        final x = leftPad + stepX * i;
        final y = chartHeight - (chartHeight * (s.values[i] / 100)).clamp(0, chartHeight);
        if (i == 0) {
          path.moveTo(x, y);
          fillPath.moveTo(x, chartHeight);
          fillPath.lineTo(x, y);
        } else {
          path.lineTo(x, y);
          fillPath.lineTo(x, y);
        }
        if (i == s.values.length - 1) {
          fillPath.lineTo(x, chartHeight);
        }
      }
      fillPath.close();

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

      for (var i = 0; i < s.values.length; i++) {
        final x = leftPad + stepX * i;
        final y = chartHeight - (chartHeight * (s.values[i] / 100)).clamp(0, chartHeight);
        canvas.drawCircle(Offset(x, y), 3, Paint()..color = s.color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) => false;
}

class _RingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color ringColor;
  final double percent;
  final String? percentLabel;
  final List<_StatRow> rows;

  const _RingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ringColor,
    required this.percent,
    required this.rows,
    this.percentLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      value: percent,
                      strokeWidth: 8,
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation(ringColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(percent * 100).round()}%', style: AppTextStyles.heading2),
                      if (percentLabel != null)
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
    );
  }
}

class _MiniRingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final double percent;
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
                    value: percent,
                    strokeWidth: 6,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Text('${(percent * 100).round()}%',
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
