import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import 'stage_common.dart';

/// Data-structure and algorithm stage. A step lists one or more structures (array, list, stack, queue, hash, tree,
/// graph, gantt, bars) with a state on each cell/node, so a single scene can show e.g. a graph, the BFS queue and
/// the visited array moving together.
class StructureStage extends StatelessWidget {
  final Map<String, dynamic> s;
  const StructureStage({super.key, required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (s['code'] is Map) ...[CodePanel(code: asMap(s['code'])), const SizedBox(height: 10)],
        for (final raw in asList(s['structures'])) ...[
          _Block(def: asMap(raw)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Block extends StatelessWidget {
  final Map<String, dynamic> def;
  const _Block({required this.def});

  @override
  Widget build(BuildContext context) {
    final kind = str(def['kind']);
    final name = str(def['name']);
    Widget body;
    switch (kind) {
      case 'array':
        body = _array(def);
      case 'list':
        body = _list(def);
      case 'stack':
        body = _stack(def);
      case 'queue':
        body = _queue(def);
      case 'hash':
        body = _hash(def);
      case 'tree':
        body = _Tree(def: def);
      case 'graph':
        body = _Graph(def: def);
      case 'gantt':
        body = _Gantt(def: def);
      case 'bars':
        body = _bars(def);
      default:
        body = Text('unknown structure "$kind"', style: AppTextStyles.caption);
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (name.isNotEmpty) ...[Text(name.toUpperCase(), style: AppTextStyles.eyebrow.copyWith(fontSize: 10)), const SizedBox(height: 10)],
        body,
        if (str(def['caption']).isNotEmpty) ...[const SizedBox(height: 8), Text(str(def['caption']), style: AppTextStyles.code.copyWith(fontSize: 11.5, color: AppColors.xp))],
      ]),
    );
  }

  static Widget cell(String v, String? st, {double w = 46, double h = 46}) {
    final c = stateColor(st);
    final active = stateIsActive(st);
    final dim = st == 'dim';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: w,
      height: h,
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(active ? 1.08 : 1.0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? c.withOpacity(0.22) : AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dim ? AppColors.border : c, width: active ? 2 : 1),
        boxShadow: active ? [BoxShadow(color: c.withOpacity(0.35), blurRadius: 14, spreadRadius: -4)] : null,
      ),
      child: Text(v,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.code.copyWith(fontSize: v.length > 4 ? 10.5 : 14, fontWeight: FontWeight.w800, color: dim ? AppColors.textHint : AppColors.textPrimary)),
    );
  }

  Widget _array(Map<String, dynamic> d) {
    final cells = asList(d['cells']);
    final ptrs = asMap(d['pointers']);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (var i = 0; i < cells.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Column(children: [
              cell(str(asMap(cells[i])['v']), str(asMap(cells[i])['s'])),
              const SizedBox(height: 3),
              Text('$i', style: AppTextStyles.caption.copyWith(fontSize: 10)),
              SizedBox(
                height: 16,
                child: Text(
                  [
                    for (final e in ptrs.entries)
                      if (e.value is num && (e.value as num).toInt() == i) e.key
                  ].join(','),
                  style: AppTextStyles.code.copyWith(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w800),
                ),
              ),
            ]),
          ),
      ]),
    );
  }

  Widget _list(Map<String, dynamic> d) {
    final nodes = asList(d['nodes']);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        if (str(d['head']).isNotEmpty) ...[
          Text(str(d['head']), style: AppTextStyles.code.copyWith(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w800)),
          const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textHint),
        ],
        for (var i = 0; i < nodes.length; i++) ...[
          cell(str(asMap(nodes[i])['v']), str(asMap(nodes[i])['s']), w: 50),
          if (i < nodes.length - 1) Icon(d['doubly'] == true ? Icons.swap_horiz_rounded : Icons.arrow_forward_rounded, size: 18, color: AppColors.textHint),
        ],
        if (d['cycle'] == true)
          const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.replay_rounded, size: 18, color: AppColors.orchid))
        else
          Padding(padding: const EdgeInsets.only(left: 6), child: Text('null', style: AppTextStyles.code.copyWith(fontSize: 11, color: AppColors.textHint))),
      ]),
    );
  }

  Widget _stack(Map<String, dynamic> d) {
    final items = asList(d['items']);
    return Row(children: [
      Column(children: [
        if (items.isEmpty) Text('empty', style: AppTextStyles.caption),
        for (var i = items.length - 1; i >= 0; i--)
          Padding(padding: const EdgeInsets.only(bottom: 5), child: cell(str(asMap(items[i])['v']), str(asMap(items[i])['s']), w: 90, h: 38)),
      ]),
      const SizedBox(width: 10),
      if (items.isNotEmpty)
        Row(children: [
          const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.primary),
          Text('top', style: AppTextStyles.code.copyWith(fontSize: 11, color: AppColors.primary))
        ]),
    ]);
  }

  Widget _queue(Map<String, dynamic> d) {
    final items = asList(d['items']);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        Text('front', style: AppTextStyles.code.copyWith(fontSize: 11, color: AppColors.primary)),
        const SizedBox(width: 6),
        if (items.isEmpty) Text('empty', style: AppTextStyles.caption),
        for (final it in items) Padding(padding: const EdgeInsets.only(right: 5), child: cell(str(asMap(it)['v']), str(asMap(it)['s']))),
        const SizedBox(width: 2),
        Text('rear', style: AppTextStyles.code.copyWith(fontSize: 11, color: AppColors.primary)),
      ]),
    );
  }

  Widget _hash(Map<String, dynamic> d) {
    return Column(children: [
      for (final b in asList(d['buckets']))
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              Container(
                width: 34,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: BorderRadius.circular(10)),
                child: Text(str(asMap(b)['i']), style: AppTextStyles.code.copyWith(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
              for (final it in asList(asMap(b)['items'])) ...[
                const Icon(Icons.arrow_forward_rounded, size: 15, color: AppColors.textHint),
                cell(str(asMap(it)['v']), str(asMap(it)['s']), w: 78, h: 38),
              ],
            ]),
          ),
        ),
    ]);
  }

  Widget _bars(Map<String, dynamic> d) {
    return Column(children: [
      for (final b in asList(d['bars']))
        () {
          final m = asMap(b);
          final v = ((m['value'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
          final c = stateColor(str(m['s']).isEmpty ? 'compare' : str(m['s']));
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              SizedBox(width: 74, child: Text(str(m['label']), style: AppTextStyles.code.copyWith(fontSize: 11.5))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: v),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) => LinearProgressIndicator(value: t, minHeight: 12, backgroundColor: AppColors.inputFill, valueColor: AlwaysStoppedAnimation(c)),
                  ),
                ),
              ),
              if (str(m['text']).isNotEmpty) SizedBox(width: 66, child: Text(str(m['text']), textAlign: TextAlign.right, style: AppTextStyles.caption.copyWith(fontSize: 11))),
            ]),
          );
        }(),
    ]);
  }
}

