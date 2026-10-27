import 'dart:math' as math;
import 'dart:ui' show PathMetric;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import 'stage_common.dart';

/// "Inside your computer", drawn like the real thing: a CPU chip with pins and glowing cores, a data bus with
/// packets moving along it, a RAM module whose stack frames and heap objects carry memory addresses, and animated
/// arrows from a reference on the stack to the object it points at. Changed values flash, new frames and objects pop
/// in, garbage fades. A step only has to say which parts are lit; the stage animates the difference from the
/// previous step.
class ComputerStage extends StatefulWidget {
  final Map<String, dynamic> s;
  final Map<String, dynamic>? prev;
  final int stepIndex;
  const ComputerStage({super.key, required this.s, this.prev, this.stepIndex = 0});

  @override
  State<ComputerStage> createState() => _ComputerStageState();
}

class _Arrow {
  final Offset from;
  final Offset to;
  const _Arrow(this.from, this.to);
  bool near(_Arrow o) => (from - o.from).distance < 1.5 && (to - o.to).distance < 1.5;
}

class _ComputerStageState extends State<ComputerStage> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  final GlobalKey _ramKey = GlobalKey();
  final Map<String, GlobalKey> _refKeys = {};
  final Map<String, GlobalKey> _objKeys = {};
  List<_Arrow> _arrows = const [];

  Map<String, dynamic> get s => widget.s;
  Map<String, dynamic> get prev => widget.prev ?? const {};

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  bool _lit(String id) => asList(s['highlight']).map(str).contains(id);
  bool get _flowing => asList(s['flow']).isNotEmpty;

  String get _doing => str(asMap(s['cpu'])['doing']).toLowerCase();

  /// Reads from memory (data flows up into the CPU) or writes to it (data flows down)?
  bool get _reading => RegExp(r'\b(read|load|fetch|follow|look ?up|dereference)\b').hasMatch(_doing) && !RegExp(r'\b(write|store|assign|set)\b').hasMatch(_doing);

  /// The label on the bus, only when the instruction clearly says CPU <-> RAM (not "OS reads from disk" and the like).
  String? get _busLabel {
    if (!_flowing) return null;
    final d = _doing;
    if (d.contains('disk') || d.startsWith('os') || d.contains('network') || d.contains('packet')) return null;
    if (_reading) return 'READ';
    if (RegExp(r'\b(write|store|assign|set|execute|add|increment|compute)\b').hasMatch(d)) return 'WRITE';
    return null;
  }

  // ── addresses, so memory feels like memory ───────────────────────────
  static String _hex(int v) => '0x${v.toRadixString(16).toUpperCase().padLeft(4, '0')}';

  @override
  Widget build(BuildContext context) {
    final cpu = asMap(s['cpu']);
    final stack = asList(s['stack']);
    final heap = asList(s['heap']);
    final disk = asList(s['disk']);
    final grid = asMap(s['grid']);
    final panels = asList(s['panels']);
    final net = asMap(s['net']);
    final console = asList(s['console']);
    final hasRam = stack.isNotEmpty || heap.isNotEmpty || grid.isNotEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureArrows());

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0A10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: CustomPaint(
        painter: _BoardPainter(),
        child: Column(
          children: [
            if (s['code'] is Map) ...[CodePanel(code: asMap(s['code'])), const SizedBox(height: 10)],
            if (cpu.isNotEmpty) _cpu(cpu),
            if (cpu.isNotEmpty && hasRam) _Bus(active: _flowing, up: _reading, color: AppColors.primary, label: _busLabel),
            if (hasRam) _ram(stack, heap, grid),
            if (disk.isNotEmpty || net.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (disk.isNotEmpty) Expanded(child: _disk(disk)),
                if (disk.isNotEmpty && net.isNotEmpty) const SizedBox(width: 10),
                if (net.isNotEmpty) Expanded(child: _net(net)),
              ]),
            ],
            for (var i = 0; i < panels.length; i++) ...[const SizedBox(height: 10), _panel(asMap(panels[i]), _lit('panel:$i'))],
            if (console.isNotEmpty) ...[const SizedBox(height: 10), _console(console)],
          ],
        ),
      ),
    );
  }

  // ── CPU ──────────────────────────────────────────────────────────────
  Widget _cpu(Map<String, dynamic> cpu) {
    final lit = _lit('cpu');
    final regs = asMap(cpu['regs']);
    final prevRegs = asMap(asMap(prev['cpu'])['regs']);
    final cores = asList(cpu['cores']);
    final doing = str(cpu['doing']);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = lit ? 0.35 + 0.35 * _pulse.value : 0.0;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF14121B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: lit ? AppColors.primary : AppColors.border, width: lit ? 1.8 : 1),
            boxShadow: lit ? [BoxShadow(color: AppColors.primary.withOpacity(glow), blurRadius: 26, spreadRadius: -4)] : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Chip(cores: cores, lit: lit, pulse: _pulse.value),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NOW EXECUTING', style: AppTextStyles.eyebrow.copyWith(fontSize: 9.5, color: lit ? AppColors.primary : AppColors.textHint)),
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.border)),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: doing.isEmpty ? 'idle' : doing, style: AppTextStyles.code.copyWith(fontSize: 11.5, color: AppColors.primaryLight, height: 1.35)),
                        TextSpan(text: _pulse.value > 0.5 ? ' |' : '  ', style: AppTextStyles.code.copyWith(fontSize: 11.5, color: AppColors.primary)),
                      ])),
                    ),
                    if (regs.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        for (final e in regs.entries) _Reg(name: e.key, value: str(e.value), changed: prevRegs.isNotEmpty && str(prevRegs[e.key]) != str(e.value)),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── RAM ──────────────────────────────────────────────────────────────
  Widget _ram(List<dynamic> stack, List<dynamic> heap, Map<String, dynamic> grid) {
    final lit = _lit('ram') || _lit('stack') || _lit('heap');
    // fresh keys for this build's references/objects
    final liveRef = <String>{};
    final liveObj = <String>{};
    for (var fi = 0; fi < stack.length; fi++) {
      for (final e in asMap(asMap(stack[fi])['vars']).entries) {
        if (_refTarget(str(e.value)) != null) liveRef.add('$fi.${e.key}');
      }
    }
    for (final o in heap) {
      liveObj.add(str(asMap(o)['id']));
    }
    _refKeys.removeWhere((k, _) => !liveRef.contains(k));
    _objKeys.removeWhere((k, _) => !liveObj.contains(k));

    return Container(
      key: _ramKey,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0E2A33), Color(0xFF0F1A22)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lit ? AppColors.accentCyan : AppColors.accentCyan.withOpacity(0.35), width: lit ? 1.8 : 1),
        boxShadow: lit ? [BoxShadow(color: AppColors.accentCyan.withOpacity(0.25), blurRadius: 24, spreadRadius: -6)] : null,
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.developer_board_rounded, size: 15, color: AppColors.accentCyan),
                const SizedBox(width: 6),
                Text('MEMORY (RAM)', style: AppTextStyles.eyebrow.copyWith(fontSize: 10, color: AppColors.accentCyan)),
              ]),
              const SizedBox(height: 10),
              if (stack.isNotEmpty || heap.isNotEmpty)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 11, child: _stack(stack)),
                  const SizedBox(width: 26),
                  Expanded(flex: 10, child: _heap(heap)),
                ]),
              if (grid.isNotEmpty) ...[
                if (stack.isNotEmpty || heap.isNotEmpty) const SizedBox(height: 12),
                _grid(grid),
              ],
              const SizedBox(height: 10),
              // the gold contacts along the bottom of a memory stick
              CustomPaint(size: const Size(double.infinity, 12), painter: _ContactsPainter()),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                key: ValueKey('arrows_${widget.stepIndex}_${_arrows.length}'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => CustomPaint(painter: _ArrowPainter(_arrows, t)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "-> s1" / "-> #obj1" -> "s1"
  static String? _refTarget(String v) {
    final m = RegExp(r'^->\s*#?([A-Za-z0-9_]+)').firstMatch(v.trim());
    return m?.group(1);
  }

  Widget _stack(List<dynamic> frames) {
    final prevFrames = asList(prev['stack']).map((f) => str(asMap(f)['frame'])).toList();
    final prevVars = {
      for (final f in asList(prev['stack']))
        for (final e in asMap(asMap(f)['vars']).entries) '${asMap(f)['frame']}.${e.key}': str(e.value),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('STACK', style: AppTextStyles.eyebrow.copyWith(fontSize: 9.5, color: AppColors.accentCyan)),
          const SizedBox(width: 6),
          Icon(Icons.south_rounded, size: 11, color: AppColors.accentCyan.withOpacity(0.7)),
          Flexible(child: Text('newest on top', overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(fontSize: 9))),
        ]),
        const SizedBox(height: 6),
        if (frames.isEmpty) Text('empty', style: AppTextStyles.caption),
        for (var i = frames.length - 1; i >= 0; i--)
          () {
            final f = asMap(frames[i]);
            final name = str(f['frame']);
            final isNew = prev.isNotEmpty && !prevFrames.contains(name);
            final vars = asMap(f['vars']).entries.toList();
            final base = 0x7FF0 - i * 0x30;
            return _PopIn(
              key: ValueKey('frame_$name$i'),
              play: isNew,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentCyan.withOpacity(i == frames.length - 1 ? 0.8 : 0.4), width: i == frames.length - 1 ? 1.6 : 1),
                ),
                child: Column(children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.accentCyan.withOpacity(0.2), borderRadius: const BorderRadius.vertical(top: Radius.circular(11))),
                    child: Text(name, overflow: TextOverflow.ellipsis, style: AppTextStyles.code.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accentCyan)),
                  ),
                  if (vars.isEmpty) Padding(padding: const EdgeInsets.all(8), child: Text('no variables yet', style: AppTextStyles.caption.copyWith(fontSize: 10))),
                  for (var vi = 0; vi < vars.length; vi++)
                    _slot(
                      key: _refTarget(str(vars[vi].value)) != null ? (_refKeys['$i.${vars[vi].key}'] ??= GlobalKey()) : null,
                      addr: _hex(base - vi * 4),
                      name: vars[vi].key,
                      value: str(vars[vi].value),
                      changed: prev.isNotEmpty && prevVars['$name.${vars[vi].key}'] != str(vars[vi].value),
                    ),
                  const SizedBox(height: 3),
                ]),
              ),
            );
          }(),
      ],
    );
  }

  Widget _slot({GlobalKey? key, required String addr, required String name, required String value, required bool changed}) {
    final isRef = _refTarget(value) != null;
    final isText = value.startsWith('"');
    final color = isRef ? AppColors.orchid : (isText ? AppColors.success : AppColors.xp);
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(8, 3, 8, 0),
      child: Row(children: [
        SizedBox(
            width: 34,
            child: Text(addr.replaceFirst('0x', ''), maxLines: 1, overflow: TextOverflow.clip, style: AppTextStyles.code.copyWith(fontSize: 8.5, color: AppColors.textHint))),
        Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.code.copyWith(fontSize: 11, color: AppColors.textSecondary))),
        const SizedBox(width: 6),
        Flexible(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: _Flash(
              // a new value restarts the flash
              key: ValueKey('$name=$value'),
              play: changed,
              color: color,
              child: Container(
                constraints: const BoxConstraints(minWidth: 34),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: color.withOpacity(0.16), borderRadius: BorderRadius.circular(7), border: Border.all(color: color.withOpacity(0.7))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (isRef) Icon(Icons.link_rounded, size: 10, color: color),
                  if (isRef) const SizedBox(width: 2),
                  Flexible(
                      child: Text(isRef ? _refTarget(value)! : value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.code.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _heap(List<dynamic> objs) {
    final prevIds = asList(prev['heap']).map((o) => str(asMap(o)['id'])).toSet();
    final prevFields = {
      for (final o in asList(prev['heap']))
        for (final e in asMap(asMap(o)['fields']).entries) '${asMap(o)['id']}.${e.key}': str(e.value),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HEAP', style: AppTextStyles.eyebrow.copyWith(fontSize: 9.5, color: AppColors.orchid)),
        const SizedBox(height: 6),
        if (objs.isEmpty) Text('empty', style: AppTextStyles.caption),
        for (var oi = 0; oi < objs.length; oi++)
          () {
            final m = asMap(objs[oi]);
            final id = str(m['id']);
            final garbage = str(m['state']) == 'garbage';
            final fresh = prev.isNotEmpty && (!prevIds.contains(id) || str(m['state']) == 'new');
            final fields = asMap(m['fields']).entries.toList();
            return _PopIn(
              key: ValueKey('obj_$id'),
              play: fresh && !garbage,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: garbage ? 0.38 : 1,
                child: Container(
                  key: _objKeys[id] ??= GlobalKey(),
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.orchid.withOpacity(fresh ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: garbage ? AppColors.textHint : AppColors.orchid.withOpacity(fresh ? 1 : 0.55), width: fresh ? 1.8 : 1),
                    boxShadow: fresh ? [BoxShadow(color: AppColors.orchid.withOpacity(0.4), blurRadius: 16, spreadRadius: -4)] : null,
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.orchid.withOpacity(0.22), borderRadius: const BorderRadius.vertical(top: Radius.circular(11))),
                      child: Row(children: [
                        Expanded(
                            child: Text(str(m['type']),
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.code
                                    .copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.orchid, decoration: garbage ? TextDecoration.lineThrough : null))),
                        Text('@${_hex(0x2000 + oi * 0x40).replaceFirst('0x', '')}', style: AppTextStyles.code.copyWith(fontSize: 8.5, color: AppColors.textHint)),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(9, 4, 9, 7),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('#$id', style: AppTextStyles.code.copyWith(fontSize: 9, color: AppColors.textHint)),
                        for (final e in fields)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: _Flash(
                              key: ValueKey('$id.${e.key}=${e.value}'),
                              play: prev.isNotEmpty && prevFields['$id.${e.key}'] != str(e.value) && prevIds.contains(id),
                              color: AppColors.xp,
                              child: Text('${e.key} = ${str(e.value)}', style: AppTextStyles.code.copyWith(fontSize: 11, color: AppColors.textPrimary)),
                            ),
                          ),
                        if (garbage)
                          Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(children: [
                                const Icon(Icons.delete_sweep_rounded, size: 12, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text('no references: garbage', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(fontSize: 9.5)),
                                )
                              ])),
                      ]),
                    ),
                  ]),
                ),
              ),
            );
          }(),
      ],
    );
  }

  Widget _grid(Map<String, dynamic> grid) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (str(grid['title']).isNotEmpty) Text(str(grid['title']), style: AppTextStyles.caption),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final c in asList(grid['cells']))
          () {
            final m = asMap(c);
            final st = str(m['s']);
            final col = st == 'free' ? AppColors.textHint : (st == 'hot' ? AppColors.primary : (st == 'bad' ? AppColors.error : AppColors.accentCyan));
            return AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: st == 'free' ? Colors.black.withOpacity(0.3) : col.withOpacity(0.2),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: st == 'free' ? AppColors.border : col, width: st == 'hot' ? 2 : 1),
                boxShadow: st == 'hot' ? [BoxShadow(color: col.withOpacity(0.5), blurRadius: 14, spreadRadius: -3)] : null,
              ),
              child: Text(str(m['label']), style: AppTextStyles.code.copyWith(fontSize: 11, color: st == 'free' ? AppColors.textHint : AppColors.textPrimary)),
            );
          }(),
      ]),
    ]);
  }

  // ── disk, network, panels, console ───────────────────────────────────
  Widget _disk(List<dynamic> files) {
    final lit = _lit('disk');
    return _MiniCard(
      title: 'Disk',
      color: AppColors.xp,
      lit: lit,
      leading: lit
          ? RotationTransition(turns: _pulse, child: const Icon(Icons.album_rounded, size: 16, color: AppColors.xp))
          : const Icon(Icons.album_rounded, size: 16, color: AppColors.textHint),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final f in files)
          Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                const Icon(Icons.insert_drive_file_rounded, size: 12, color: AppColors.xp),
                const SizedBox(width: 5),
                Expanded(child: Text(str(f), overflow: TextOverflow.ellipsis, style: AppTextStyles.code.copyWith(fontSize: 11)))
              ])),
      ]),
    );
  }

  Widget _net(Map<String, dynamic> net) {
    final lit = _lit('net');
    return _MiniCard(
      title: str(net['label']).isEmpty ? 'Network' : str(net['label']),
      color: AppColors.success,
      lit: lit,
      leading: Icon(Icons.wifi_rounded, size: 16, color: lit ? AppColors.success : AppColors.textHint),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final p in asList(net['packets']))
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const Icon(Icons.mail_rounded, size: 12, color: AppColors.success),
              const SizedBox(width: 5),
              Expanded(child: Text(str(p), overflow: TextOverflow.ellipsis, style: AppTextStyles.code.copyWith(fontSize: 11))),
            ]),
          ),
      ]),
    );
  }

  Widget _panel(Map<String, dynamic> p, bool lit) {
    final rows = asList(p['rows']);
    final hl = asList(p['hl']).whereType<num>().map((e) => e.toInt()).toSet();
    return _MiniCard(
      title: str(p['title']),
      color: AppColors.primary,
      lit: lit || hl.isNotEmpty,
      leading: Icon(Icons.table_rows_rounded, size: 16, color: lit ? AppColors.primary : AppColors.textHint),
      child: Column(children: [
        for (var i = 0; i < rows.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
                color: hl.contains(i) ? AppColors.primary.withOpacity(0.22) : (i == 0 ? Colors.white.withOpacity(0.04) : Colors.transparent),
                borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              for (final c in asList(rows[i]))
                Expanded(
                    child: Text(str(c),
                        style: AppTextStyles.code.copyWith(
                            fontSize: 11.5, fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w400, color: hl.contains(i) ? AppColors.textPrimary : AppColors.textSecondary))),
            ]),
          ),
      ]),
    );
  }

  Widget _console(List<dynamic> lines) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _lit('console') ? AppColors.success : AppColors.border, width: _lit('console') ? 1.6 : 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            for (final c in [AppColors.error, AppColors.warning, AppColors.success])
              Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 5), decoration: BoxDecoration(color: c.withOpacity(0.8), shape: BoxShape.circle))
          ]),
          const SizedBox(height: 8),
          Text(r'$ java Main', style: AppTextStyles.code.copyWith(fontSize: 11.5, color: AppColors.textHint)),
          for (final l in lines) Text(str(l), style: AppTextStyles.code.copyWith(fontSize: 12, color: AppColors.success)),
        ]),
      );

  // ── measure arrows between a reference slot and its object ───────────
  void _measureArrows() {
    if (!mounted) return;
    final ramBox = _ramKey.currentContext?.findRenderObject();
    if (ramBox is! RenderBox || !ramBox.attached) return;
    final next = <_Arrow>[];
    for (final fe in _refKeys.entries) {
      final parts = fe.key.split('.');
      final fi = int.tryParse(parts.first);
      if (fi == null) continue;
      final stack = asList(s['stack']);
      if (fi >= stack.length) continue;
      final val = str(asMap(asMap(stack[fi])['vars'])[parts.sublist(1).join('.')]);
      final target = _refTarget(val);
      final srcBox = fe.value.currentContext?.findRenderObject();
      final dstBox = target == null ? null : _objKeys[target]?.currentContext?.findRenderObject();
      if (srcBox is! RenderBox || dstBox is! RenderBox || !srcBox.attached || !dstBox.attached) continue;
      final a = ramBox.globalToLocal(srcBox.localToGlobal(Offset(srcBox.size.width, srcBox.size.height / 2)));
      final b = ramBox.globalToLocal(dstBox.localToGlobal(Offset(0, math.min(dstBox.size.height / 2, 24))));
      next.add(_Arrow(a, b));
    }
    final same = next.length == _arrows.length && [for (var i = 0; i < next.length; i++) next[i].near(_arrows[i])].every((x) => x);
    if (!same) setState(() => _arrows = next);
  }
}

