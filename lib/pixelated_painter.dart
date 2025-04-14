import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pixelated_shimmer/pixelation_utils.dart'; // For PixelationBlock

/// Paints pixelated blocks, animating their color based on variations of a base color.
class PixelatedPainter extends CustomPainter {
  final List<PixelationBlock> pixelationData;
  final Animation<double> animation;
  final Color baseColor; // Renamed
  final double variation; // Renamed
  final double lightnessBias; // Renamed
  final double transition; // Renamed

  // State for storing current colors and tracking animation cycle
  List<Color>? _currentBlockColors;
  List<Color>? _previousBlockColors; // Store colors from the previous cycle
  double _previousAnimValue = -1.0; // Initialize to value outside 0-1 range
  List<PixelationBlock>? _lastPixelationData; // To detect data changes

  // Use a single Random instance
  final Random _random = Random();

  PixelatedPainter({
    required this.pixelationData,
    required this.animation,
    required this.baseColor, // Renamed
    required this.variation, // Renamed
    required this.lightnessBias, // Renamed
    required this.transition, // Renamed
  })  : assert(variation >= 0.0 && variation <= 1.0,
            'variation must be between 0.0 and 1.0'),
        assert(lightnessBias >= -1.0 && lightnessBias <= 1.0,
            'lightnessBias must be between -1.0 and 1.0'),
        assert(transition >= 0.0 && transition <= 1.0,
            'transition must be between 0.0 and 1.0'),
        super(repaint: animation);

  final Paint _blockPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (pixelationData.isEmpty) return;

    final double currentAnimValue = animation.value;
    bool needsColorUpdate = false;

    // 1. Check conditions requiring color update
    if (_lastPixelationData != pixelationData) {
      needsColorUpdate = true;
      _currentBlockColors = null; // Force re-initialization
      _previousBlockColors = null;
      _lastPixelationData = pixelationData;
      _previousAnimValue = -1.0; // Reset cycle detection
    }

    // Check if animation has looped (value decreased significantly)
    if (currentAnimValue < _previousAnimValue &&
        (_previousAnimValue - currentAnimValue) > 0.5) {
      needsColorUpdate = true;
    }

    // 2. Generate New Random Colors if needed
    if (needsColorUpdate || _currentBlockColors == null) {
      // Shift current colors to previous (create copy)
      _previousBlockColors = _currentBlockColors?.toList();

      // Initialize or resize current colors list
      _currentBlockColors ??=
          List<Color>.filled(pixelationData.length, Colors.transparent);
      if (_currentBlockColors!.length != pixelationData.length) {
        _currentBlockColors =
            List<Color>.filled(pixelationData.length, Colors.transparent);
        _previousBlockColors = null; // Mismatch, reset previous
      }

      // Generate new colors
      final HSLColor baseHsl = HSLColor.fromColor(baseColor);
      for (int i = 0; i < pixelationData.length; i++) {
        // Calculate random lightness offset (biased)
        final double lightnessOffset =
            (_random.nextDouble() * variation) - (variation / 2.0);
        final double finalLightness =
            (baseHsl.lightness + lightnessBias + lightnessOffset)
                .clamp(0.0, 1.0);

        // Calculate random saturation offset
        final double saturationOffset =
            (_random.nextDouble() * variation) - (variation / 2.0);
        final double finalSaturation =
            (baseHsl.saturation + saturationOffset).clamp(0.0, 1.0);

        // Calculate random hue offset (degrees, +/- up to variation * 180)
        final double hueOffset =
            (_random.nextDouble() * variation * 360.0) - (variation * 180.0);
        final double finalHue = (baseHsl.hue + hueOffset) % 360.0;
        // Ensure hue is non-negative after modulo
        final double nonNegativeHue =
            finalHue < 0 ? finalHue + 360.0 : finalHue;

        // Store the newly generated color with varied hue, lightness, and saturation
        _currentBlockColors![i] = HSLColor.fromAHSL(
          baseHsl.alpha, // Keep original alpha
          nonNegativeHue, // Apply hue variation
          finalSaturation, // Apply saturation variation
          finalLightness, // Apply lightness variation (with bias)
        ).toColor();
      }

      // Handle first run: If previous is still null, copy current to avoid lerp errors
      _previousBlockColors ??= _currentBlockColors!.toList();
    }

    // 3. Calculate transition progress (0.0 to 1.0 within the transitionFraction)
    final double t = (transition > 0)
        ? (currentAnimValue / transition).clamp(0.0, 1.0) // Use renamed field
        : 1.0;

    // 4. Draw Blocks Using Interpolated Colors
    if (_currentBlockColors == null || _previousBlockColors == null)
      return; // Should not happen if initialized correctly

    for (int i = 0; i < pixelationData.length; i++) {
      // Ensure index is valid for color lists (safety check)
      if (i >= _currentBlockColors!.length || i >= _previousBlockColors!.length)
        continue;

      final block = pixelationData[i];
      final Rect clippedRect = block.rect.intersect(Offset.zero & size);
      if (clippedRect.isEmpty) continue;

      // Interpolate between previous and current color based on progress t
      final Color currentColor = _currentBlockColors![i];
      final Color previousColor = _previousBlockColors![i];
      _blockPaint.color = Color.lerp(previousColor, currentColor, t)!;

      canvas.drawRect(clippedRect, _blockPaint);
    }

    // 5. Update previous animation value for next frame check
    _previousAnimValue = currentAnimValue;
  }

  @override
  bool shouldRepaint(covariant PixelatedPainter oldDelegate) {
    return oldDelegate.pixelationData != pixelationData ||
        oldDelegate.baseColor != baseColor || // Renamed
        oldDelegate.variation != variation || // Renamed
        oldDelegate.lightnessBias != lightnessBias || // Renamed
        oldDelegate.transition != transition; // Renamed
  }
}
