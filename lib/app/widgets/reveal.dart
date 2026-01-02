import 'package:flutter/material.dart';

class Reveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Duration duration;
  final Curve curve;
  final Offset offset;

  const Reveal({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.duration = const Duration(milliseconds: 450),
    this.curve = Curves.easeOutCubic,
    this.offset = const Offset(0, 0.08),
  });

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.delayMs == 0) {
      _visible = true;
    } else {
      Future.delayed(Duration(milliseconds: widget.delayMs)).then((_) {
        if (!mounted) {
          return;
        }
        setState(() => _visible = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: widget.duration,
      curve: widget.curve,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : widget.offset,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}
