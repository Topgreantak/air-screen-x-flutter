import 'package:flutter/material.dart';
import '../models/connection_state.dart';

class ConnectionBadge extends StatelessWidget {
  final ConnState state;
  const ConnectionBadge({super.key, required this.state});

  Color get _color => switch (state) {
        ConnState.streaming => Colors.green,
        ConnState.waiting || ConnState.requesting => Colors.orange,
        ConnState.denied || ConnState.error => Colors.red,
        ConnState.disconnected => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.circle, size: 12, color: _color),
      const SizedBox(width: 8),
      Text(state.label, style: Theme.of(context).textTheme.bodyMedium),
    ]);
  }
}
