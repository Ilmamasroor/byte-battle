import 'package:flutter/material.dart';
import '../../data/learning_progress_service.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/personalization/hero_prefs.dart';
import '../../../../core/personalization/lens.dart';
import '../../../../core/widgets/ai/lens_picker.dart';
import '../../../../core/widgets/ai/companion_says.dart';
import '../../../../core/widgets/ai/memory_poster.dart';
import '../../../../core/widgets/brand/bit_mascot.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../../concepts/presentation/state/concept_controller.dart';
import '../../../concepts/presentation/widgets/concept_header.dart';
import '../../../concepts/presentation/widgets/concept_progress.dart';
import '../data/models/mnemonic_model.dart';
import '../presentation/state/mnemonic_controller.dart';

/// "Remember" stage — AI-generated mnemonic for the concept (from
/// `POST /api/ai/mnemonic`) plus a memory tip, and a "Next: Battle" CTA.
/// A "Regenerate" action re-requests a fresh mnemonic from the AI.
class MnemonicScreen extends StatefulWidget {
  final String conceptId;

  const MnemonicScreen({super.key, required this.conceptId});

  @override
  State<MnemonicScreen> createState() => _MnemonicScreenState();
}

class _MnemonicScreenState extends State<MnemonicScreen> {
  final _controller = MnemonicController.instance;
  final _concept = ConceptController();

  @override
  void initState() {
    super.initState();
    _concept.load(widget.conceptId);
    _controller.loadMnemonic(widget.conceptId, lens: HeroPrefs.instance.lens);
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
                  onPressed: _controller.isLoading ? null : () => _controller.loadMnemonic(widget.conceptId, force: true, lens: HeroPrefs.instance.lens),
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
            final mnemonic = _controller.mnemonic;

            if (_controller.isLoading && mnemonic == null) {
              return LoadingView(message: Lens.byId(HeroPrefs.instance.lens)?.loading ?? 'Coming up with a mnemonic for you...');
            }
            if (_controller.errorMessage != null && mnemonic == null) {
              return ErrorView(
                message: _controller.errorMessage!,
                onRetry: () => _controller.loadMnemonic(widget.conceptId, force: true, lens: HeroPrefs.instance.lens),
              );
            }

            return _Content(
              conceptId: widget.conceptId,
              concept: _concept.concept,
              mnemonic: mnemonic,
              onLens: (id) => _controller.loadMnemonic(widget.conceptId, force: true, lens: id),
            );
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final String conceptId;
  final MnemonicModel? mnemonic;
  final ConceptModel? concept;
  final ValueChanged<String?> onLens;
  const _Content({required this.conceptId, required this.concept, required this.mnemonic, required this.onLens});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConceptHeader(
            title: concept?.name ?? mnemonic?.concept.name ?? 'Concept',
            difficulty: difficultyLabel(concept?.difficulty),
            icon: Icons.psychology_outlined,
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          ConceptProgress(
            current: ConceptStage.remember,
            conceptId: conceptId,
            routes: const {
              ConceptStage.concept: RouteNames.conceptDetail,
              ConceptStage.understand: RouteNames.understand,
              ConceptStage.visualize: RouteNames.explore,
              ConceptStage.relate: RouteNames.relate,
              ConceptStage.remember: RouteNames.remember,
              ConceptStage.battle: RouteNames.battle,
            },
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          LensPicker(onChanged: onLens),
          const SizedBox(height: AppDimensions.spacingMd),
          const CompanionSays(
            mood: BitMood.cheer,
            text: 'Last step before the battle: lock it in. Read it out loud, then test yourself.',
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          MemoryPoster(
            lens: Lens.byId(HeroPrefs.instance.lens),
            mnemonic: mnemonic?.mnemonic.mnemonic ?? '',
            memoryTip: mnemonic?.mnemonic.memoryTip ?? '',
          ),
          if (mnemonic?.fallback == true) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            Text('The AI service is unavailable right now, so this is a basic template. Tap refresh to try again.', style: AppTextStyles.caption),
          ],
          const SizedBox(height: AppDimensions.spacingXl),
          AppButton(
            label: 'Next: Battle',
            icon: Icons.arrow_forward_rounded,
            onPressed: () async {
              await LearningProgressService.completeIfAt(conceptId, 'REMEMBER');
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed(
                RouteNames.battle,
                arguments: {'conceptId': conceptId},
              );
            },
          ),
        ],
      ),
    );
  }
}
