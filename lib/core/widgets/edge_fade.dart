import 'package:flutter/material.dart';

/// Затухание у краёв горизонтального списка: только с той стороны, где есть скрытая часть.
class EdgeFade extends StatefulWidget {
  const EdgeFade({super.key, required this.child, this.extent = 28});

  final Widget child;

  final double extent;

  @override
  State<EdgeFade> createState() => _EdgeFadeState();
}

class _EdgeFadeState extends State<EdgeFade> {
  // Сила затухания слева и справа: 0 — нет, 1 — край полностью прозрачен.
  double _left = 0;
  double _right = 0;

  bool _onNotification(Notification notification) {
    final ScrollMetrics metrics;
    if (notification is ScrollMetricsNotification) {
      metrics = notification.metrics;
    } else if (notification is ScrollNotification) {
      metrics = notification.metrics;
    } else {
      return false;
    }
    if (metrics.axis != Axis.horizontal) return false;

    final left = (metrics.pixels / widget.extent).clamp(0.0, 1.0);
    final right = ((metrics.maxScrollExtent - metrics.pixels) / widget.extent)
        .clamp(0.0, 1.0);
    if (left != _left || right != _right) {
      setState(() {
        _left = left;
        _right = right;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<Notification>(
      onNotification: _onNotification,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) {
          final fade = (widget.extent / rect.width).clamp(0.0, 0.5);
          return LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 1 - _left),
              Colors.black,
              Colors.black,
              Colors.black.withValues(alpha: 1 - _right),
            ],
            stops: [0, fade, 1 - fade, 1],
          ).createShader(rect);
        },
        child: widget.child,
      ),
    );
  }
}
