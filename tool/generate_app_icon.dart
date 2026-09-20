// Generates the AI Workspace launcher-icon artwork.
//
// Run with:  dart run tool/generate_app_icon.dart
//
// Outputs:
//   assets/icon/app_icon.png             1024x1024, indigo background + white hub
//   assets/icon/app_icon_foreground.png  1024x1024, transparent, hub only
//
// The mark is the same "hub" symbol used across the app UI (splash, sign-in,
// navigation rail): a central node connected to three outer nodes — an
// original design drawn programmatically with the `image` package, in the
// brand palette from lib/theme/app_colors.dart.

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  const size = 1024;

  // Brand palette (mirrors AppColors.primary = 0xFF5B5FE9).
  final background = img.ColorRgba8(0x5B, 0x5F, 0xE9, 0xFF);
  final white = img.ColorRgba8(0xFF, 0xFF, 0xFF, 0xFF);

  // Full launcher icon: filled indigo square, hub at ~59% reach — inside the
  // 80%-diameter maskable safe zone, so the same file works as a maskable
  // web icon too.
  final full = img.Image(width: size, height: size);
  img.fill(full, color: background);
  _drawHub(full, color: white, scale: 1.12);
  _writePng('assets/icon/app_icon.png', full);

  // Adaptive-icon foreground: transparent canvas, hub inside the
  // 66%-diameter adaptive safe zone so it survives any launcher mask.
  final foreground = img.Image(width: size, height: size);
  _drawHub(foreground, color: white, scale: 0.95);
  _writePng('assets/icon/app_icon_foreground.png', foreground);

  stdout.writeln('Icon artwork written to assets/icon/');
}

/// Draws the hub mark, centred, with overall reach proportional to [scale].
/// At scale 1.0 the outermost node edge sits 268 px from the centre.
void _drawHub(img.Image image, {required img.Color color, double scale = 1.0}) {
  const cx = 512, cy = 512; // canvas centre at 1024x1024
  final centerRadius = (72 * scale).round();
  final spokeLength = (226 * scale).round();
  final spokeThickness = 30 * scale;
  final nodeRadius = (42 * scale).round();

  // Three outer nodes: top, bottom-left, bottom-right.
  const anglesDeg = <double>[-90, 210, 330];
  for (final degrees in anglesDeg) {
    final radians = degrees * math.pi / 180;
    final nx = cx + (spokeLength * math.cos(radians)).round();
    final ny = cy + (spokeLength * math.sin(radians)).round();
    // Spoke drawn as a rotated filled quad: the package's anti-aliased
    // thick drawLine produces banding artifacts, a polygon looks cleaner.
    _fillSpoke(image, cx, cy, nx, ny, spokeThickness / 2, color);
    img.fillCircle(
      image,
      x: nx,
      y: ny,
      radius: nodeRadius,
      color: color,
      antialias: true,
    );
  }
  // Central hub on top of the spoke junctions.
  img.fillCircle(
    image,
    x: cx,
    y: cy,
    radius: centerRadius,
    color: color,
    antialias: true,
  );
}

/// Fills the spoke between the hub centre and an outer node as a rectangle
/// rotated along the center->node axis with half-width [halfWidth].
void _fillSpoke(
  img.Image image,
  int x1,
  int y1,
  int x2,
  int y2,
  double halfWidth,
  img.Color color,
) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final length = math.sqrt(dx * dx + dy * dy);
  if (length == 0) return;
  // Perpendicular unit vector.
  final px = -dy / length * halfWidth;
  final py = dx / length * halfWidth;
  img.fillPolygon(
    image,
    vertices: [
      img.Point(x1 + px, y1 + py),
      img.Point(x2 + px, y2 + py),
      img.Point(x2 - px, y2 - py),
      img.Point(x1 - px, y1 - py),
    ],
    color: color,
  );
}

void _writePng(String path, img.Image image) {
  File(path).createSync(recursive: true);
  File(path).writeAsBytesSync(img.encodePng(image));
  stdout.writeln('  -> $path (${image.width}x${image.height})');
}