// ═════════════════════════════════════════════════════════════════════
// small pieces
// ═════════════════════════════════════════════════════════════════════

/// Scales/fades its child in once when [play] is true (a new stack frame or heap object appearing).
class _PopIn extends StatelessWidget {
  final bool play;
  final Widget child;
  const _PopIn({super.key, required this.play, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!play) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, t, c) => Opacity(opacity: t.clamp(0.0, 1.0), child: Transform.scale(scale: 0.88 + 0.12 * t, alignment: Alignment.topCenter, child: c)),
      child: child,
    );
  }
}

/// Briefly lights up its child's background in [color] when [play] (a value just changed).
class _Flash extends StatelessWidget {
  final bool play;
  final Color color;
  final Widget child;
  const _Flash({super.key, required this.play, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!play) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (context, t, c) => DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: color.withOpacity(0.75 * t), blurRadius: 14 * t + 1, spreadRadius: 2 * t)]),
        child: c,
      ),
      child: child,
    );
  }
}

class _Reg extends StatelessWidget {
  final String name;
  final String value;
  final bool changed;
  const _Reg({required this.name, required this.value, required this.changed});

  @override
  Widget build(BuildContext context) {
    return _Flash(
      key: ValueKey('$name=$value'),
      play: changed,
      color: AppColors.xp,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.xp.withOpacity(0.35))),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: '$name ', style: AppTextStyles.code.copyWith(fontSize: 10.5, color: AppColors.textHint)),
          TextSpan(text: value, style: AppTextStyles.code.copyWith(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.xp)),
        ])),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String title;
  final Color color;
  final bool lit;
  final Widget leading;
  final Widget child;
  const _MiniCard({required this.title, required this.color, required this.lit, required this.leading, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: lit ? color.withOpacity(0.12) : const Color(0xFF14121B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lit ? color : AppColors.border, width: lit ? 1.7 : 1),
        boxShadow: lit ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, spreadRadius: -6)] : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          leading,
          const SizedBox(width: 6),
          Expanded(child: Text(title.toUpperCase(), overflow: TextOverflow.ellipsis, style: AppTextStyles.eyebrow.copyWith(fontSize: 9.5, color: lit ? color : AppColors.textHint)))
        ]),
        const SizedBox(height: 8),
        child,
      ]),
    );
  }
}

