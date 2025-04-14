import 'dart:ui' show Color, Rect;
import 'package:flutter/foundation.dart'; // For immutable
import 'package:image/image.dart' as img_lib; // Use image library

/// Data class to hold pixelation results for a single block.
@immutable
class PixelationBlock {
  final Rect rect;
  final Color color;

  const PixelationBlock({required this.rect, required this.color});

  // Need methods for serialization if sending complex objects between isolates
  // For simple data like this, sending as a Map might be easier if needed.
}

/// Input data for the pixelation computation isolate.
@immutable
class PixelationComputeData {
  final Uint8List byteData; // Raw image bytes (e.g., RGBA)
  final int imageWidth;
  final int imageHeight;
  final double pixelSize;

  const PixelationComputeData({
    required this.byteData,
    required this.imageWidth,
    required this.imageHeight,
    required this.pixelSize,
  });
}

/// Computes the pixelated representation of an image.
/// Designed to be run in an isolate via `compute`.
/// Uses the 'image' package for easier pixel access and averaging.
List<PixelationBlock> computePixelationData(PixelationComputeData data) {
  final List<PixelationBlock> blocks = [];
  final int pixelSizeInt = data.pixelSize.round();
  if (pixelSizeInt <= 0) {
    return blocks; // Avoid division by zero or infinite loops
  }

  try {
    // Decode the image using the image library
    // Assuming RGBA format from ui.Image.toByteData(format: ui.ImageByteFormat.rawRgba)
    img_lib.Image? decodedImage = img_lib.Image.fromBytes(
      width: data.imageWidth,
      height: data.imageHeight,
      bytes: data.byteData.buffer, // Use the buffer
      format: img_lib.Format.uint8, // Assuming 8-bit channels
      numChannels: 4, // RGBA
    );

    // Handle decoding failure immediately
    if (decodedImage == null) {
      return blocks;
    }
    final img_lib.Image image = decodedImage; // Now non-nullable

    // Iterate through the image in blocks
    for (int y = 0; y < data.imageHeight; y += pixelSizeInt) {
      for (int x = 0; x < data.imageWidth; x += pixelSizeInt) {
        int totalR = 0;
        int totalG = 0;
        int totalB = 0;
        int totalA = 0;
        int pixelCount = 0;

        // Calculate bounds for the current block, clamping to image dimensions
        final int blockEndX = (x + pixelSizeInt).clamp(0, data.imageWidth);
        final int blockEndY = (y + pixelSizeInt).clamp(0, data.imageHeight);
        final int blockWidth = blockEndX - x;
        final int blockHeight = blockEndY - y;

        if (blockWidth <= 0 || blockHeight <= 0) continue; // Skip empty blocks

        // Iterate over pixels within the block using image library
        for (int py = y; py < blockEndY; py++) {
          for (int px = x; px < blockEndX; px++) {
            // ignore: unnecessary_nullable_for_final_variable_declarations
            final img_lib.Pixel? pixel = image.getPixelSafe(px, py);
            if (pixel != null) {
              totalR += pixel.r.toInt();
              totalG += pixel.g.toInt();
              totalB += pixel.b.toInt();
              totalA += pixel.a.toInt(); // Assuming alpha channel matters
              pixelCount++;
            }
          }
        }

        if (pixelCount > 0) {
          final int avgR = totalR ~/ pixelCount;
          final int avgG = totalG ~/ pixelCount;
          final int avgB = totalB ~/ pixelCount;
          final int avgA = totalA ~/ pixelCount;

          final blockRect = Rect.fromLTWH(
            x.toDouble(),
            y.toDouble(),
            pixelSizeInt.toDouble(), // Use intended pixel size for rect
            pixelSizeInt.toDouble(),
          );

          blocks.add(PixelationBlock(
            rect: blockRect,
            color: Color.fromARGB(avgA, avgR, avgG, avgB),
          ));
        }
      }
    }
  } catch (e) {
    // print("Error during pixelation computation: $e");
    // Depending on requirements, you might want to rethrow or return empty/partial list
    return blocks; // Return whatever was computed so far or empty
  }

  return blocks;
}
