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

  @override
  void initState() {
    super.initState();
    _controller.loadMnemonic(widget.conceptId);
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
                      : () => _controller.loadMnemonic(widget.conceptId, force: true),
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
            final mnemonic = _controller.mnemonic;

            if (_controller.isLoading && mnemonic == null) {
              return const LoadingView(message: 'Coming up with a mnemonic for you...');
            }
            if (_controller.errorMessage != null && mnemonic == null) {
              return ErrorView(
                message: _controller.errorMessage!,
                onRetry: () => _controller.loadMnemonic(widget.conceptId, force: true),
              );
            }

            return _Content(conceptId: widget.conceptId, mnemonic: mnemonic);
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final String conceptId;
  final MnemonicModel? mnemonic;
  const _Content({required this.conceptId, required this.mnemonic});

  @override
  Widget build(BuildContext context) {
    final concept = mnemonic?.concept;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConceptHeader(
            title: concept?.name ?? 'Concept',
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
          GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_outlined,
                        color: AppColors.accentCyan, size: 18),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Text('THE MNEMONIC',
                        style: AppTextStyles.bodyBold.copyWith(letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                Text(
                  mnemonic?.mnemonic.mnemonic ?? '',
                  style: AppTextStyles.heading2.copyWith(color: AppColors.accentCyan),
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
                const Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.btnGamificationPink, size: 18),
                const SizedBox(width: AppDimensions.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Memory Tip', style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(mnemonic?.mnemonic.memoryTip ?? '', style: AppTextStyles.body),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          AppButton(
            label: 'Next: Battle',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.of(context).pushReplacementNamed(RouteNames.battle),
          ),
        ],
      ),
    );
  }
}