/// A CPU die with pins on all four sides. With cores it shows a tile per core; with none, one glowing core.
class _Chip extends StatelessWidget {
  final List<dynamic> cores;
  final bool lit;
  final double pulse;
  const _Chip({required this.cores, required this.lit, required this.pulse});

  @override
  Widget build(BuildContext context) {
    const size = 104.0;
    final count = cores.isEmpty ? 1 : cores.length.clamp(1, 4);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: const Size(size, size), painter: _ChipPainter(lit: lit, pulse: pulse)),
        SizedBox(
          width: 62,
          height: 62,
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: count == 1 ? 1 : 2,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            padding: EdgeInsets.zero,
            children: [
              for (var i = 0; i < count; i++)
                () {
                  final busy = cores.isEmpty ? lit : cores[i] != null;
                  final label = cores.isEmpty ? 'CPU' : (cores[i] == null ? 'idle' : str(cores[i]));
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: busy ? AppColors.primary.withOpacity(0.28 + 0.18 * pulse) : Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: busy ? AppColors.primary : AppColors.border),
                      boxShadow: busy ? [BoxShadow(color: AppColors.primary.withOpacity(0.5 * pulse), blurRadius: 10, spreadRadius: -2)] : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: FittedBox(
                          child:
                              Text(label, style: AppTextStyles.code.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: busy ? AppColors.textPrimary : AppColors.textHint))),
                    ),
                  );
                }(),
            ],
          ),
        ),
      ]),
    );
  }
}

