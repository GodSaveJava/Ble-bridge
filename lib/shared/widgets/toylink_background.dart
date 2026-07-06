import 'package:flutter/material.dart';

class ToyLinkBackground extends StatelessWidget {
  const ToyLinkBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFFFF1F7), Color(0xFFFFF8FC)],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -80,
            right: -40,
            child: _BlurCircle(
              size: 220,
              color: const Color(0xFFFFC3DC).withValues(alpha: 0.34),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: _BlurCircle(
              size: 260,
              color: const Color(0xFFFFD7E7).withValues(alpha: 0.30),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
