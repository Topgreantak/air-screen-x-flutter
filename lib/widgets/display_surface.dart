import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Embeds the native Metal view that renders decoded H.264 frames directly (no Flutter raster).
// Touch handling happens in the native view (TouchHandler → UDP). See ios/.../MetalViewFactory.
class DisplaySurface extends StatelessWidget {
  const DisplaySurface({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black, // letterbox bars
      child: UiKitView(
        viewType: 'idisplay/metal-view',
        layoutDirection: TextDirection.ltr,
        creationParamsCodec: StandardMessageCodec(),
      ),
    );
  }
}
