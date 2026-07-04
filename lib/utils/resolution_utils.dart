import 'dart:ui';

// Letterbox/pillarbox math — mirrors the Swift MetalRenderer viewport calc. Pure & testable.
// Never stretches: fits the stream aspect inside the screen, centered, with black bars.
class ContentRect {
  final double x, y, width, height;
  const ContentRect(this.x, this.y, this.width, this.height);

  bool contains(double px, double py) =>
      px >= x && px <= x + width && py >= y && py <= y + height;
}

// streamAspect = w/h of the stream. screen = device surface size.
ContentRect fitContent(double streamAspect, Size screen) {
  if (streamAspect <= 0 || screen.width <= 0 || screen.height <= 0) {
    return const ContentRect(0, 0, 0, 0);
  }
  final screenAspect = screen.width / screen.height;
  if (streamAspect > screenAspect) {
    // wider than screen → letterbox (bars top/bottom)
    final h = screen.width / streamAspect;
    return ContentRect(0, (screen.height - h) / 2, screen.width, h);
  } else {
    // taller/narrower → pillarbox (bars left/right)
    final w = screen.height * streamAspect;
    return ContentRect((screen.width - w) / 2, 0, w, screen.height);
  }
}

// Map a touch inside the content rect to normalized 0..1 over the virtual resolution.
// Returns null if the touch is on a letterbox bar (outside content).
Offset? normalizeTouch(double px, double py, ContentRect content) {
  if (!content.contains(px, py) || content.width == 0 || content.height == 0) return null;
  return Offset((px - content.x) / content.width, (py - content.y) / content.height);
}
