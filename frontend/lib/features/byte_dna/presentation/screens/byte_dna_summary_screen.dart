import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/glow_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../performance/data/performance_analytics.dart';
import '../../../performance/presentation/state/performance_controller.dart';
import '../../../performance/presentation/widgets/xp_chip.dart';

class _SkillRow {
  final String label;
  final double? value; // null = no evidence yet
  final IconData icon;
  final Color color;

  const _SkillRow(this.label, this.value, this.icon, this.color);
}

/// "Byte DNA": the learner's learning fingerprint. The four skill bars are averaged from their verified
/// performance records (`GET /api/performance`); the topic strengths, repeated mistakes and areas come from the
/// Byte DNA the backend evolves after every activity (`GET /api/byte-dna`). Nothing is shown that has no evidence.
class ByteDnaSummaryScreen extends StatefulWidget {
  const ByteDnaSummaryScreen({super.key});

  @override
  State<ByteDnaSummaryScreen> createState() => _ByteDnaSummaryScreenState();
}

class _ByteDnaSummaryScreenState extends State<ByteDnaSummaryScreen> {
  final _controller = PerformanceController.instance;

  static const _look = {
    'Understanding': (Icons.lightbulb_outline_rounded, AppColors.accentCyan),
    'Application': (Icons.code_rounded, AppColors.btnAccentPurple),
    'Debugging': (Icons.bug_report_outlined, AppColors.btnGamificationPink),
    'Communication': (Icons.chat_bubble_outline_rounded, AppColors.success),
  };
  static const _typeOfSkill = {
    'Understanding': PerformanceAnalytics.battle,
    'Application': PerformanceAnalytics.coding,
    'Debugging': PerformanceAnalytics.debugging,
    'Communication': PerformanceAnalytics.interview,
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
    await Future.wait([_controller.load(force: true), _controller.loadByteDna(force: true)]);
    if (mounted && _controller.errorMessage == null) _controller.loadRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final loading = (c.isLoading && !c.loaded) || (c.isLoadingByteDna && c.byteDna == null);
    final error = c.errorMessage ?? (c.byteDna == null ? c.byteDnaError : null);
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
        child: loading
            ? const LoadingView(message: 'Reading your Byte DNA…')
            : error != null
                ? ErrorView(message: error, onRetry: _load)
                : RefreshIndicator(onRefresh: _load, child: _content()),
      ),
    );
  }

  Widget _content() {
    final c = _controller;
    final dna = c.byteDna;
    final skillValues = PerformanceAnalytics.skills(c.records);
    final skills = [
      for (final name in PerformanceAnalytics.skillNames)
        _SkillRow(name, skillValues[name], _look[name]!.$1, _look[name]!.$2),
    ];
    final withData = skills.where((s) => s.value != null).toList()..sort((a, b) => b.value!.compareTo(a.value!));
    final strongest = withData.isEmpty ? null : withData.first;
    final weakest = withData.length < 2 ? null : withData.last;

    // biggest positive change between the older and newer half of the evidence of a skill
    String? improvedSkill;
    double improvedBy = 0;
    for (final name in PerformanceAnalytics.skillNames) {
      final delta = PerformanceAnalytics.improvement(c.records, _typeOfSkill[name]!);
      if (delta != null && delta > improvedBy) {
        improvedBy = delta;
        improvedSkill = name;
      }
    }
    final topics = (dna?.topicAccuracy.entries.toList() ?? [])
      ..sort((a, b) => b.value.accuracy.compareTo(a.value.accuracy));
    final focus = c.recommendations.isEmpty ? null : c.recommendations.first;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.borderLight.withOpacity(0.5)),
                ),
                child: const Icon(Icons.fingerprint_rounded, color: AppColors.btnAccentPurple, size: 22),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.heading1,
                    children: [
                      const TextSpan(text: 'BYTE '),
                      TextSpan(text: 'DNA', style: TextStyle(color: AppColors.accentCyan)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Text(
                'Different skills.\nOne you.',
                textAlign: TextAlign.right,
                style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Padding(
            padding: EdgeInsets.only(left: 60),
            child: Text('Your Learning Fingerprint', style: AppTextStyles.body),
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          GlowCard(
            glowColor: AppColors.btnAccentPurple,
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            child: Column(
              children: [
                const _FingerprintArt(),
                const SizedBox(height: AppDimensions.spacingLg),
                for (final skill in skills)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
                    child: _SkillBar(skill: skill),
                  ),
                if (withData.isEmpty)
                  Text('Finish a battle, coding challenge, debugging exercise or interview to fill these bars.',
                      textAlign: TextAlign.center, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InsightCard(
                  icon: Icons.star_border_rounded,
                  color: AppColors.accentCyan,
                  title: 'Strongest',
                  lineIcon: Icons.check_rounded,
                  line: strongest == null ? 'Not enough evidence' : strongest.label,
                  caption: strongest == null
                      ? 'Complete an activity to find out.'
                      : '${(strongest.value! * 100).round()}% average accuracy.',
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: _InsightCard(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.btnGamificationPink,
                  title: 'Needs attention',
                  lineIcon: Icons.warning_amber_rounded,
                  line: weakest == null ? 'Not enough evidence' : weakest.label,
                  caption: weakest == null
                      ? 'Practise two different skills to compare them.'
                      : '${(weakest.value! * 100).round()}% average accuracy.',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InsightCard(
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                  title: 'Recent improvement',
                  lineIcon: Icons.arrow_upward_rounded,
                  line: improvedSkill == null ? 'Not yet' : '$improvedSkill +${(improvedBy * 100).round()}%',
                  caption: improvedSkill == null
                      ? 'Needs two or more results in a skill to show a trend.'
                      : 'Your newer results beat your older ones.',
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: _InsightCard(
                  icon: Icons.track_changes_rounded,
                  color: AppColors.btnAccentPurple,
                  title: 'Current focus',
                  lineIcon: Icons.track_changes_rounded,
                  line: focus == null ? (weakest?.label ?? 'None yet') : focus.title,
                  caption: focus == null ? 'Small steps. Big progress.' : c.conceptName(focus.conceptId),
                ),
              ),
            ],
          ),
          if (topics.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingLg),
            Text('Topic strength (from your evidence)', style: AppTextStyles.bodyBold),
            const SizedBox(height: AppDimensions.spacingSm),
            for (final t in topics)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
                child: _SkillBar(
                  skill: _SkillRow(
                      '${t.key} (${t.value.attempts} ${t.value.attempts == 1 ? 'attempt' : 'attempts'})',
                      t.value.accuracy.clamp(0.0, 1.0),
                      Icons.hub_outlined,
                      AppColors.accentCyan),
                ),
              ),
          ],
          if (dna != null && dna.repeatedMistakes.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            Text('Repeated mistakes: ${dna.repeatedMistakes.join(', ')}', style: AppTextStyles.body),
          ],
          if (dna != null && dna.difficultyAreas.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            Text('Areas you find hard: ${dna.difficultyAreas.join(', ')}', style: AppTextStyles.body),
          ],
          if (dna != null && dna.confidenceAreas.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            Text('Areas you feel confident in: ${dna.confidenceAreas.join(', ')}', style: AppTextStyles.body),
          ],
          const SizedBox(height: AppDimensions.spacingLg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.onAccent),
                const SizedBox(width: AppDimensions.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Byte DNA is evolving...',
                          style: AppTextStyles.bodyBold.copyWith(color: AppColors.onAccent)),
                      const SizedBox(height: 2),
                      Text(
                        'It updates after every battle, challenge and interview you finish.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.onAccent.withOpacity(0.85)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (c.records.isEmpty) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pushNamed(RouteNames.conceptList),
                child: const Text('Choose a concept', style: TextStyle(color: AppColors.accentCyan)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FingerprintArt extends StatelessWidget {
  const _FingerprintArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.4)),
        gradient: RadialGradient(
          colors: [AppColors.primary.withOpacity(0.25), Colors.transparent],
        ),
      ),
      child: const Icon(Icons.fingerprint_rounded, size: 56, color: AppColors.accentCyan),
    );
  }
}

class _SkillBar extends StatelessWidget {
  final _SkillRow skill;
  const _SkillBar({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: skill.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Icon(skill.icon, size: 16, color: skill.color),
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(skill.label, style: AppTextStyles.bodyBold),
                  Text(skill.value == null ? 'No data' : '${(skill.value! * 100).round()}%',
                      style: AppTextStyles.bodyBold.copyWith(color: skill.color)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                child: LinearProgressIndicator(
                  value: skill.value ?? 0,
                  minHeight: 8,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation(skill.color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final IconData lineIcon;
  final String line;
  final String caption;

  const _InsightCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.lineIcon,
    required this.line,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(title, style: AppTextStyles.bodyBold),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            width: 20,
            height: 2,
            color: color,
          ),
          Row(
            children: [
              Icon(lineIcon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  line,
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(caption, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
