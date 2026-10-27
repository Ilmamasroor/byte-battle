import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../contract/viz_contract.dart';
import '../engine/playback_controller.dart';
import 'orbit_camera.dart';
import 'scene_painter.dart';
import 'scene_spec.dart';
import 'scene_tween.dart';

/// The 3D view of a timeline at the controller's current position.
///
/// It draws, animates between frames, and lets the learner orbit, zoom and select. It never decides what is
/// true: the frame comes from the timeline, the position from the controller, and the camera is its own state,
/// so moving the camera cannot change playback and seeking cannot move the camera.
class VizViewport extends StatefulWidget {
  final VizTimeline timeline;
  final VizPlaybackController controller;
  final Set<VizInteraction> interactions;
  final String? selectedId;
  final ValueChanged<String?>? onSelect;

  /// Called once if the timeline or the painter throws, so the caller can show its fallback.
  final void Function(Object error)? onFailure;
  final double height;

  const VizViewport({
    super.key,
    required this.timeline,
    required this.controller,
    this.interactions = const {VizInteraction.orbit, VizInteraction.zoom, VizInteraction.select, VizInteraction.replay},
    this.selectedId,
    this.onSelect,
    this.onFailure,
    this.height = 340,
  });

  @override
  State<VizViewport> createState() => _VizViewportState();
}

