// iOS-side config. R1: Windows owns mode/aspect/resolution — iOS only holds the host address
// and basic local prefs (FPS, display). Stream params come back from the host in CONFIG_ACK.

class Prefs {
  final String hostIp;
  final int fps; // preference; Windows may clamp
  final bool letterbox;

  const Prefs({this.hostIp = '', this.fps = 60, this.letterbox = true});

  Prefs copyWith({String? hostIp, int? fps, bool? letterbox}) => Prefs(
        hostIp: hostIp ?? this.hostIp,
        fps: fps ?? this.fps,
        letterbox: letterbox ?? this.letterbox,
      );

  // Sent to native → ctrl SET_PREFS payload.
  Map<String, dynamic> toPrefsJson() => {
        'fps': fps,
        'display': {'letterbox': letterbox},
      };

  Map<String, dynamic> toJson() => {'hostIp': hostIp, 'fps': fps, 'letterbox': letterbox};

  factory Prefs.fromJson(Map<String, dynamic> j) => Prefs(
        hostIp: (j['hostIp'] as String?) ?? '',
        fps: (j['fps'] as num?)?.toInt() ?? 60,
        letterbox: (j['letterbox'] as bool?) ?? true,
      );
}

// Authoritative stream info from the Windows host (CONFIG_ACK / CONFIG_UPDATE).
class StreamInfo {
  final String mode;
  final String aspectRatio;
  final int width;
  final int height;
  final int fps;
  final String codec;

  const StreamInfo({
    required this.mode,
    required this.aspectRatio,
    required this.width,
    required this.height,
    required this.fps,
    required this.codec,
  });

  double get aspect => height == 0 ? 1.0 : width / height;

  factory StreamInfo.fromJson(Map<String, dynamic> j) => StreamInfo(
        mode: (j['mode'] as String?) ?? 'extend',
        aspectRatio: (j['aspectRatio'] as String?) ?? 'native',
        width: (j['virtualWidth'] as num?)?.toInt() ?? 0,
        height: (j['virtualHeight'] as num?)?.toInt() ?? 0,
        fps: (j['fps'] as num?)?.toInt() ?? 60,
        codec: (j['codec'] as String?) ?? 'h264',
      );
}