class _ChipPainter extends CustomPainter {
  final bool lit;
  final double pulse;
  _ChipPainter({required this.lit, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final pin = Paint()..color = const Color(0xFFB8A27A);
    const n = 7;
    final die = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    for (var i = 0; i < n; i++) {
      final f = (i + 0.7) / (n + 0.4);
      final x = die.left + die.width * f;
      final y = die.top + die.height * f;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 1.8, 0, 3.6, 10), const Radius.circular(1)), pin);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 1.8, size.height - 10, 3.6, 10), const Radius.circular(1)), pin);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, y - 1.8, 10, 3.6), const Radius.circular(1)), pin);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 10, y - 1.8, 10, 3.6), const Radius.circular(1)), pin);
    }
    final body = RRect.fromRectAndRadius(die, const Radius.circular(10));
    canvas.drawRRect(
        body, Paint()..shader = const LinearGradient(colors: [Color(0xFF2A2735), Color(0xFF191722)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(die));
    canvas.drawRRect(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lit ? 2 : 1.2
          ..color = lit ? AppColors.primary.withOpacity(0.6 + 0.4 * pulse) : AppColors.borderLight);
    // a notch marking pin 1
    canvas.drawCircle(Offset(die.left + 8, die.top + 8), 2.2, Paint()..color = lit ? AppColors.primary : AppColors.textHint);
  }

  @override
  bool shouldRepaint(_ChipPainter old) => old.lit != lit || old.pulse != pulse;
}

