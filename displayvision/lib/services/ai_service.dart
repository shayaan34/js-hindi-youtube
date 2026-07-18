import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../models/models.dart';

/// AI vision service: wall/zone detection, placement suggestions, room
/// dimension estimation and cost estimation.
///
/// In demo mode a deterministic heuristic engine produces realistic-looking
/// results instantly, so the whole workflow can be demonstrated offline.
///
/// To use a real model, supply an API key via
/// `--dart-define=AI_API_KEY=...` and implement the request in
/// [_callVisionApi]. Both OpenAI Vision (gpt-4o) and Gemini Vision accept an
/// image plus the prompt below and return the same JSON schema that
/// [AiAnalysis] parses:
///
/// ```text
/// Analyze this interior photo of a business for digital advertising
/// placement. Return JSON: { "zones": [{ "kind":
/// "wall|window|counter|entrance|pillar|displayArea", "rect": [x, y, w, h]
/// (normalized 0-1), "confidence": 0-1, "recommended": bool,
/// "estimatedWidthM": number, "estimatedHeightM": number }],
/// "roomWidthM": number, "roomDepthM": number, "bestZoneIndex": int,
/// "screenInches": 32|43|55|65|75, "posterSize": string,
/// "visibilityScore": 0-100, "attentionScore": 0-100, "narrative": string }
/// ```
class AiVisionService {
  /// Analyze a site photo and return zones + recommendations.
  Future<AiAnalysis> analyzePhoto(Uint8List photoBytes,
      {BusinessCategory category = BusinessCategory.other}) async {
    if (AppConfig.aiApiKey.isNotEmpty) {
      try {
        return await _callVisionApi(photoBytes, category);
      } catch (_) {
        // Fall through to the on-device heuristic engine.
      }
    }
    return _heuristicAnalysis(photoBytes, category);
  }

  Future<AiAnalysis> _callVisionApi(
      Uint8List photoBytes, BusinessCategory category) async {
    // Integration point for OpenAI Vision / Gemini Vision (see class docs).
    // Kept unimplemented in the mockup build so it carries no http dependency.
    throw UnimplementedError(
        'Wire ${AppConfig.visionBackend.name} here with your API key.');
  }

  /// Deterministic pseudo-detection seeded from the photo bytes, so the same
  /// photo always produces the same "AI" result.
  Future<AiAnalysis> _heuristicAnalysis(
      Uint8List bytes, BusinessCategory category) async {
    await Future.delayed(const Duration(milliseconds: 1400)); // "thinking"
    final seed = bytes.isEmpty
        ? 42
        : bytes.length ^ bytes.first ^ bytes.last ^ bytes[bytes.length ~/ 2];
    final rng = Random(seed);

    double jitter(double base, double spread) =>
        base + (rng.nextDouble() - 0.5) * spread;

    final zones = <DetectedZone>[
      DetectedZone(
        kind: ZoneKind.wall,
        rect: Rect.fromLTWH(jitter(0.12, 0.06), jitter(0.14, 0.06),
            jitter(0.42, 0.08), jitter(0.38, 0.08)),
        confidence: jitter(0.93, 0.06),
        recommended: true,
        estimatedWidthM: jitter(3.6, 0.8),
        estimatedHeightM: jitter(2.6, 0.4),
      ),
      DetectedZone(
        kind: ZoneKind.window,
        rect: Rect.fromLTWH(jitter(0.62, 0.06), jitter(0.18, 0.05),
            jitter(0.24, 0.05), jitter(0.34, 0.06)),
        confidence: jitter(0.85, 0.08),
        recommended: false,
        estimatedWidthM: jitter(1.8, 0.4),
        estimatedHeightM: jitter(2.0, 0.3),
      ),
      DetectedZone(
        kind: ZoneKind.counter,
        rect: Rect.fromLTWH(jitter(0.30, 0.08), jitter(0.62, 0.06),
            jitter(0.36, 0.08), jitter(0.20, 0.05)),
        confidence: jitter(0.81, 0.10),
        recommended: false,
        estimatedWidthM: jitter(2.4, 0.6),
        estimatedHeightM: jitter(1.1, 0.2),
      ),
      DetectedZone(
        kind: ZoneKind.entrance,
        rect: Rect.fromLTWH(jitter(0.02, 0.02), jitter(0.30, 0.08),
            jitter(0.14, 0.04), jitter(0.52, 0.08)),
        confidence: jitter(0.77, 0.10),
        recommended: false,
      ),
      if (rng.nextBool())
        DetectedZone(
          kind: ZoneKind.pillar,
          rect: Rect.fromLTWH(jitter(0.52, 0.04), jitter(0.20, 0.05),
              jitter(0.08, 0.02), jitter(0.55, 0.08)),
          confidence: jitter(0.72, 0.10),
          recommended: false,
        ),
    ];

    final screenSizes = [32, 43, 55, 65, 75];
    final wall = zones.first;
    final wallWidth = wall.estimatedWidthM ?? 3.5;
    // Pick a screen whose diagonal is roughly a third of the wall width.
    final idealInches = wallWidth * 0.33 * 39.37;
    final screen = screenSizes.reduce((a, b) =>
        (a - idealInches).abs() < (b - idealInches).abs() ? a : b);

    final visibility = 70 + rng.nextInt(26);
    final attention = 62 + rng.nextInt(30);
    final cost = screen * 950.0 + 15000 + rng.nextInt(8000);

    return AiAnalysis(
      zones: zones,
      bestZoneIndex: 0,
      recommendedScreenInches: screen,
      recommendedPosterSize:
          wallWidth > 3.2 ? '24" × 36" (A1)' : '18" × 24" (A2)',
      visibilityScore: visibility,
      attentionScore: attention,
      estimatedRoomWidthM: jitter(5.8, 1.5),
      estimatedRoomDepthM: jitter(7.4, 2.0),
      estimatedCostInr: cost,
      narrative:
          'The primary wall facing the ${category.label.toLowerCase()} seating '
          'and entry flow offers the strongest sightlines. A $screen" LED '
          'display mounted at eye level (~1.6 m) on this wall maximizes dwell-'
          'time exposure. The glass frontage suits vinyl branding, and the '
          'counter area is ideal for a digital menu board. Estimated '
          'visibility score: $visibility/100.',
    );
  }

  /// Day / night preview: returns a color filter matrix for the mockup.
  static List<double> lightingMatrix({required bool night}) {
    if (!night) return _identityMatrix;
    // Cool, dimmed ambient with preserved highlights — screens pop at night.
    return const [
      0.55, 0, 0, 0, 0,
      0, 0.58, 0, 0, 4,
      0, 0, 0.75, 0, 12,
      0, 0, 0, 1, 0,
    ];
  }

  static const List<double> _identityMatrix = [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];
}
