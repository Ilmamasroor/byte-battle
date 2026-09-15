import 'package:flutter/material.dart';

/// The 4 states every button in the "Button Styles (Quick Reference)"
/// section supports: Default, Hover, Pressed, Disabled.
enum ButtonInteractionState { normal, hover, pressed, disabled }

/// Wraps [builder] with pointer/tap tracking so any button widget can
/// react to Default / Hover / Pressed / Disabled without repeating the
/// gesture-handling boilerplate. Hover only fires on mouse-driven
/// platforms (web/desktop) — on touch it simply never triggers, which is
/// expected mobile behaviour.
class InteractiveButtonBuilder extends StatefulWidget {
  final bool disabled;
  final VoidCallback? onTap;
  final Widget Function(BuildContext context, ButtonInteractionState state)
      builder;

  const InteractiveButtonBuilder({
    super.key,
    required this.builder,
    this.onTap,
    this.disabled = false,
  });

  @override
  State<InteractiveButtonBuilder> createState() =>
      _InteractiveButtonBuilderState();
}

class _InteractiveButtonBuilderState extends State<InteractiveButtonBuilder> {
  bool _hovering = false;
  bool _pressed = false;

  ButtonInteractionState get _state {
    if (widget.disabled) return ButtonInteractionState.disabled;
    if (_pressed) return ButtonInteractionState.pressed;
    if (_hovering) return ButtonInteractionState.hover;
    return ButtonInteractionState.normal;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.disabled
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) {
        if (!widget.disabled) setState(() => _hovering = true);
      },
      onExit: (_) {
        if (!widget.disabled) setState(() => _hovering = false);
      },
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
        onTapCancel: widget.disabled ? null : () => setState(() => _pressed = false),
        onTapUp: widget.disabled ? null : (_) => setState(() => _pressed = false),
        onTap: widget.disabled ? null : widget.onTap,
        child: widget.builder(context, _state),
      ),
    );
  }
}