class _Tree extends StatelessWidget {
  final Map<String, dynamic> def;
  const _Tree({required this.def});

  @override
  Widget build(BuildContext context) {
    final nodes = {for (final n in asList(def['nodes'])) str(asMap(n)['id']): asMap(n)};
    if (nodes.isEmpty) return const SizedBox.shrink();
    final rootId = str(asMap(asList(def['nodes']).first)['id']);
    final pos = <String, Offset>{}; // x = in-order index, y = depth
    var counter = 0;
    var maxDepth = 0;
    void walk(String? id, int depth) {
      if (id == null || id.isEmpty || !nodes.containsKey(id)) return;
      walk(str(nodes[id]!['l']), depth + 1);
      final x = counter++;
      pos[id] = Offset(x.toDouble(), depth.toDouble());
      if (depth > maxDepth) maxDepth = depth;
      walk(str(nodes[id]!['r']), depth + 1);
    }

    walk(rootId, 0);
    final cols = counter;
    return LayoutBuilder(builder: (context, box) {
      const nodeW = 40.0;
      final w = box.maxWidth;
      final h = (maxDepth + 1) * 62.0;
      Offset center(String id) {
        final p = pos[id]!;
        return Offset((p.dx + 0.5) / cols * w, p.dy * 62 + nodeW / 2);
      }

      return SizedBox(
        height: h,
        child: Stack(children: [
          CustomPaint(
              size: Size(w, h),
              painter: _EdgePainter([
                for (final e in nodes.entries)
                  for (final child in [str(e.value['l']), str(e.value['r'])])
                    if (child.isNotEmpty && pos.containsKey(child) && pos.containsKey(e.key)) (center(e.key), center(child), str(nodes[child]!['s'])),
              ])),
          for (final e in pos.entries)
            Positioned(
              left: center(e.key).dx - nodeW / 2,
              top: center(e.key).dy - nodeW / 2,
              child: _Block.cell(str(nodes[e.key]!['v']), str(nodes[e.key]!['s']), w: nodeW, h: nodeW),
            ),
        ]),
      );
    });
  }
}

class _Graph extends StatelessWidget {
  final Map<String, dynamic> def;
  const _Graph({required this.def});

