import 'package:flutter/material.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/network/backend_api.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../learning/data/learning_progress_service.dart';
import '../../data/models/concept_model.dart';
import '../state/concept_controller.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

enum StageStatus { completed, inProgress, locked }

class _Stage {
  final String label;
  final String status;
  final StageStatus state;
  final String? route;

  const _Stage(this.label, this.status, this.state, {this.route});
}

/// A journey tile and the range of backend stages it covers: done once the learner's current stage is past
/// [end], active while it is within [start, end), locked before.
class _TileDef {
  final String label;
  final String route;
  final int start;
  final int end;
  const _TileDef(this.label, this.route, this.start, this.end);
}

/// The real journey for the flagship concept. Stage names follow the product loop:
/// Understand -> Visualize -> Relate -> Remember -> Battle -> Code -> Debug -> Interview.
const _tiles = [
  _TileDef('Understand', RouteNames.understand, 0, 1),
  _TileDef('Explore', RouteNames.explore, 1, 2),
  _TileDef('Relate & Remember', RouteNames.relate, 2, 4),
  _TileDef('Challenge', RouteNames.battle, 4, 5),
  _TileDef('Implement', RouteNames.coding, 5, 6),
  _TileDef('Debug', RouteNames.debugging, 6, 7),
  _TileDef('Boss Battle', RouteNames.bossBattleIntro, 6, 8),
  _TileDef('Interview', RouteNames.interviewIntro, 7, 8),
];

class LearningJourneyScreen extends StatefulWidget {
  final String conceptId;

  const LearningJourneyScreen({super.key, required this.conceptId});

  @override
  State<LearningJourneyScreen> createState() => _LearningJourneyScreenState();
}

class _LearningJourneyScreenState extends State<LearningJourneyScreen> {
  final _concept = ConceptController();
  LearningProgressModel? _progress;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _concept.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    _concept.load(widget.conceptId);
    try {
      // POST /api/learning/start is idempotent: it creates the progress row on first use and returns the
      // current one afterwards.
      final progress = await BackendApi.instance.startLearning(widget.conceptId);
      if (!mounted) return;
      setState(() {
        _progress = progress;
        _error = null;
        _loading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  List<_Stage> _stages() {
    final current = _progress == null ? 0 : stageIndex(_progress!.currentStage);
    return [
      for (final t in _tiles)
        _Stage(
          t.label,
          current >= t.end
              ? 'Completed'
              : (current >= t.start ? 'Ready' : 'Locked'),
          current >= t.end
              ? StageStatus.completed
              : (current >= t.start ? StageStatus.inProgress : StageStatus.locked),
          route: t.route,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final stages = _stages();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Your Learning Journey', style: AppTextStyles.heading2),
      ),
      body: _loading
          ? const LoadingView(message: 'Mapping your journey...')
          : (_error != null && _progress == null)
              ? ErrorView(
                  message: _error!,
                  onRetry: () {
                    setState(() => _loading = true);
                    _refresh();
                  },
                )
              : Padding(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListenableBuilder(
                    listenable: _concept,
                    builder: (context, _) {
                      final c = _concept.concept;
                      if (c == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
                        child: Text(
                          '${c.name ?? 'Concept'} - ${difficultyLabel(c.difficulty)}'
                          '${_progress != null ? ' - ${_progress!.progressPercentage}% complete' : ''}',
                          style: AppTextStyles.display.copyWith(fontSize: 22),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        itemCount: stages.length,
                        itemBuilder: (context, index) {
                          final stage = stages[index];
                          final isLast = index == stages.length - 1;
                          return _StageTile(
                            stage: stage,
                            isLast: isLast,
                            onTap: stage.state == StageStatus.locked || stage.route == null
                                ? null
                                : () => Navigator.of(context)
                                    .pushNamed(stage.route!,
                                        arguments: {'conceptId': widget.conceptId})
                                    .then((_) => _refresh()),
                          );
                        },
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Complete all stages to master this concept',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                ],
              ),
            ),
    );
  }
}

class _StageTile extends StatelessWidget {
  final _Stage stage;
  final bool isLast;
  final VoidCallback? onTap;

  const _StageTile({required this.stage, required this.isLast, this.onTap});

  bool get _locked => stage.state == StageStatus.locked;
  bool get _current => stage.state == StageStatus.inProgress;

  Color get _accent {
    switch (stage.state) {
      case StageStatus.completed:
        return AppColors.success;
      case StageStatus.inProgress:
        return AppColors.primary;
      case StageStatus.locked:
        return AppColors.textHint;
    }
  }

  IconData get _icon {
    switch (stage.state) {
      case StageStatus.completed:
        return Icons.check_rounded;
      case StageStatus.inProgress:
        return Icons.play_arrow_rounded;
      case StageStatus.locked:
        return Icons.lock_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _locked ? AppColors.surface : _accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: _locked ? AppColors.border : _accent, width: 1.5),
                ),
                child: Icon(_icon, size: 18, color: _locked ? AppColors.textHint : AppColors.onAccent),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: stage.state == StageStatus.completed ? AppColors.success.withOpacity(0.6) : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _current ? AppColors.primary.withOpacity(0.10) : AppColors.surface.withOpacity(_locked ? 0.45 : 0.9),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: _current ? AppColors.primary : AppColors.border, width: _current ? 1.4 : 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stage.label,
                                style: AppTextStyles.bodyBold.copyWith(color: _locked ? AppColors.textSecondary : AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text(stage.status, style: AppTextStyles.caption.copyWith(color: _accent, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      if (_current) const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