class _VizViewportState extends State<VizViewport> with TickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
  late final AnimationController _camAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late OrbitCamera _camera;
  OrbitCamera? _camFrom, _camTo;
  late OrbitCamera _home;
  bool _cameraTouched = false;
  double _aspect = 1.4;
  SceneSpec _from = SceneSpec.empty;
  SceneSpec _to = SceneSpec.empty;
  int _position = 0;
  int _nonce = 0;
  Object? _failure;
  bool _reported = false;
  double _gestureStartDistance = 12;

  @override
  void initState() {
    super.initState();
    _nonce = widget.controller.replayNonce;
    _loadTimeline(initial: true);
    widget.controller.addListener(_onController);
    _camAnim.addListener(_onCamTick);
  }

  @override
  void didUpdateWidget(VizViewport old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
    }
    if (!identical(old.timeline, widget.timeline)) {
      _loadTimeline(initial: true);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    _anim.dispose();
    _camAnim.dispose();
    super.dispose();
  }

  VizTimeline get _tl => widget.timeline;

  SceneSpec? _sceneAt(int p) {
    try {
      final s = _tl.frameAt(p.clamp(0, _tl.length - 1)).scene;
      s.validate();
      return s;
    } catch (e) {
      _fail(e);
      return null;
    }
  }

  void _fail(Object e) {
    _failure = e;
    if (_reported) return;
    _reported = true;
    // Defer: this can run while building or painting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onFailure?.call(e);
    });
  }

  /// A new timeline (lesson, variant or input changed): drop every trace of the old one.
  void _loadTimeline({required bool initial}) {
    _failure = null;
    _reported = false;
    _anim.stop();
    _position = widget.controller.position;
    _to = _sceneAt(_position) ?? SceneSpec.empty;
    _from = _to;
    _cameraTouched = false;
    _home = _computeHome();
    _camera = _home.copy();
    _camAnim.stop();
  }

  OrbitCamera _computeHome() {
    SceneBounds bounds;
    try {
      bounds = _tl.bounds;
    } catch (e) {
      _fail(e);
      bounds = SceneBounds.unit;
    }
    return OrbitCamera.fitting(bounds, hint: _tl.cameraHint, aspect: _aspect);
  }

  bool get _reduced => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _onController() {
    final c = widget.controller;
    final p = c.position;
    final replay = c.replayNonce != _nonce;
    _nonce = c.replayNonce;
    if (p == _position && !replay) return;
    final scene = _sceneAt(p);
    if (scene == null) {
      setState(() {});
      return;
    }
    final jump = (p - _position).abs() > 1;
    final fromScene = replay ? (_sceneAt(p - 1) ?? _currentScene()) : _currentScene();
    _position = p;
    if (_reduced) {
      _from = scene;
      _to = scene;
      _anim.value = 1;
      setState(() {});
      return;
    }
    _from = fromScene;
    _to = scene;
    _anim.duration = Duration(milliseconds: ((jump ? 320 : 560) / c.speed).round().clamp(120, 900));
    _anim.forward(from: 0);
    setState(() {});
  }

  SceneSpec _currentScene() => SceneTween.lerp(_from, _to, Curves.easeInOutCubic.transform(_anim.value));

  // ---- camera

  void _onCamTick() {
    if (_camFrom == null || _camTo == null) return;
    _camera.setFrom(OrbitCamera.lerp(_camFrom!, _camTo!, Curves.easeInOut.transform(_camAnim.value)));
    setState(() {});
  }

  void resetCamera() {
    _cameraTouched = false;
    _home = _computeHome();
    if (_reduced) {
      setState(() => _camera.setFrom(_home));
      return;
    }
    _camFrom = _camera.copy();
    _camTo = _home;
    _camAnim.forward(from: 0);
  }

  void _zoom(double f) => setState(() {
        _cameraTouched = true;
        _camera.zoom(f);
      });

  // ---- gestures

  void _onScaleStart(ScaleStartDetails d) {
    _gestureStartDistance = _camera.distance;
    _camAnim.stop();
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final can = widget.interactions;
    setState(() {
      if (d.pointerCount >= 2 && can.contains(VizInteraction.zoom)) {
        _cameraTouched = true;
        _camera.distance = (_gestureStartDistance / d.scale).clamp(OrbitCamera.minDistance, OrbitCamera.maxDistance);
      }
      if (can.contains(VizInteraction.orbit) && d.focalPointDelta != Offset.zero) {
        _cameraTouched = true;
        _camera.orbit(-d.focalPointDelta.dx * 0.008, d.focalPointDelta.dy * 0.006);
      }
    });
  }

  void _onTap(Offset local, Size size) {
    if (!widget.interactions.contains(VizInteraction.select)) return;
    final id = ScenePainter.pick(_currentScene(), _camera, size, local);
    widget.onSelect?.call(id == widget.selectedId ? null : id);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = _reduced;
    final can = widget.interactions;
    if (_failure != null) {
      // The shell swaps in its fallback after this frame; until then show a calm placeholder, not a broken scene.
      return SizedBox(height: widget.height, child: const Center(child: Text('Switching to the flat view...', style: TextStyle(color: AppColors.textHint))));
    }
    return Semantics(
      container: true,
      label: '3D visualization. ${_safeExplanation()}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
            gradient: const RadialGradient(center: Alignment(0, -0.3), radius: 1.1, colors: [Color(0xFF1F1B2C), Color(0xFF0B0A10)]),
          ),
          child: LayoutBuilder(builder: (context, box) {
            final size = Size(box.maxWidth, box.maxHeight);
            final aspect = size.width / math.max(1, size.height);
            if ((aspect - _aspect).abs() > 0.05) {
              _aspect = aspect;
              if (!_cameraTouched && !_camAnim.isAnimating) {
                _home = _computeHome();
                _camera = _home.copy();
              }
            }
            return Stack(children: [
              Positioned.fill(
                child: Listener(
                  onPointerSignal: (e) {
                    if (e is PointerScrollEvent && can.contains(VizInteraction.zoom)) _zoom(e.scrollDelta.dy > 0 ? 1.1 : 0.9);
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: _onScaleUpdate,
                    onTapUp: (d) => _onTap(d.localPosition, size),
                    child: AnimatedBuilder(
                      animation: _anim,
                      builder: (context, _) {
                        final scene = reduced ? _to : _currentScene();
                        final sel = widget.selectedId;
                        final selNode = sel == null ? null : _to.node(sel);
                        final hi = selNode == null ? const <String>{} : {selNode.id, ...selNode.related};
                        return CustomPaint(
                          size: size,
                          painter: ScenePainter(scene: scene, camera: _camera.copy(), highlighted: hi, selectedId: selNode?.id, onError: _fail),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (can.contains(VizInteraction.zoom)) ...[
                    _RoundButton(icon: Icons.add_rounded, tooltip: 'Zoom in', onTap: () => _zoom(0.8)),
                    const SizedBox(height: 6),
                    _RoundButton(icon: Icons.remove_rounded, tooltip: 'Zoom out', onTap: () => _zoom(1.25)),
                    const SizedBox(height: 6),
                  ],
                  if (can.contains(VizInteraction.orbit)) _RoundButton(icon: Icons.center_focus_strong_rounded, tooltip: 'Reset camera', onTap: resetCamera),
                  if (can.contains(VizInteraction.replay)) ...[
                    const SizedBox(height: 6),
                    _RoundButton(icon: Icons.replay_rounded, tooltip: 'Replay this step', onTap: widget.controller.replay),
                  ],
                ]),
              ),
              if (can.contains(VizInteraction.orbit))
                const Positioned(
                    left: 12, bottom: 8, child: Text('drag to orbit  -  pinch or scroll to zoom  -  tap to inspect', style: TextStyle(fontSize: 10, color: AppColors.textHint))),
            ]);
          }),
        ),
      ),
    );
  }

  String _safeExplanation() {
    try {
      return _tl.frameAt(_position.clamp(0, _tl.length - 1)).explanation.text;
    } catch (_) {
      return '';
    }
  }

  /// For tests: the camera as the painter last received it.
  @visibleForTesting
  OrbitCamera get debugCamera => _camera;
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.surface.withOpacity(0.85), shape: BoxShape.circle, border: Border.all(color: AppColors.borderLight)),
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
