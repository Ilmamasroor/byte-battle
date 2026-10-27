import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../readiness/data/readiness_store.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/glow_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../learning/data/learning_progress_service.dart';
import '../../../learning/scenes/scene_preview_card.dart';
import '../../../learning/explanation/data/models/canonical_knowledge_model.dart';
import '../../../learning/explanation/data/repositories/explanation_repository.dart';
import '../../data/models/concept_model.dart';
import '../state/concept_controller.dart';
import '../widgets/concept_header.dart';

/// Concept overview screen, the first stop in a concept's learning flow. Everything here is the real concept:
/// name / difficulty / description from `GET /api/concepts/{id}`, "What You'll Learn" from the canonical key
/// points, the learner's own stage from `/api/learning`, and a "Start Learning" CTA into the Understand stage.
class ConceptDetailScreen extends StatefulWidget {
  final String conceptId;

  const ConceptDetailScreen({super.key, required this.conceptId});

  @override
  State<ConceptDetailScreen> createState() => _ConceptDetailScreenState();
}

class _ConceptDetailScreenState extends State<ConceptDetailScreen> {
  final _concept = ConceptController();

  CanonicalKnowledgeModel? _knowledge;
  String? _knowledgeError;
  bool _knowledgeLoading = true;
  LearningProgressModel? _progress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _concept.dispose();
    super.dispose();
  }

  void _load() {
    _concept.load(widget.conceptId, force: true);
    _loadSecondary();
  }

  Future<void> _loadSecondary() async {
    setState(() {
      _knowledgeLoading = true;
      _knowledgeError = null;
    });
    final progress = LearningProgressService.current(widget.conceptId);
    try {
      final knowledge = await ExplanationRepository.live().getCanonicalKnowledge(widget.conceptId);
      if (!mounted) return;
      setState(() => _knowledge = knowledge);
    } on NetworkException catch (e) {
      if (mounted) setState(() => _knowledgeError = e.message);
    } catch (_) {
      if (mounted) setState(() => _knowledgeError = 'Something went wrong. Please try again.');
    }
    final p = await progress;
    if (!mounted) return;
    setState(() {
      _progress = p;
      _knowledgeLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _concept,
          builder: (context, _) {
            final concept = _concept.concept;
            if (concept == null && _concept.isLoading) {
              return const LoadingView(message: 'Loading concept...');
            }
            if (concept == null) {
              return ErrorView(message: _concept.errorMessage ?? 'Could not load this concept.', onRetry: _load);
            }
            return _body(concept);
          },
        ),
      ),
    );
  }

  Widget _body(ConceptModel concept) {
    final description = concept.description?.trim() ?? '';
    final progress = _progress;
    final started = progress != null && (progress.progressPercentage > 0 || progress.currentStage != 'UNDERSTAND');
    final keyPoints = _knowledge?.keyPoints ?? const <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConceptHeader(title: concept.name ?? 'Concept', difficulty: difficultyLabel(concept.difficulty)),
          const SizedBox(height: AppDimensions.spacingXl),
          GlowCard(
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.track_changes_rounded, color: AppColors.accentCyan, size: 20),
                const SizedBox(width: AppDimensions.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About This Concept', style: AppTextStyles.bodyBold),
                      const SizedBox(height: 4),
                      Text(description.isEmpty ? 'No description is available for this concept yet.' : description,
                          style: AppTextStyles.body),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ScenePreviewCard(conceptId: widget.conceptId),
          if (progress != null) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              started
                  ? 'Your progress: ${progress.progressPercentage}% - next stage: ${_stageLabel(progress.currentStage)}'
                  : 'You have not started this concept yet.',
              style: AppTextStyles.caption,
            ),
          ],
          const SizedBox(height: AppDimensions.spacingLg),
          AppButton(
            label: started ? 'Continue Learning' : 'Start Learning',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => started
                ? Navigator.of(context).pushNamed(RouteNames.understand, arguments: {'conceptId': widget.conceptId})
                : ReadinessStore.open(context, widget.conceptId, RouteNames.understand),
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          Text("What You'll Learn", style: AppTextStyles.heading2),
          const SizedBox(height: AppDimensions.spacingMd),
          if (_knowledgeLoading && _knowledge == null)
            const Padding(
              padding: EdgeInsets.all(AppDimensions.spacingMd),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_knowledgeError != null && _knowledge == null)
            Row(
              children: [
                Expanded(child: Text('Could not load the key points: $_knowledgeError', style: AppTextStyles.caption)),
                TextButton(onPressed: _loadSecondary, child: const Text('Retry')),
              ],
            )
          else if (keyPoints.isEmpty)
            Text('Key points for this concept are not available yet.', style: AppTextStyles.caption)
          else
            for (final point in keyPoints)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
                child: GlowCard(
                  padding: const EdgeInsets.all(AppDimensions.spacingMd),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: AppColors.accentCyan, size: 18),
                      const SizedBox(width: AppDimensions.spacingSm),
                      Expanded(child: Text(point, style: AppTextStyles.body)),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  static String _stageLabel(String stage) {
    final s = stage.toLowerCase().replaceAll('_', ' ');
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }
}
