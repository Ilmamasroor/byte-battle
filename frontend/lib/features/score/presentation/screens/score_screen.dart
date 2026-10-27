import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/network/backend_api.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../battle/presentation/state/battle_controller.dart';
import '../../../dashboard/presentation/state/dashboard_controller.dart';
import '../../../learning/data/learning_progress_service.dart';
import '../widgets/mastery_circle.dart';
import '../widgets/score_breakdown.dart';

/// "Battle Complete!" score summary screen, every number real: the finished battle's result (passed in as
/// [outcome]), the learner's XP / level / streak (`GET /api/gamification/me`) and the four skill bars derived
/// from their stored performance records (`GET /api/performance`). A skill with no evidence yet says so instead
/// of showing a made-up number.
///
/// Reached after a battle (pushed from [BattleResultScreen]); without an [outcome] it simply shows the
/// learner's overall standing.
class ScoreScreen extends StatefulWidget {
  final BattleOutcome? outcome;

  const ScoreScreen({super.key, this.outcome});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  GamificationStats? _stats;
  Map<String, double?> _skills = const {};
  LearningProgressModel? _progress;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = BackendApi.instance;
      final stats = await api.gamification();
      final records = await api.performanceRecords();
      final outcome = widget.outcome;
      final progress = outcome == null ? null : await LearningProgressService.current(outcome.conceptId);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _skills = DashboardController.skillsFromRecords(records);
        _progress = progress;
        _loading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your score. Please try again.';
        _loading = false;
      });
    }
  }

  final int _navIndex = 2;

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(RouteNames.dashboard);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(RouteNames.conceptList);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(RouteNames.coding);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(RouteNames.profile);
        break;
      default:
        break;
    }
  }

  /// The mastery circle: this battle's accuracy, or the average of the skills that have evidence.
  int? get _mastery {
    final o = widget.outcome;
    if (o != null) return o.accuracy;
    final values = _skills.values.whereType<double>().toList();
    if (values.isEmpty) return null;
    return (values.reduce((a, b) => a + b) / values.length).round().clamp(0, 100);
  }

  Color _color(double v) => v >= 75 ? AppColors.success : (v >= 50 ? AppColors.primary : AppColors.warning);

  /// Which stage the learner is on now, e.g. "Next up: CODE" (the server advances it when a battle is won).
  String? get _nextStep {
    final p = _progress;
    if (p == null || widget.outcome?.result.won != true) return null;
    return p.completed ? 'Concept completed!' : 'Next up: ${p.currentStage}';
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.outcome;
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: AppBottomNav(currentIndex: _navIndex, onTap: _onNavTap),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(o == null ? 'Your Score' : (o.result.won ? 'Battle Complete!' : 'Battle Over'),
            style: AppTextStyles.bodyBold),
      ),
      body: _loading
          ? const LoadingView(message: 'Tallying your score...')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final o = widget.outcome;
    final stats = _stats!;
    final mastery = _mastery;
    final shown = _skills.entries.where((e) => e.value != null).toList();
    final missing = _skills.entries.where((e) => e.value == null).map((e) => e.key).toList();
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (mastery != null) MasteryCircle(score: mastery),
                      if (mastery != null) const SizedBox(width: AppDimensions.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o != null ? 'Battle Accuracy' : 'Mastery Score', style: AppTextStyles.bodyBold),
                            const SizedBox(height: AppDimensions.spacingXs),
                            if (o != null)
                              Text('${o.result.finalScore} points  •  ${o.result.correctAnswers}/${o.result.totalQuestions} correct',
                                  style: AppTextStyles.caption)
                            else if (mastery == null)
                              const Text('Finish a battle to earn your first score.', style: AppTextStyles.caption),
                            if (_nextStep != null) ...[
                              const SizedBox(height: AppDimensions.spacingXs),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(_nextStep!,
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingMd),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat(label: 'XP', value: '${stats.xp}'),
                        _Stat(label: 'LEVEL', value: '${stats.level}'),
                        _Stat(label: 'STREAK', value: '${stats.streakDays}d'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  for (final e in shown)
                    ScoreBreakdown(
                      label: e.key,
                      value: e.value!.round().clamp(0, 100),
                      color: _color(e.value!),
                    ),
                  if (missing.isNotEmpty)
                    Text('No evidence yet: ${missing.join(', ')}', style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          if (o != null && o.result.won)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
              child: AppButton(
                label: 'BACK TO JOURNEY',
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  RouteNames.learningJourney,
                  (r) => r.settings.name == RouteNames.dashboard || r.isFirst,
                  arguments: {'conceptId': o.conceptId},
                ),
              ),
            ),
          AppButton(
            label: 'VIEW PERFORMANCE',
            outlined: o != null && o.result.won,
            onPressed: () => Navigator.of(context).pushNamed(RouteNames.performance),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(value, style: AppTextStyles.heading2),
      ],
    );
  }
}
