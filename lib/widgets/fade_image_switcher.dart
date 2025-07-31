import 'dart:async';

import 'package:flutter/cupertino.dart';

class FadeImageSwitcher extends StatefulWidget {
  final List<String> images;
  final Duration fadeDuration;
  final Duration displayDuration;

  const FadeImageSwitcher({
    required this.images,
    this.fadeDuration = const Duration(seconds: 2),
    this.displayDuration = const Duration(seconds: 5),
    super.key,
  });

  @override
  State<FadeImageSwitcher> createState() => _FadeImageSwitcherState();
}

class _FadeImageSwitcherState extends State<FadeImageSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  int _bottomIndex = 0;
  int _topIndex = 1;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _bottomIndex = _topIndex;
          _topIndex = (_topIndex + 1) % widget.images.length;
          _controller.reset();
        });
      }
    });
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _startCycle();
  }

  void _startCycle() {
    _timer = Timer.periodic(widget.displayDuration, (_) => _startFade());
  }

  void _startFade() async {
    if (!_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(widget.images[_bottomIndex], fit: BoxFit.cover),
        FadeTransition(
          opacity: _animation,
          child: Image.asset(widget.images[_topIndex], fit: BoxFit.cover),
        ),
      ],
    );
  }
}
