// lib/src/widgets/typing_indicator.dart
import 'package:flutter/material.dart';

/// A typing indicator that shows animated bubbles
/// to indicate that someone is typing or content is loading
class BubbleTypingIndicator extends StatefulWidget {
  /// Color of the bubbles
  final Color? color;

  /// Size of the bubbles
  final double bubbleSize;

  /// Spacing between bubbles
  final double spacing;

  /// Duration of the full animation cycle
  final Duration animationDuration;

  /// Number of bubbles to show
  final int bubbleCount;

  const BubbleTypingIndicator({
    super.key,
    this.color,
    this.bubbleSize = 8.0,
    this.spacing = 4.0,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.bubbleCount = 3,
  });

  @override
  State<BubbleTypingIndicator> createState() => _BubbleTypingIndicatorState();
}

class _BubbleTypingIndicatorState extends State<BubbleTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor =
        widget.color ?? Theme.of(context).colorScheme.primary.withOpacity(0.7);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        widget.bubbleCount,
        (index) => Padding(
          padding: EdgeInsets.only(
              right: index < widget.bubbleCount - 1 ? widget.spacing : 0),
          child: _buildAnimatedBubble(index, themeColor),
        ),
      ),
    );
  }

  Widget _buildAnimatedBubble(int index, Color color) {
    // Create a delay offset for each bubble (0.0 to 0.75)
    final delayFraction = index / (widget.bubbleCount * 1.5);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate current value with delay offset
        final animationValue = (_controller.value + delayFraction) % 1.0;

        // Create a custom curve effect
        double scale;
        double opacity;

        if (animationValue < 0.5) {
          // Grow and fade in (0.0 -> 0.5)
          final progress = animationValue / 0.5;
          scale = 0.5 + (progress * 0.5);
          opacity = 0.3 + (progress * 0.7);
        } else {
          // Shrink and fade out (0.5 -> 1.0)
          final progress = (animationValue - 0.5) / 0.5;
          scale = 1.0 - (progress * 0.5);
          opacity = 1.0 - (progress * 0.7);
        }

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: widget.bubbleSize,
              height: widget.bubbleSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
