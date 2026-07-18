import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme.dart';
import '../models/models.dart';

/// Interactive before/after slider comparison for a saved mockup.
class BeforeAfterScreen extends StatefulWidget {
  const BeforeAfterScreen({super.key, required this.project});

  final MockupProject project;

  @override
  State<BeforeAfterScreen> createState() => _BeforeAfterScreenState();
}

class _BeforeAfterScreenState extends State<BeforeAfterScreen> {
  double _split = 0.5;

  Future<void> _share({required bool whatsapp}) async {
    final p = widget.project;
    await Share.shareXFiles(
      [
        XFile.fromData(p.afterBytes,
            mimeType: 'image/png', name: '${p.name}.png'),
      ],
      text: whatsapp
          ? 'Here is how your new display will look! — ${p.name} (via DisplayVision)'
          : '${p.name} — mockup preview from DisplayVision',
      subject: 'DisplayVision mockup: ${p.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.project.name)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        return GestureDetector(
                          onHorizontalDragUpdate: (d) => setState(() =>
                              _split = (d.localPosition.dx / w)
                                  .clamp(0.02, 0.98)
                                  .toDouble()),
                          onTapDown: (d) => setState(() =>
                              _split = (d.localPosition.dx / w)
                                  .clamp(0.02, 0.98)
                                  .toDouble()),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // AFTER (full)
                              Image.memory(widget.project.afterBytes,
                                  fit: BoxFit.cover),
                              // BEFORE (left portion)
                              ClipRect(
                                clipper: _LeftClipper(_split),
                                child: Image.memory(
                                    widget.project.beforeBytes,
                                    fit: BoxFit.cover),
                              ),
                              // Divider line + handle
                              Align(
                                alignment:
                                    Alignment(2 * _split - 1, 0),
                                child: Container(
                                  width: 3,
                                  color: DVColors.orange,
                                ),
                              ),
                              Align(
                                alignment:
                                    Alignment(2 * _split - 1, 0),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: DVColors.orange,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black
                                              .withOpacity(0.4),
                                          blurRadius: 10),
                                    ],
                                  ),
                                  child: const Icon(
                                      Icons.compare_arrows_rounded,
                                      color: Colors.white,
                                      size: 22),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                left: 12,
                                child: _tag('BEFORE'),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: _tag('AFTER',
                                    color: DVColors.orange),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Drag the handle to compare the original photo with the mockup.',
                style: text.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366)),
                      onPressed: () => _share(whatsapp: true),
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _share(whatsapp: false),
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: const Text('Share / Email'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, {Color color = Colors.black54}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
      );
}

class _LeftClipper extends CustomClipper<Rect> {
  _LeftClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftClipper oldClipper) =>
      oldClipper.fraction != fraction;
}
