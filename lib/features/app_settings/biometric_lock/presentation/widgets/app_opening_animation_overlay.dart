import 'package:flutter/material.dart';
import 'package:trace/core/theme/typography.dart';
import 'package:trace/core/utils/useful_extension.dart';

class AppOpeningAnimationOverlay extends StatefulWidget {
  const AppOpeningAnimationOverlay({required this.onCompleted, super.key});

  final VoidCallback onCompleted;

  @override
  State<AppOpeningAnimationOverlay> createState() =>
      _AppOpeningAnimationOverlayState();
}

class _AppOpeningAnimationOverlayState extends State<AppOpeningAnimationOverlay>
    with
        SingleTickerProviderStateMixin,
        LateInitMixin<AppOpeningAnimationOverlay> {
  static const _wordmark = 'Trace';

  late final AnimationController _controller;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _iconScale;
  late final Animation<double> _overlayOpacity;
  bool _completedWithoutAnimation = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _iconOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.36, curve: Curves.easeOutCubic),
    );
    _iconScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.04, 0.34, curve: Curves.easeOutBack),
      ),
    );
    _overlayOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.84, 1, curve: Curves.easeOutCubic),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onCompleted();
      }
    });

  }

  @override
  void lateInitState() {
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      if (!_completedWithoutAnimation) {
        _completedWithoutAnimation = true;
        Future<void>.microtask(() {
          if (mounted) {
            widget.onCompleted();
          }
        });
      }
      return Positioned.fill(child: ColoredBox(color: context.cs.surface));
    }

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(opacity: _overlayOpacity.value, child: child);
        },
        child: Material(
          color: context.cs.surface,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [context.cs.surface, context.cs.surfaceContainerLowest],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _iconOpacity,
                      child: ScaleTransition(
                        scale: _iconScale,
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            color: context.cs.primaryContainer,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: context.cs.shadow.withValues(
                                  alpha: 0.14,
                                ),
                                blurRadius: 28,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Image.asset(
                            'assets/icon/trace_icon_foreground_v2.png',
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_wordmark.length, (index) {
                        final start = 0.34 + (index * 0.08);
                        final end = (start + 0.18).clamp(0.0, 0.9);
                        final opacity = CurvedAnimation(
                          parent: _controller,
                          curve: Interval(
                            start,
                            end,
                            curve: Curves.easeOutCubic,
                          ),
                        );
                        final slide =
                            Tween<Offset>(
                              begin: const Offset(-0.22, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _controller,
                                curve: Interval(
                                  start,
                                  end,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                            );

                        return FadeTransition(
                          opacity: opacity,
                          child: SlideTransition(
                            position: slide,
                            child: Text(
                              _wordmark[index],
                              style: context.tt.headlineMedium?.copyWith(
                                fontFamily: AppTypography.fontFamily,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: context.cs.onSurface,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
