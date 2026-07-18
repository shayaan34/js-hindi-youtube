import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../services/ai_service.dart';
import '../state/app_state.dart';
import 'before_after_screen.dart';

/// The mockup studio: place LED screens, posters, stickers and animated
/// content on a site photo with perspective, glow, shadows and reflections.
class MockupEditorScreen extends StatefulWidget {
  const MockupEditorScreen(
      {super.key, required this.client, required this.photo});

  final Client client;
  final SitePhoto photo;

  @override
  State<MockupEditorScreen> createState() => _MockupEditorScreenState();
}

class _MockupEditorScreenState extends State<MockupEditorScreen> {
  final _canvasKey = GlobalKey();
  final _picker = ImagePicker();
  final _ai = AiVisionService();

  final List<MockupOverlay> _overlays = [];
  String? _selectedId;
  List<DetectedZone>? _zones;
  bool _detecting = false;
  bool _showOverlays = true;
  bool _night = false;
  bool _capturing = false;

  MockupOverlay? get _selected {
    for (final o in _overlays) {
      if (o.id == _selectedId) return o;
    }
    return null;
  }

  // ------------------------------------------------------------ AI detect

  Future<void> _detectZones() async {
    setState(() => _detecting = true);
    final analysis = await _ai.analyzePhoto(widget.photo.bytes,
        category: widget.client.category);
    if (!mounted) return;
    setState(() {
      _zones = analysis.zones;
      _detecting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'AI found ${analysis.zones.length} placement zones — best: '
            '${analysis.zones[analysis.bestZoneIndex].kind.label}')));
  }

  // ------------------------------------------------------------ overlays

  Future<void> _addOverlay(OverlayKind kind, {bool pickArtwork = false}) async {
    Uint8List? bytes;
    var mediaType = MediaType.none;
    if (pickArtwork) {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        bytes = await file.readAsBytes();
        mediaType = _sniffMediaType(bytes, file.name);
      }
    }
    final canvas = _canvasKey.currentContext?.size ?? const Size(360, 480);
    final isScreen = kind.isScreen;
    setState(() {
      final overlay = MockupOverlay(
        id: const Uuid().v4(),
        kind: kind,
        mediaBytes: bytes,
        mediaType: mediaType,
        position: Offset(canvas.width * 0.28, canvas.height * 0.24),
        width: isScreen ? canvas.width * 0.44 : canvas.width * 0.30,
        height: isScreen ? canvas.width * 0.44 * 9 / 16 : canvas.width * 0.42,
        glow: isScreen,
        reflection: isScreen,
      );
      _overlays.add(overlay);
      _selectedId = overlay.id;
    });
  }

  MediaType _sniffMediaType(Uint8List bytes, String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.json') ||
        (bytes.isNotEmpty && bytes.first == 0x7B)) {
      return MediaType.lottie;
    }
    if (bytes.length > 3 &&
        bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return MediaType.gif;
    }
    return MediaType.image;
  }

  void _removeSelected() {
    setState(() {
      _overlays.removeWhere((o) => o.id == _selectedId);
      _selectedId = null;
    });
  }

  // ------------------------------------------------------------ capture

  Future<void> _saveMockup() async {
    final previousSelection = _selectedId;
    setState(() {
      _selectedId = null;
      _zones = null;
      _capturing = true;
    });
    await Future.delayed(const Duration(milliseconds: 80));
    try {
      final boundary = _canvasKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final after = data!.buffer.asUint8List();

      if (!mounted) return;
      final name = await _promptName();
      if (name == null) return;

      final project = context.read<AppState>().saveMockup(
            widget.client,
            name: name,
            before: widget.photo.bytes,
            after: after,
            folder: widget.client.businessName,
          );
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BeforeAfterScreen(project: project)));
    } finally {
      if (mounted) {
        setState(() {
          _selectedId = previousSelection;
          _capturing = false;
        });
      }
    }
  }

  Future<String?> _promptName() {
    final controller = TextEditingController(
        text: '${widget.client.businessName} mockup');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DVColors.surfaceRaised,
        title: const Text('Save mockup'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Mockup name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mockup Studio'),
        actions: [
          IconButton(
            tooltip: _night ? 'Day preview' : 'Night preview',
            icon: Icon(_night
                ? Icons.wb_sunny_outlined
                : Icons.nightlight_outlined),
            onPressed: () => setState(() => _night = !_night),
          ),
          IconButton(
            tooltip: 'Toggle before/after',
            icon: Icon(_showOverlays
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded),
            onPressed: () =>
                setState(() => _showOverlays = !_showOverlays),
          ),
          IconButton(
            tooltip: 'Save mockup',
            icon: const Icon(Icons.save_alt_rounded, color: DVColors.orange),
            onPressed: _overlays.isEmpty || _capturing ? null : _saveMockup,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildCanvas()),
          _buildInspector(),
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DVColors.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () => setState(() => _selectedId = null),
        child: RepaintBoundary(
          key: _canvasKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.matrix(
                    AiVisionService.lightingMatrix(night: _night)),
                child:
                    Image.memory(widget.photo.bytes, fit: BoxFit.cover),
              ),
              if (_zones != null)
                LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: _zones!
                        .map((z) => _ZoneBox(
                            zone: z,
                            canvasSize: Size(constraints.maxWidth,
                                constraints.maxHeight)))
                        .toList(),
                  ),
                ),
              if (_showOverlays)
                ..._overlays.map((o) => _OverlayWidget(
                      key: ValueKey(o.id),
                      overlay: o,
                      selected: o.id == _selectedId,
                      night: _night,
                      onSelect: () =>
                          setState(() => _selectedId = o.id),
                      onChanged: () => setState(() {}),
                    )),
              if (_detecting)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                            color: DVColors.orange),
                        const SizedBox(height: 14),
                        Text('AI analyzing walls & perspective…',
                            style:
                                Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInspector() {
    final o = _selected;
    if (o == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      decoration: BoxDecoration(
        color: DVColors.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DVColors.stroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(o.kind.icon, size: 16, color: DVColors.orange),
              const SizedBox(width: 6),
              Text(o.kind.label, style: text.titleMedium),
              const Spacer(),
              _miniToggle('Glow', o.glow, (v) => setState(() => o.glow = v)),
              _miniToggle(
                  'Shadow', o.shadow, (v) => setState(() => o.shadow = v)),
              _miniToggle('Mirror', o.reflection,
                  (v) => setState(() => o.reflection = v)),
              IconButton(
                tooltip: 'Delete element',
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: DVColors.danger),
                onPressed: _removeSelected,
              ),
            ],
          ),
          _sliderRow('Tilt ↔', o.tiltY, -0.6, 0.6,
              (v) => setState(() => o.tiltY = v)),
          _sliderRow('Tilt ↕', o.tiltX, -0.6, 0.6,
              (v) => setState(() => o.tiltX = v)),
          _sliderRow('Rotate', o.rotation, -math.pi / 2, math.pi / 2,
              (v) => setState(() => o.rotation = v)),
          _sliderRow('Brightness', o.brightness, 0.4, 1.8,
              (v) => setState(() => o.brightness = v)),
        ],
      ),
    );
  }

  Widget _miniToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: value,
        visualDensity: VisualDensity.compact,
        selectedColor: DVColors.orange.withOpacity(0.25),
        onSelected: onChanged,
      ),
    );
  }

  Widget _sliderRow(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
            width: 76,
            child:
                Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: DVColors.orange,
              thumbColor: DVColors.orangeBright,
              inactiveTrackColor: DVColors.stroke,
              trackHeight: 2.4,
            ),
            child: Slider(value: value.clamp(min, max).toDouble(), min: min, max: max,
                onChanged: onChanged),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return SafeArea(
      top: false,
      child: Container(
        height: 92,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          children: [
            _ToolButton(
              icon: Icons.auto_awesome_rounded,
              label: 'Detect walls',
              highlight: true,
              onTap: _detecting ? null : _detectZones,
            ),
            ...OverlayKind.values.map((kind) => _ToolButton(
                  icon: kind.icon,
                  label: kind.label,
                  onTap: () => _showAddSheet(kind),
                )),
          ],
        ),
      ),
    );
  }

  void _showAddSheet(OverlayKind kind) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DVColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add ${kind.label}',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                kind.isScreen
                    ? 'Use built-in live demo content, or upload your own '
                      'artwork (PNG/JPG), GIF animation or Lottie JSON.'
                    : 'Upload the artwork (PNG/JPG) or start with a '
                      'placeholder you can replace later.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Upload artwork / animation'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _addOverlay(kind, pickArtwork: true);
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: Icon(
                    kind.isScreen
                        ? Icons.play_circle_outline
                        : Icons.dashboard_customize_outlined,
                    color: DVColors.orange),
                label: Text(kind.isScreen
                    ? 'Use live demo content'
                    : 'Use placeholder'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _addOverlay(kind);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Zone overlay
// ---------------------------------------------------------------------------

class _ZoneBox extends StatelessWidget {
  const _ZoneBox({required this.zone, required this.canvasSize});

  final DetectedZone zone;
  final Size canvasSize;

  @override
  Widget build(BuildContext context) {
    final rect = Rect.fromLTWH(
      zone.rect.left * canvasSize.width,
      zone.rect.top * canvasSize.height,
      zone.rect.width * canvasSize.width,
      zone.rect.height * canvasSize.height,
    );
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: zone.color,
                width: zone.recommended ? 2.4 : 1.2),
            borderRadius: BorderRadius.circular(8),
            color: zone.color.withOpacity(zone.recommended ? 0.12 : 0.05),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              margin: const EdgeInsets.all(4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: zone.color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${zone.recommended ? '★ ' : ''}${zone.kind.label} '
                '${(zone.confidence * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Draggable overlay element
// ---------------------------------------------------------------------------

class _OverlayWidget extends StatefulWidget {
  const _OverlayWidget({
    super.key,
    required this.overlay,
    required this.selected,
    required this.night,
    required this.onSelect,
    required this.onChanged,
  });

  final MockupOverlay overlay;
  final bool selected;
  final bool night;
  final VoidCallback onSelect;
  final VoidCallback onChanged;

  @override
  State<_OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<_OverlayWidget>
    with SingleTickerProviderStateMixin {
  double _startWidth = 0;
  double _startHeight = 0;
  double _startRotation = 0;

  late final AnimationController _demoController = AnimationController(
      vsync: this, duration: const Duration(seconds: 4))
    ..repeat();

  @override
  void dispose() {
    _demoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.overlay;

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0016) // perspective depth
      ..rotateX(o.tiltX)
      ..rotateY(o.tiltY)
      ..rotateZ(o.rotation);

    return Positioned(
      left: o.position.dx,
      top: o.position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSelect,
        onScaleStart: (d) {
          widget.onSelect();
          _startWidth = o.width;
          _startHeight = o.height;
          _startRotation = o.rotation;
        },
        onScaleUpdate: (d) {
          o.position += d.focalPointDelta;
          if (d.pointerCount > 1) {
            o.width = (_startWidth * d.scale).clamp(48, 1600).toDouble();
            o.height = (_startHeight * d.scale).clamp(32, 1600).toDouble();
            o.rotation = _startRotation + d.rotation;
          }
          widget.onChanged();
        },
        child: Transform(
          alignment: Alignment.center,
          transform: transform,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _decoratedContent(o),
              if (o.reflection)
                Positioned(
                  top: o.height + 4,
                  left: 0,
                  child: Opacity(
                    opacity: 0.22,
                    child: Transform(
                      alignment: Alignment.topCenter,
                      transform: Matrix4.diagonal3Values(1, -1, 1),
                      child: ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.white, Colors.transparent],
                          stops: [0, 0.8],
                        ).createShader(rect),
                        blendMode: BlendMode.dstIn,
                        child: _content(o),
                      ),
                    ),
                  ),
                ),
              if (widget.selected) ..._selectionChrome(o),
            ],
          ),
        ),
      ),
    );
  }

  /// Content wrapped with shadow, glow and brightness.
  Widget _decoratedContent(MockupOverlay o) {
    final brightnessMatrix = <double>[
      o.brightness, 0, 0, 0, 0,
      0, o.brightness, 0, 0, 0,
      0, 0, o.brightness, 0, 0,
      0, 0, 0, 1, 0,
    ];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(o.kind.isScreen ? 6 : 3),
        boxShadow: [
          if (o.shadow)
            BoxShadow(
              color: Colors.black.withOpacity(0.55),
              blurRadius: 18,
              offset: const Offset(6, 12),
            ),
          if (o.glow)
            BoxShadow(
              color: (widget.night
                      ? DVColors.orangeBright
                      : DVColors.orange)
                  .withOpacity(widget.night ? 0.55 : 0.32),
              blurRadius: widget.night ? 46 : 30,
              spreadRadius: widget.night ? 6 : 2,
            ),
        ],
      ),
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(brightnessMatrix),
        child: _content(o),
      ),
    );
  }

  /// The raw artwork / screen content at the overlay's size.
  Widget _content(MockupOverlay o) {
    final radius = BorderRadius.circular(o.kind.isScreen ? 6 : 3);
    Widget inner;

    if (o.mediaBytes != null && o.mediaType == MediaType.lottie) {
      inner = Lottie.memory(o.mediaBytes!, fit: BoxFit.cover);
    } else if (o.mediaBytes != null) {
      // Image.memory animates GIFs automatically.
      inner = Image.memory(o.mediaBytes!, fit: BoxFit.cover,
          gaplessPlayback: true);
    } else if (o.kind.isScreen) {
      inner = _demoScreenContent();
    } else {
      inner = _placeholderArtwork(o.kind);
    }

    if (o.kind.isScreen) {
      // LED bezel + subtle screen sheen.
      return Container(
        width: o.width,
        height: o.height,
        decoration: BoxDecoration(
          color: const Color(0xFF050505),
          borderRadius: radius,
          border: Border.all(color: const Color(0xFF1E1E22), width: 3),
        ),
        padding: const EdgeInsets.all(3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            fit: StackFit.expand,
            children: [
              inner,
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.10),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      stops: const [0, 0.35, 1],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: o.width,
      height: o.height,
      child: ClipRRect(borderRadius: radius, child: inner),
    );
  }

  /// Built-in animated "advertisement" for LED screens with no artwork.
  Widget _demoScreenContent() {
    return AnimatedBuilder(
      animation: _demoController,
      builder: (context, _) {
        final t = _demoController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t, -1),
              end: Alignment(1 + 2 * t, 1),
              colors: const [
                Color(0xFFE05500),
                Color(0xFFFF8A3C),
                Color(0xFF2A1305),
                Color(0xFFFF6A00),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.smart_display_rounded,
                      color: Colors.white, size: 28),
                  const SizedBox(height: 4),
                  Text('YOUR AD HERE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 6)
                        ],
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _placeholderArtwork(OverlayKind kind) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F5F7), Color(0xFFD9D9DE)],
        ),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(kind.icon, color: DVColors.orangeDeep, size: 30),
              const SizedBox(height: 4),
              Text(kind.label.toUpperCase(),
                  style: const TextStyle(
                      color: Color(0xFF2A2A30),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
            ],
          ),
        ),
      ),
    );
  }

  /// Selection border + corner resize handle.
  List<Widget> _selectionChrome(MockupOverlay o) {
    return [
      Positioned.fill(
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: DVColors.orange, width: 1.6),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
      Positioned(
        right: -12,
        bottom: -12,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) {
            o.width = (o.width + d.delta.dx).clamp(48, 1600).toDouble();
            o.height = (o.height + d.delta.dy).clamp(32, 1600).toDouble();
            widget.onChanged();
          },
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: DVColors.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.open_in_full_rounded,
                size: 13, color: Colors.white),
          ),
        ),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Toolbar button
// ---------------------------------------------------------------------------

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 82,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            gradient: highlight ? DVColors.orangeGradient : null,
            color: highlight ? null : DVColors.surfaceRaised,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DVColors.stroke),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 22,
                  color: highlight ? Colors.white : DVColors.orange),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: highlight ? Colors.white : DVColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
