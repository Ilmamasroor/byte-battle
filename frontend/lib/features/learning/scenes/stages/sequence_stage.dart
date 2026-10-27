import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../scene_models.dart';
import 'stage_common.dart';

/// Who-talks-to-whom stage: actors across the top with lifelines, and the messages revealed so far as arrows
/// between them. Covers protocols (TCP, DNS, HTTP), caches and databases, queues, transactions, replication.
class SequenceStage extends StatelessWidget {
  final SceneDoc doc;
  final int index;
  const SequenceStage({super.key, required this.doc, required this.index});

  @override
  Widget build(BuildContext context) {
    final s = doc.steps[index].state;
    final actors = asList(s['actors']).map(str).toList();
    final states = asMap(s['actorState']);
    final msgs = <Map<String, dynamic>>[];
    for (var i = 0; i <= index; i++) {
      final st = doc.steps[i];
      // `msg` is a per-step event (not inherited), so read it from the raw step state only when it was set on that step.
      final m = st.state['msg'];
      if (m is Map) msgs.add(Map<String, dynamic>.from(m));
      final ms = st.state['msgs'];
      if (ms is List) msgs.addAll(ms.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
    }
    if (actors.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: LayoutBuilder(builder: (context, box) {
        final colW = box.maxWidth / actors.length;
        double cx(int i) => colW * (i + 0.5);
        return Column(children: [
          Row(children: [
            for (var i = 0; i < actors.length; i++)
              SizedBox(
                width: colW,
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.16), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.6))),
                    child: Text(actors[i], textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyBold.copyWith(fontSize: 12)),
                  ),
                  SizedBox(
                      height: 18,
                      child: Text(str(states['$i']),
                          style: AppTextStyles.code.copyWith(fontSize: 10, color: AppColors.xp), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
                ]),
              ),
          ]),
          Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _LifelinePainter(actors.length))),
            Column(children: [
              const SizedBox(height: 6),
              for (var i = 0; i < msgs.length; i++) _Msg(msg: msgs[i], cx: cx, colW: colW, latest: i == msgs.length - 1, n: actors.length),
              if (msgs.isEmpty) const SizedBox(height: 40),
            ]),
          ]),
        ]);
      }),
    );
  }
}

class _LifelinePainter extends CustomPainter {
  final int n;
  _LifelinePainter(this.n);
  @override
  void paint(Canvas canvas, Size size) {
    final colW = size.width / n;
    for (var i = 0; i < n; i++) {
      final x = colW * (i + 0.5);
      var y = 0.0;
      while (y < size.height) {
        canvas.drawLine(
            Offset(x, y),
            Offset(x, y + 5),
            Paint()
              ..color = AppColors.border
              ..strokeWidth = 1.5);
        y += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_LifelinePainter old) => old.n != n;
}

class _Msg extends StatelessWidget {
  final Map<String, dynamic> msg;
  final double Function(int) cx;
  final double colW;
  final bool latest;
  final int n;
  const _Msg({required this.msg, required this.cx, required this.colW, required this.latest, required this.n});

  @override
  Widget build(BuildContext context) {
    final from = ((msg['from'] as num?)?.toInt() ?? 0).clamp(0, n - 1);
    final to = ((msg['to'] as num?)?.toInt() ?? 0).clamp(0, n - 1);
    final kind = str(msg['kind']);
    final color = kind == 'error' ? AppColors.error : (kind == 'res' ? AppColors.success : (kind == 'note' ? AppColors.xp : AppColors.accentCyan));
    final left = cx(from < to ? from : to);
    final right = cx(from < to ? to : from);
    final self = from == to;
    return TweenAnimationBuilder<double>(
      key: ValueKey('${msg['label']}_$from$to$latest'),
      tween: Tween(begin: latest ? 0 : 1, end: 1),
      duration: const Duration(milliseconds: 450),
      builder: (context, t, _) => Opacity(
        opacity: t,
        child: SizedBox(
          height: 46,
          child: Stack(children: [
            if (self || kind == 'note')
              Positioned(
                left: (left - 70).clamp(0, double.infinity),
                width: 140,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(color: color.withOpacity(0.16), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.6))),
                  child: Text(str(msg['label']),
                      textAlign: TextAlign.center, style: AppTextStyles.code.copyWith(fontSize: 10.5, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              )
            else ...[
              Positioned(left: left, width: (right - left) * t, top: 26, child: Container(height: 2.5, color: color)),
              Positioned(
                left: from < to ? left + (right - left) * t - 10 : left - 2,
                top: 18,
                child: Icon(from < to ? Icons.arrow_right_rounded : Icons.arrow_left_rounded, size: 20, color: color),
              ),
              Positioned(
                left: left,
                width: right - left,
                top: 2,
                child: Text(str(msg['label']),
                    textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: AppTextStyles.code.copyWith(fontSize: 11, color: color, fontWeight: FontWeight.w800)),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