  @override
  Widget build(BuildContext context) {
    final nodes = asList(def['nodes']).map(asMap).toList();
    final byId = {for (final n in nodes) str(n['id']): n};
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      const h = 240.0;
      const r = 20.0;
      Offset at(String id) {
        final n = byId[id]!;
        return Offset(((n['x'] as num?)?.toDouble() ?? 0.5) * (w - 2 * r) + r, ((n['y'] as num?)?.toDouble() ?? 0.5) * (h - 2 * r) + r);
      }

      final edges = asList(def['edges']).map(asMap).where((e) => byId.containsKey(str(e['a'])) && byId.containsKey(str(e['b']))).toList();
      return SizedBox(
        height: h,
        child: Stack(children: [
          CustomPaint(
            size: Size(w, h),
            painter: _EdgePainter([for (final e in edges) (at(str(e['a'])), at(str(e['b'])), str(e['s']))],
                weights: [for (final e in edges) str(e['w'])], directed: def['directed'] == true),
          ),
          for (final n in nodes)
            Positioned(
              left: at(str(n['id'])).dx - r,
              top: at(str(n['id'])).dy - r,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _Block.cell(str(n['id']), str(n['s']), w: r * 2, h: r * 2),
                if (str(n['note']).isNotEmpty) Text(str(n['note']), style: AppTextStyles.code.copyWith(fontSize: 10, color: AppColors.xp)),
              ]),
            ),
        ]),
      );
    });
  }
}

class _EdgePainter extends CustomPainter {
  final List<(Offset, Offset, String)> edges;
  final List<String>? weights;
  final bool directed;
  _EdgePainter(this.edges, {this.weights, this.directed = false});

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < edges.length; i++) {
      final (a, b, st) = edges[i];
      final active = stateIsActive(st);
      final c = active ? stateColor(st) : AppColors.borderLight;
      canvas.drawLine(
          a,
          b,
          Paint()
            ..color = st == 'dim' ? AppColors.border : c
            ..strokeWidth = active ? 3 : 1.6
            ..strokeCap = StrokeCap.round);
      if (directed) {
        final dir = (b - a);
        if (dir.distance > 0) {
          final u = dir / dir.distance;
          final tip = b - u * 22;
          final n = Offset(-u.dy, u.dx);
          canvas.drawPath(
              Path()
                ..moveTo(tip.dx, tip.dy)
                ..lineTo((tip - u * 9 + n * 5).dx, (tip - u * 9 + n * 5).dy)
                ..lineTo((tip - u * 9 - n * 5).dx, (tip - u * 9 - n * 5).dy)
                ..close(),
              Paint()..color = c);
        }
      }
      final w = weights != null && i < weights!.length ? weights![i] : '';
      if (w.isNotEmpty) {
        final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
        final tp = TextPainter(
            text: TextSpan(text: w, style: AppTextStyles.code.copyWith(fontSize: 11, color: AppColors.xp, fontWeight: FontWeight.w800)), textDirection: TextDirection.ltr)
          ..layout();
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: mid, width: tp.width + 8, height: tp.height + 2), const Radius.circular(6)), Paint()..color = AppColors.background);
        tp.paint(canvas, mid - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) => true;
}

class _Gantt extends StatelessWidget {
  final Map<String, dynamic> def;
  const _Gantt({required this.def});

  @override
  Widget build(BuildContext context) {
    final max = ((def['max'] as num?)?.toDouble() ?? 10).clamp(1.0, 1000.0);
    final time = (def['time'] as num?)?.toDouble();
    return LayoutBuilder(builder: (context, box) {
      final labelW = 54.0;
      final w = box.maxWidth - labelW;
      final lanes = asList(def['lanes']).map(asMap).toList();
      return Column(children: [
        for (final lane in lanes)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              SizedBox(width: labelW, child: Text(str(lane['name']), style: AppTextStyles.code.copyWith(fontSize: 11.5, fontWeight: FontWeight.w800))),
              SizedBox(
                width: w,
                height: 38,
                child: Stack(children: [
                  Container(decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(8))),
                  for (final b in asList(lane['blocks']).map(asMap))
                    Positioned(
                      left: ((b['start'] as num?)?.toDouble() ?? 0) / max * w,
                      width: (((b['len'] as num?)?.toDouble() ?? 1) / max * w - 2).clamp(4.0, w),
                      top: 3,
                      bottom: 3,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: stateColor(str(b['s']).isEmpty ? 'compare' : str(b['s'])).withOpacity(0.85), borderRadius: BorderRadius.circular(6)),
                        child: Text(str(b['label']),
                            overflow: TextOverflow.clip, style: AppTextStyles.code.copyWith(fontSize: 11, color: AppColors.onAccent, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  if (time != null) Positioned(left: time / max * w - 1, top: 0, bottom: 0, child: Container(width: 2, color: AppColors.primary)),
                ]),
              ),
            ]),
          ),
        Padding(
          padding: EdgeInsets.only(left: labelW),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('0', style: AppTextStyles.caption.copyWith(fontSize: 10)),
            if (time != null) Text('t = ${time.toInt()}', style: AppTextStyles.code.copyWith(fontSize: 10.5, color: AppColors.primary)),
            Text('${max.toInt()}', style: AppTextStyles.caption.copyWith(fontSize: 10))
          ]),
        ),
      ]);
    });
  }
}
