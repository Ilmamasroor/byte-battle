import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/glow_card.dart';
import '../../../../core/widgets/loading_view.dart';
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

  @override
  void initState() {
    super.initState();
    _controller.loadAnalogy(widget.conceptId);
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
                  onPressed: _controller.isLoading
                      ? null
                      : () => _controller.loadAnalogy(widget.conceptId, force: true),
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.accentCyan),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final analogy = _controller.analogy;

            if (_controller.isLoading && analogy == null) {
              return const LoadingView(message: 'Coming up with an analogy for you...');
            }
            if (_controller.errorMessage != null && analogy == null) {
              return ErrorView(
                message: _controller.errorMessage!,
                onRetry: () => _controller.loadAnalogy(widget.conceptId, force: true),
              );
            }

            return _Content(conceptId: widget.conceptId, analogy: analogy);
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final String conceptId;
  final AnalogyModel? analogy;
  const _Content({required this.conceptId, required this.analogy});

  @override
  Widget build(BuildContext context) {
    final concept = analogy?.concept;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConceptHeader(
            title: concept?.name ?? 'Concept',
            difficulty: concept?.difficulty ?? 'Medium',
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
          GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.link_rounded, color: AppColors.accentCyan, size: 18),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Text('THE ANALOGY',
                        style: AppTextStyles.bodyBold.copyWith(letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                Text(analogy?.analogy ?? '', style: AppTextStyles.body),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.hub_outlined, color: AppColors.btnAccentPurple, size: 18),
                const SizedBox(width: AppDimensions.spacingSm),
                Expanded(
                  child: Text(analogy?.connection ?? '', style: AppTextStyles.caption),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.btnGamificationPink.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.btnGamificationPink.withOpacity(0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.psychology_outlined,
                    color: AppColors.btnGamificationPink, size: 18),
                const SizedBox(width: AppDimensions.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Memory Tip', style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(analogy?.memoryTip ?? '', style: AppTextStyles.body),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          AppButton(
            label: 'Next: Remember',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.of(context).pushReplacementNamed(RouteNames.remember),
          ),
        ],
      ),
    );
  }
}
