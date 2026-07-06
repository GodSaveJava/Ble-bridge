import 'package:flutter/material.dart';

/// A premium, silky smooth bouncing animation wrapper for cards and buttons.
/// Shrinks slightly when pressed down, giving a tactile, high-end feel.
class PremiumBouncingWrapper extends StatefulWidget {
  const PremiumBouncingWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.97,
    this.duration = const Duration(milliseconds: 150),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;

  @override
  State<PremiumBouncingWrapper> createState() => _PremiumBouncingWrapperState();
}

class _PremiumBouncingWrapperState extends State<PremiumBouncingWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
