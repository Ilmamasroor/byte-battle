import 'package:flutter/material.dart';
import '../../data/learning_progress_service.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/personalization/hero_prefs.dart';
import '../../../../core/personalization/lens.dart';
import '../../../../core/widgets/ai/lens_picker.dart';
import '../../../../core/widgets/ai/analogy_scene.dart';
import '../../../../core/widgets/ai/companion_says.dart';
import '../../../../core/widgets/brand/bit_mascot.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../../concepts/presentation/state/concept_controller.dart';
import '../../../concepts/presentation/widgets/concept_header.dart';
import '../../../concepts/presentation/widgets/concept_progress.dart';
import '../data/models/analogy_model.dart';
import '../presentation/state/analogy_controller.dart';

/// "Relate" stage — AI-generated personal analogy for the concept
/// (from `POST /api/ai/analogy`), how it connects to something familiar,
/// a memory tip, and a "Next: Remember" CTA. A "Regenerate" action
/// re-requests a fresh analogy from the AI.
class AnalogyScreen extends StatefulWidget {
  final String conceptId;

  const AnalogyScreen({super.key, required this.conceptId});

  @override
  State<AnalogyScreen> createState() => _AnalogyScreenState();
}

class _AnalogyScreenState extends State<AnalogyScreen> {
  final _controller = AnalogyController.instance;
  final _concept = ConceptController();

  @override
  void initState() {
    super.initState();
    _concept.load(widget.conceptId);
    _controller.loadAnalogy(widget.conceptId, lens: HeroPrefs.instance.lens);
  }

  @override
  void dispose() {
    _concept.dispose();
    super.dispose();
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spacingMd),
            child: Center(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => IconButton(
                  tooltip: 'Regenerate',
                  onPressed: _controller.isLoading ? null : () => _controller.loadAnalogy(widget.conceptId, force: true, lens: HeroPrefs.instance.lens),
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.accentCyan),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_controller, _concept, HeroPrefs.instance]),
          builder: (context, _) {
            final analogy = _controller.analogy;

            if (_controller.isLoading && analogy == null) {
              return LoadingView(message: Lens.byId(HeroPrefs.instance.lens)?.loading ?? 'Coming up with an analogy for you...');
            }
            if (_controller.errorMessage != null && analogy == null) {
              return ErrorView(
                message: _controller.errorMessage!,
                onRetry: () => _controller.loadAnalogy(widget.conceptId, force: true, lens: HeroPrefs.instance.lens),
              );
            }

            return _Content(
              conceptId: widget.conceptId,
              concept: _concept.concept,
              analogy: analogy,
              onLens: (id) => _controller.loadAnalogy(widget.conceptId, force: true, lens: id),
            );
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final String conceptId;
  final AnalogyModel? analogy;
  final ConceptModel? concept;
  final ValueChanged<String?> onLens;
  const _Content({required this.conceptId, required this.concept, required this.analogy, required this.onLens});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConceptHeader(
            title: concept?.name ?? analogy?.concept.name ?? 'Concept',
            difficulty: difficultyLabel(concept?.difficulty),
            icon: Icons.link_rounded,
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          ConceptProgress(
            current: ConceptStage.relate,
            conceptId: conceptId,
            routes: const {
              ConceptStage.concept: RouteNames.conceptDetail,
              ConceptStage.understand: RouteNames.understand,
              ConceptStage.visualize: RouteNames.explore,
              ConceptStage.relate: RouteNames.relate,
              ConceptStage.remember: RouteNames.remember,
            },
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          LensPicker(onChanged: onLens),
          const SizedBox(height: AppDimensions.spacingMd),
          CompanionSays(
            mood: BitMood.curious,
            text: Lens.byId(HeroPrefs.instance.lens) == null
                ? 'Let me explain this with something you already know. Picture it, then we map it to code.'
                : 'Through the ${Lens.byId(HeroPrefs.instance.lens)!.label.toLowerCase()} lens! Picture it, then we map it to code.',
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          AnalogyScene(
            lens: Lens.byId(HeroPrefs.instance.lens),
            analogy: analogy?.analogy ?? '',
            connection: analogy?.connection ?? '',
            memoryTip: analogy?.memoryTip ?? '',
          ),
          if (analogy?.fallback == true) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            Text('The AI service is unavailable right now, so this is a basic template. Tap refresh to try again.', style: AppTextStyles.caption),
          ],
          const SizedBox(height: AppDimensions.spacingXl),
          AppButton(
            label: 'Next: Remember',
            icon: Icons.arrow_forward_rounded,
            onPressed: () async {
              await LearningProgressService.completeIfAt(conceptId, 'RELATE');
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed(
                RouteNames.remember,
                arguments: {'conceptId': conceptId},
              );
            },
          ),
        ],
      ),
    );
  }
}
