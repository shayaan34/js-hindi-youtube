import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_config.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../services/ai_service.dart';
import 'mockup_editor_screen.dart';

/// Runs AI analysis on a site photo and presents placement recommendations,
/// detected zones, room dimensions, scores and cost estimate.
class AiSuggestionsScreen extends StatefulWidget {
  const AiSuggestionsScreen(
      {super.key, required this.client, required this.photo});

  final Client client;
  final SitePhoto photo;

  @override
  State<AiSuggestionsScreen> createState() => _AiSuggestionsScreenState();
}

class _AiSuggestionsScreenState extends State<AiSuggestionsScreen> {
  final _ai = AiVisionService();
  AiAnalysis? _analysis;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final result = await _ai.analyzePhoto(widget.photo.bytes,
        category: widget.client.category);
    if (mounted) setState(() => _analysis = result);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final a = _analysis;
    final currency = NumberFormat.currency(
        locale: 'en_IN', symbol: AppConfig.currencySymbol, decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Suggestions')),
      body: a == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: DVColors.orange),
                  const SizedBox(height: 16),
                  Text('Detecting walls, perspective & dimensions…',
                      style: text.bodySmall),
                ],
              ),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  FadeSlideIn(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: LayoutBuilder(
                          builder: (context, constraints) => Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(widget.photo.bytes,
                                  fit: BoxFit.cover),
                              ...a.zones.map((z) {
                                final rect = Rect.fromLTWH(
                                  z.rect.left * constraints.maxWidth,
                                  z.rect.top * constraints.maxHeight,
                                  z.rect.width * constraints.maxWidth,
                                  z.rect.height * constraints.maxHeight,
                                );
                                return Positioned.fromRect(
                                  rect: rect,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: z.color,
                                          width: z.recommended ? 2.5 : 1.2),
                                      color: z.color.withOpacity(
                                          z.recommended ? 0.14 : 0.05),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Container(
                                        margin: const EdgeInsets.all(3),
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 5, vertical: 2),
                                        color: z.color,
                                        child: Text(
                                          '${z.recommended ? '★ ' : ''}${z.kind.label}',
                                          style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.black,
                                              fontWeight:
                                                  FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    delayMs: 80,
                    child: Row(
                      children: [
                        Expanded(
                            child: _ScoreRing(
                                label: 'Visibility',
                                score: a.visibilityScore)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _ScoreRing(
                                label: 'Attention',
                                score: a.attentionScore)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delayMs: 140,
                    child: GlassCard(
                      glow: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.auto_awesome_rounded,
                                color: DVColors.orange, size: 18),
                            const SizedBox(width: 8),
                            Text('Recommendation', style: text.titleMedium),
                          ]),
                          const SizedBox(height: 10),
                          Text(a.narrative, style: text.bodyMedium),
                          const Divider(height: 24),
                          _row('Best wall',
                              a.zones[a.bestZoneIndex].kind.label),
                          _row('Recommended screen',
                              '${a.recommendedScreenInches}" LED display'),
                          _row('Recommended poster',
                              a.recommendedPosterSize),
                          _row('Wall size (est.)',
                              '${a.zones.first.estimatedWidthM?.toStringAsFixed(1)} m × ${a.zones.first.estimatedHeightM?.toStringAsFixed(1)} m'),
                          _row('Room (est.)',
                              '${a.estimatedRoomWidthM.toStringAsFixed(1)} m × ${a.estimatedRoomDepthM.toStringAsFixed(1)} m'),
                          _row('Installation cost (est.)',
                              currency.format(a.estimatedCostInr)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    delayMs: 200,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.design_services_rounded),
                      label: const Text('Build this mockup'),
                      onPressed: () => Navigator.of(context)
                          .pushReplacement(MaterialPageRoute(
                              builder: (_) => MockupEditorScreen(
                                  client: widget.client,
                                  photo: widget.photo))),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _row(String label, String value) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 150, child: Text(label, style: text.bodySmall)),
          Expanded(
            child: Text(value,
                style: text.bodyMedium!
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = score >= 80
        ? DVColors.success
        : score >= 60
            ? DVColors.orange
            : DVColors.warning;
    return GlassCard(
      child: Column(
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: score / 100),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) =>
                      CircularProgressIndicator(
                    value: value,
                    strokeWidth: 6,
                    color: color,
                    backgroundColor: DVColors.stroke,
                  ),
                ),
                Center(
                    child:
                        Text('$score', style: text.headlineSmall)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('$label score', style: text.bodySmall),
        ],
      ),
    );
  }
}
