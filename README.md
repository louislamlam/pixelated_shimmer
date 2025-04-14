# pixelated_shimmer

[![pub package](https://img.shields.io/pub/v/pixelated_shimmer.svg)](https://pub.dev/packages/pixelated_shimmer) <!-- TODO: Update badge once published -->
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

> A Dart package providing utilities or widgets for pixelated shimmer effects.

**Demo**

![Pixelated Shimmer Demo](./assets/screenshot.gif)

## Features

- Displays images with a pixelated reveal effect.
- Provides a customizable animated pixelated placeholder/shimmer.
- Supports network images and other image providers.
- Configurable pixel size, animation speed, colors, and more.

## Installation

Add `pixelated_shimmer` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  pixelated_shimmer: ^0.0.1 # Replace with the latest version
```

Then run `flutter pub get`.

## Usage

Import the package:

```dart
import 'package:pixelated_shimmer/pixelated_shimmer.dart';
```

Use the `PixelatedShimmer` widget:

```dart
PixelatedShimmer(
  imageProvider: NetworkImage('YOUR_IMAGE_URL_HERE'),
  width: 300,
  height: 300,
  pixelSize: 12.0,
  borderRadius: BorderRadius.circular(8),
  fit: BoxFit.cover,
)
```

For a more complete example, see the `example` directory in this repository.

## License

This package is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.
