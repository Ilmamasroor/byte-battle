import 'package:flutter/material.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../data/models/curriculum_tree.dart';
import '../state/curriculum_controller.dart';

/// Shared loading / error-with-retry / pull-to-refresh frame for the curriculum screens. [builder] gets the
/// loaded tree and returns a scrollable (so pull-to-refresh works); return `null` for an empty state.
class CurriculumBody extends StatefulWidget {
  final Widget? Function(BuildContext context, CurriculumTree tree) builder;
  final String emptyMessage;

  const CurriculumBody({super.key, required this.builder, this.emptyMessage = 'Nothing here yet.'});

  @override
  State<CurriculumBody> createState() => _CurriculumBodyState();
}

class _CurriculumBodyState extends State<CurriculumBody> {
  final _controller = CurriculumController.instance;

  @override
  void initState() {
    super.initState();
    // Re-read on every visit so progress made in the learning flow shows up; a cached tree is shown meanwhile.
    _controller.load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final tree = _controller.tree;
        if (tree == null) {
          if (_controller.errorMessage != null) {
            return ErrorView(message: _controller.errorMessage!, onRetry: () => _controller.load(force: true));
          }
          return const LoadingView(message: 'Loading curriculum...');
        }
        final content = widget.builder(context, tree);
        return RefreshIndicator(
          onRefresh: () => _controller.load(force: true),
          child: content ??
              ListView(children: [
                const SizedBox(height: 120),
                Center(child: Text(widget.emptyMessage, style: AppTextStyles.body)),
              ]),
        );
      },
    );
  }
}
