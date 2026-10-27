import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../contract/viz_contract.dart';
import '../engine/playback_controller.dart';
import '../modules/viz_palette.dart';

/// The execution timeline: one row per actor (thread), one column per event in the order they happened. Reading a
/// column left to right is time; reading a row is what one thread did. Tapping an event seeks to the state right
/// after it, so the scene, code, values and captions all follow the same selection.
class EventTimeline extends StatefulWidget {
  final VizTimeline timeline;
  final VizPlaybackController controller;

  /// Turns an actor id (a thread name) into the label spoken and shown.
  final String Function(String actor) actorLabel;

  const EventTimeline({super.key, required this.timeline, required this.controller, required this.actorLabel});

  @override
  State<EventTimeline> createState() => _EventTimelineState();
}

class _EventTimelineState extends State<EventTimeline> {
  static const _cell = 58.0;
  static const _rowHeight = 46.0;
  static const _labelWidth = 74.0;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_follow);
  }

  @override
  void didUpdateWidget(EventTimeline old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_follow);
      widget.controller.addListener(_follow);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_follow);
    _scroll.dispose();
    super.dispose();
  }

  /// Keeps the selected event in view while playing or stepping.
  void _follow() {
    // After the frame, so the scroll extent already includes the layout this position produced.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToSelected();
    });
  }

  void _scrollToSelected() {
    if (!_scroll.hasClients) return;
    final target = ((widget.controller.position - 1) * _cell - _scroll.position.viewportDimension / 2 + _cell).clamp(0.0, _scroll.position.maxScrollExtent);
    if ((target - _scroll.offset).abs() < _cell) return;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    reduce ? _scroll.jumpTo(target) : _scroll.animateTo(target, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.timeline;
    final marks = t.eventMarks;
    if (marks.isEmpty) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final pos = widget.controller.position;
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text('EXECUTION TIMELINE', style: AppTextStyles.eyebrow, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Flexible(child: Text('time flows left to right', style: AppTextStyles.caption, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: _labelWidth,
                child: Column(children: [
                  for (var a = 0; a < t.actors.length; a++)
                    SizedBox(
                      height: _rowHeight,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 9, height: 9, decoration: BoxDecoration(color: VizPalette.thread(a), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Flexible(child: Text(widget.actorLabel(t.actors[a]), style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                        ]),
                      ),
                    ),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: marks.length * _cell,
                    height: t.actors.length * _rowHeight,
                    child: Stack(children: [
                      for (var a = 1; a < t.actors.length; a++)
                        Positioned(left: 0, right: 0, top: a * _rowHeight, child: Divider(height: 1, color: AppColors.border.withOpacity(0.6))),
                      for (var i = 0; i < marks.length; i++)
                        Positioned(
                          left: i * _cell,
                          top: marks[i].actor * _rowHeight,
                          width: _cell,
                          height: _rowHeight,
                          child: _EventChip(
                            index: i + 1,
                            mark: marks[i],
                            actor: widget.actorLabel(t.actors[marks[i].actor]),
                            selected: marks[i].position == pos,
                            reached: marks[i].position <= pos,
                            onTap: () => widget.controller.seek(marks[i].position),
                          ),
                        ),
                    ]),
                  ),
                ),
              ),
            ]),
          ]),
        );
      },
    );
  }
}

class _EventChip extends StatelessWidget {
  final int index;
  final VizEventMark mark;
  final String actor;
  final bool selected;
  final bool reached;
  final VoidCallback onTap;
  const _EventChip({required this.index, required this.mark, required this.actor, required this.selected, required this.reached, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = VizPalette.thread(mark.actor);
    final border = mark.problem ? AppColors.error : (mark.waiting ? AppColors.warning : color);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Event $index: $actor ${mark.label}${mark.problem ? ', the update is lost here' : ''}${mark.waiting ? ', waiting' : ''}${selected ? ', selected' : ''}',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: selected ? border : (reached ? color.withOpacity(0.22) : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: reached || selected ? border : border.withOpacity(0.4), width: selected || mark.problem ? 2 : 1),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (mark.problem) Icon(Icons.warning_amber_rounded, size: 13, color: selected ? AppColors.onAccent : AppColors.error),
              if (mark.waiting && !mark.problem) Icon(Icons.hourglass_top_rounded, size: 12, color: selected ? AppColors.onAccent : AppColors.warning),
              Flexible(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$index', style: AppTextStyles.caption.copyWith(fontSize: 9, color: selected ? AppColors.onAccent : AppColors.textHint)),
                  Text(mark.label,
                      style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: selected ? AppColors.onAccent : (reached ? AppColors.textPrimary : AppColors.textSecondary)),
                      overflow: TextOverflow.clip,
                      maxLines: 1),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