/// The data bus: three thin traces with glowing packets moving along them (up = RAM to CPU, down = CPU to RAM).
class _Bus extends StatefulWidget {
  final bool active;
  final bool up;
  final Color color;
  final String? label;
  const _Bus({required this.active, required this.up, required this.color, this.label});

  @override
  State<_Bus> createState() => _BusState();
}

class _BusState extends State<_Bus> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(alignment: Alignment.center, children: [
          CustomPaint(size: const Size(double.infinity, 40), painter: _BusPainter(active: widget.active, up: widget.up, t: _c.value, color: widget.color)),
          if (widget.label != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(100), border: Border.all(color: widget.color)),
              child: Text(widget.label!, style: AppTextStyles.eyebrow.copyWith(fontSize: 9, color: widget.color)),
            ),
        ]),
      ),
    );
  }
}

class _BusPainter extends CustomPainter {
  final bool active;
  final bool up;
  final double t;
  final Color color;
  _BusPainter({required this.active, required this.up, required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    for (var lane = -1; lane <= 1; lane++) {
      final x = cx + lane * 14;
      canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          Paint()
            ..color = active ? color.withOpacity(0.45) : AppColors.border
            ..strokeWidth = 2);
      if (!active) continue;
      for (var k = 0; k < 2; k++) {
        final phase = (t + k * 0.5 + (lane + 1) * 0.17) % 1.0;
        final y = (up ? 1 - phase : phase) * size.height;
        canvas.drawCircle(
            Offset(x, y),
            3.6,
            Paint()
              ..color = color
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5));
        canvas.drawCircle(Offset(x, y), 2.4, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(_BusPainter old) => true;
}

class _ContactsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFB8A27A).withOpacity(0.9);
    const w = 5.0, gap = 3.0;
    for (var x = 0.0; x + w < size.width; x += w + gap) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 2, w, size.height - 2), const Radius.circular(1)), p);
    }
  }

  @override
  bool shouldRepaint(_ContactsPainter old) => false;
}

