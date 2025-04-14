import 'package:flutter/material.dart';
import 'package:pixelated_shimmer/pixelated_painter.dart';
import 'package:pixelated_shimmer/pixelation_utils.dart';

class PixelatedShimmer extends StatefulWidget {
  /// The provider for the image to load. If not provided, the widget will show a shimmer effect.
  final ImageProvider? imageProvider;

  /// Whether to show the shimmer effect when no image is provided.
  /// Defaults to true.
  final bool showShimmer;

  /// The size of each square block in the pixelated version.
  /// Smaller values mean more detail but higher computation cost.
  final double pixelSize;

  /// The base color for the shimmer gradient.
  final Color shimmerBaseColor;

  /// The highlight color for the shimmer gradient.
  final Color shimmerHighlightColor;

  /// The duration for one cycle of the animation.
  final Duration duration;

  /// The duration for fading in the final image once loaded.
  final Duration fadeDuration;

  /// The color displayed before the pixelation effect is ready.
  final Color placeholderColor;

  /// The target width of the image widget.
  final double? width;

  /// The target height of the image widget.
  final double? height;

  /// How the image should be inscribed into the space allocated during layout.
  final BoxFit? fit;

  /// Optional base color for the random block animation during loading/error states.
  /// If null, the `placeholderColor` will be used as the base.
  final Color? baseColor;

  /// Controls the intensity of random color variation (lightness/saturation) during animation.
  /// Range: 0.0 (no variation) to 1.0 (full variation). Defaults to 0.15.
  final double? variation;

  /// Shifts the average lightness of the animation colors. Positive values make it lighter,
  /// negative values darker. Range: -1.0 to 1.0. Defaults to 0.25.
  final double? lightnessBias;

  /// Fraction of the animation cycle duration used for transitioning between colors.
  /// Range: 0.0 (instant jump) to 1.0 (transition over full cycle). Defaults to 0.6.
  final double? transition;

  /// The border radius to apply to the widget.
  final BorderRadiusGeometry? borderRadius;

  const PixelatedShimmer({
    super.key,
    this.imageProvider,
    this.showShimmer = true,
    this.pixelSize = 16.0,
    this.shimmerBaseColor = const Color(0xFFE0E0E0), // Light grey
    this.shimmerHighlightColor = const Color(0xFFF5F5F5), // Lighter grey
    this.duration = const Duration(milliseconds: 160),
    this.fadeDuration = const Duration(milliseconds: 500),
    this.placeholderColor = const Color(0xFFEEEEEE), // Very light grey
    this.width,
    this.height,
    this.fit,
    this.baseColor,
    this.variation = 0.15,
    this.lightnessBias = 0.25,
    this.transition = 0.6,
    this.borderRadius,
  }) : assert(pixelSize > 0, 'pixelSize must be positive');

  @override
  State<PixelatedShimmer> createState() => _PixelatedShimmerState();
}

