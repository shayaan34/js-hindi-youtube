import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';

/// Live AR-style preview: opens the phone camera, lets the rep place a
/// virtual LED screen or poster on the feed and walk around while the
/// element tracks with drag-based parallax and perspective.
///
/// This is a lightweight in-Flutter AR simulation. For full plane detection
/// and world tracking, plug in `ar_flutter_plugin` (ARCore on Android /
/// ARKit on iOS) — this screen's placement model (position, scale, tilt)
/// maps 1:1 onto an AR anchor transform.
class ARPreviewScreen extends StatefulWidget {
  const ARPreviewScreen({super.key, required this.client});

  final Client client;

  @override
  State<ARPreviewScreen> createState() => _ARPreviewScreenState();
}

class _ARPreviewScreenState extends State<ARPreviewScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _camera;
  bool _cameraFailed = false;
  bool _wallDetected = false;
  bool _placed = false;
  bool _showPoster = false;

  Offset _position = const Offset(0.5, 0.45); // normalized
  double _scale = 1.0;
  double _tiltY = 0.0;

  late final AnimationController _scanController = AnimationController(
      vsync: this, duration: const Duration(seconds: 2))
    ..repeat();

  @override
  void initState() {
    super.initState();
    _initCamera();
    // Simulated plane detection completing after a short scan.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _wallDetected = true);
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('no cameras');
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() => _camera = controller);
    } catch (_) {
      if (mounted) setState(() => _cameraFailed = true);
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AR Preview'),
        backgroundColor: Colors.black45,
        actions: [
          IconButton(
            tooltip: _showPoster ? 'Switch to LED screen' : 'Switch to poster',
            icon: Icon(_showPoster ? Icons.tv_rounded : Icons.image_rounded),
            onPressed: () => setState(() => _showPoster = !_showPoster),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            onScaleUpdate: (d) {
              setState(() {
                _position += Offset(d.focalPointDelta.dx / size.width,
                    d.focalPointDelta.dy / size.height);
                _position = Offset(_position.dx.clamp(0.1, 0.9).toDouble(),
                    _position.dy.clamp(0.1, 0.9).toDouble());
                if (d.pointerCount > 1) {
                  _scale = (_scale * d.scale).clamp(0.4, 3.0).toDouble();
                }
                // Horizontal movement adds subtle parallax tilt, mimicking
                // walking around the placed object.
                _tiltY = ((_position.dx - 0.5) * -0.9).clamp(-0.5, 0.5).toDouble();
              });
            },
            onTapUp: (d) {
              if (_wallDetected && !_placed) {
                setState(() {
                  _placed = true;
                  _position = Offset(d.localPosition.dx / size.width,
                      d.localPosition.dy / size.height);
                });
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                _cameraLayer(),
                if (!_wallDetected) _scanOverlay(text),
                if (_wallDetected && !_placed) _tapHint(text),
                if (_placed) _virtualElement(size),
                _bottomBar(text),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cameraLayer() {
    if (_camera != null && _camera!.value.isInitialized) {
      return CameraPreview(_camera!);
    }
    // Fallback "room" for web/desktop/emulator so the flow stays demoable.
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C2C34), Color(0xFF17171B), Color(0xFF101013)],
          stops: [0, 0.7, 1],
        ),
      ),
      child: _cameraFailed
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Camera unavailable on this device — showing a simulated '
                  'room. On a phone this uses the live camera feed.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          : const Center(
              child: CircularProgressIndicator(color: DVColors.orange)),
    );
  }

  Widget _scanOverlay(TextTheme text) {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, _) {
        final t = _scanController.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            // Sweeping scan line.
            Align(
              alignment: Alignment(0, -1 + 2 * t),
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    DVColors.orange.withOpacity(0.9),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.75),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: DVColors.orange),
                    ),
                    const SizedBox(width: 10),
                    Text('Scanning for walls…', style: text.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tapHint(TextTheme text) {
    return Align(
      alignment: const Alignment(0, 0.75),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: DVColors.orange.withOpacity(0.92),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Wall detected — tap to place display',
                style: text.bodyMedium!.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _virtualElement(Size size) {
    final width = size.width * 0.5 * _scale;
    final height = _showPoster ? width * 1.4 : width * 9 / 16;
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0015)
      ..rotateY(_tiltY);

    return Positioned(
      left: _position.dx * size.width - width / 2,
      top: _position.dy * size.height - height / 2,
      child: IgnorePointer(
        child: Transform(
          alignment: Alignment.center,
          transform: transform,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: _showPoster ? Colors.white : const Color(0xFF050505),
              borderRadius: BorderRadius.circular(_showPoster ? 2 : 8),
              border: _showPoster
                  ? null
                  : Border.all(color: const Color(0xFF232329), width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 24,
                  offset: const Offset(8, 16),
                ),
                if (!_showPoster)
                  BoxShadow(
                    color: DVColors.orange.withOpacity(0.5),
                    blurRadius: 50,
                    spreadRadius: 4,
                  ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _showPoster
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_offer_rounded,
                          color: DVColors.orangeDeep, size: 40),
                      const SizedBox(height: 8),
                      Text('MEGA SALE',
                          style: TextStyle(
                              color: Colors.grey.shade900,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      const Text('UP TO 50% OFF',
                          style: TextStyle(
                              color: DVColors.orangeDeep,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  )
                : TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 2 * math.pi),
                    duration: const Duration(seconds: 6),
                    builder: (context, angle, _) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(math.cos(angle), math.sin(angle)),
                          end: Alignment(-math.cos(angle), -math.sin(angle)),
                          colors: const [
                            Color(0xFFE05500),
                            Color(0xFFFF8A3C),
                            Color(0xFF1A0A00),
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text('YOUR AD HERE',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3)),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(TextTheme text) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: DVColors.stroke),
          ),
          child: Text(
            _placed
                ? 'Drag to move • pinch to resize • move sideways for parallax'
                : 'Point the camera at the wall you want to preview',
            style: text.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