/// Faint circuit traces behind the whole machine.
class _BoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (var y = 24.0; y < size.height; y += 46) {
      final path = Path()
        ..moveTo(0, y)
        ..lineTo(size.width * 0.25, y)
        ..lineTo(size.width * 0.25 + 14, y + 14)
        ..lineTo(size.width * 0.6, y + 14)
        ..lineTo(size.width * 0.6 + 14, y)
        ..lineTo(size.width, y);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) => false;
}

/// Curved arrows from a reference on the stack to the heap object it points at, drawn on as they appear.
class _ArrowPainter extends CustomPainter {
  final List<_Arrow> arrows;
  final double t;
  _ArrowPainter(this.arrows, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final a in arrows) {
      final dx = (a.to.dx - a.from.dx).abs().clamp(30.0, 200.0) * 0.55;
      final path = Path()
        ..moveTo(a.from.dx, a.from.dy)
        ..cubicTo(a.from.dx + dx, a.from.dy, a.to.dx - dx, a.to.dy, a.to.dx, a.to.dy);
      final metrics = path.computeMetrics().toList();
      if (metrics.isEmpty) continue;
      final PathMetric m = metrics.first;
      final shown = m.extractPath(0, m.length * t);
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = AppColors.orchid.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = AppColors.orchid;
      canvas.drawPath(shown, glow);
      canvas.drawPath(shown, line);
      canvas.drawCircle(a.from, 3.2, Paint()..color = AppColors.orchid);
      if (t > 0.92) {
        final tan = m.getTangentForOffset(m.length)!;
        final dir = tan.vector;
        final tip = a.to;
        final n = Offset(-dir.dy, dir.dx);
        canvas.drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(tip.dx - dir.dx * 9 + n.dx * 5, tip.dy - dir.dy * 9 + n.dy * 5)
            ..lineTo(tip.dx - dir.dx * 9 - n.dx * 5, tip.dy - dir.dy * 9 - n.dy * 5)
            ..close(),
          Paint()..color = AppColors.orchid,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.t != t || old.arrows != arrows;
}