class _PixelatedShimmerState extends State<PixelatedShimmer>
    with TickerProviderStateMixin {
  // State variables
  ImageStream? _imageStream;
  ImageInfo? _loadedImageInfo;
  Object? _error;
  bool _isImageProviderResolved = false;

  // Animation controllers
  late final AnimationController _animationController;
  late final AnimationController _fadeController;

  // Getters for state checks
  bool get _isLoading =>
      widget.imageProvider != null &&
      _loadedImageInfo == null &&
      _error == null;
  bool get _hasError => _error != null;
  bool get _shouldShowShimmer =>
      widget.showShimmer && (widget.imageProvider == null || _isLoading);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImageProvider();
  }

  void _resolveImageProvider() {
    if (widget.imageProvider == null) {
      _isImageProviderResolved = true;
      return;
    }

    final ImageStream newStream =
        widget.imageProvider!.resolve(createLocalImageConfiguration(context));

    if (_imageStream?.key != newStream.key) {
      _imageStream?.removeListener(
          ImageStreamListener(_handleImageFrame, onError: _handleError));
      _imageStream = newStream;
      _imageStream!.addListener(
          ImageStreamListener(_handleImageFrame, onError: _handleError));
    }
  }

  @override
  void didUpdateWidget(PixelatedShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider) {
      // Image provider changed, reset everything and resolve the new one.
      // _resolveImageProvider will be called implicitly if dependencies change,
      // but we need to handle the state reset explicitly.
      _resetStateAndResolveImage();
    }
    if (widget.duration != oldWidget.duration) {
      // Also add check here
      final animationPeriod = widget.duration > Duration.zero
          ? widget.duration
          : const Duration(milliseconds: 1500); // Fallback

      // If we switch away from unbounded, we might need to handle value restoration carefully
      // final currentValue = _shimmerController.value; // Capture if needed
      _animationController.stop();
      _animationController.value = 0.0; // Reset value before repeating
      _animationController.repeat(period: animationPeriod);
    }
    if (widget.fadeDuration != oldWidget.fadeDuration) {
      _fadeController.duration = widget.fadeDuration;
    }
    // Potentially re-run pixelation if pixelSize changes, though this is complex
    // as the image might already be loaded. Decide if this is needed.
    // if (widget.pixelSize != oldWidget.pixelSize && _loadedImageInfo != null) {
    //   _computePixelation(_loadedImageInfo!.image);
    // }
  }

  @override
  void dispose() {
    _imageStream?.removeListener(
        ImageStreamListener(_handleImageFrame, onError: _handleError));
    _animationController.dispose();
    _fadeController.dispose();
    // Explicitly cancel any pending compute
    // This requires more setup, maybe a cancellation token/flag
    // passed to the isolate, or just letting it finish and ignoring the result.
    // For simplicity, we rely on the mounted check in the callback.
    super.dispose();
  }

  void _resetStateAndResolveImage() {
    _imageStream?.removeListener(
        ImageStreamListener(_handleImageFrame, onError: _handleError));
    setState(() {
      _loadedImageInfo = null;
      _error = null;
      _isImageProviderResolved = false;
      _fadeController.reset(); // Reset fade animation
      // _dependenciesInitialized remains true, but we need to resolve again
    });
    _resolveImageProvider(); // Re-resolve after resetting state
  }

  /// Called when the image frame is successfully loaded.
  void _handleImageFrame(ImageInfo imageInfo, bool synchronousCall) {
    // Prevent state updates if the widget is disposed, or if we already processed this image
    if (!mounted || _isImageProviderResolved) return;

    setState(() {
      _loadedImageInfo = imageInfo;
      _error = null; // Clear any previous error
      _isImageProviderResolved = true; // Mark as resolved
    });

    // Start fade-in animation
    _fadeController.forward();
  }

  /// Called when the image provider fails to load the image.
  void _handleError(Object error, StackTrace? stackTrace) {
    if (!mounted) return;
    setState(() {
      _error = error;
      _loadedImageInfo = null; // Ensure no image is shown
      _isImageProviderResolved = true; // Mark as resolved (with error)
    });
    // Optionally log the error
    // print("PixelatedImageShimmer Error: $error");
  }

  @override
  Widget build(BuildContext context) {
    // Get the base color from theme if not explicitly provided
    final Color effectiveBaseColor = widget.baseColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).dividerColor
            : Theme.of(context).colorScheme.primaryFixedDim);

    Widget child = _shouldShowShimmer
        ? CustomPaint(
            painter: PixelatedPainter(
              pixelationData: _generatePlaceholderPixelation(
                widget.width ?? 100,
                widget.height ?? 100,
                widget.pixelSize,
                effectiveBaseColor,
              ),
              animation: _animationController,
              baseColor: effectiveBaseColor,
              variation: widget.variation ?? 0.15,
              lightnessBias: widget.lightnessBias ?? 0.25,
              transition: widget.transition ?? 0.6,
            ),
            child: const SizedBox
                .expand(), // Ensure CustomPaint has a child to paint on
          )
        : _buildImage();

    if (widget.borderRadius != null) {
      child = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: child,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: child,
    );
  }

  List<PixelationBlock> _generatePlaceholderPixelation(
    double width,
    double height,
    double pixelSize,
    Color baseColor,
  ) {
    final List<PixelationBlock> blocks = [];
    final int columns = (width / pixelSize).ceil();
    final int rows = (height / pixelSize).ceil();

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < columns; x++) {
        final rect = Rect.fromLTWH(
          x * pixelSize,
          y * pixelSize,
          (x + 1) * pixelSize > width ? width - x * pixelSize : pixelSize,
          (y + 1) * pixelSize > height ? height - y * pixelSize : pixelSize,
        );
        blocks.add(
          PixelationBlock(
            rect: rect,
            color: baseColor,
          ),
        );
      }
    }

    return blocks;
  }

  Widget _buildImage() {
    if (widget.imageProvider == null) {
      return Container(
        color: widget.placeholderColor,
      );
    }

    if (_hasError) {
      return Container(
        color: widget.placeholderColor,
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.red),
        ),
      );
    }

    if (_loadedImageInfo == null) {
      return Container(
        color: widget.placeholderColor,
      );
    }

    return FadeTransition(
      opacity: _fadeController,
      child: RawImage(
        image: _loadedImageInfo!.image,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      ),
    );
  }
}
