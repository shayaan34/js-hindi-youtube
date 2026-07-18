import 'dart:typed_data';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Client management
// ---------------------------------------------------------------------------

enum ProjectStatus { lead, surveyDone, mockupSent, quoteSent, approved, installed }

extension ProjectStatusX on ProjectStatus {
  String get label => switch (this) {
        ProjectStatus.lead => 'Lead',
        ProjectStatus.surveyDone => 'Survey Done',
        ProjectStatus.mockupSent => 'Mockup Sent',
        ProjectStatus.quoteSent => 'Quote Sent',
        ProjectStatus.approved => 'Approved',
        ProjectStatus.installed => 'Installed',
      };

  Color get color => switch (this) {
        ProjectStatus.lead => const Color(0xFF9A9AA3),
        ProjectStatus.surveyDone => const Color(0xFF4FC3F7),
        ProjectStatus.mockupSent => const Color(0xFFFF8A3C),
        ProjectStatus.quoteSent => const Color(0xFFFFC24B),
        ProjectStatus.approved => const Color(0xFF3DDC84),
        ProjectStatus.installed => const Color(0xFFB388FF),
      };
}

enum BusinessCategory { restaurant, coffeeShop, office, mall, retail, gym, hotel, other }

extension BusinessCategoryX on BusinessCategory {
  String get label => switch (this) {
        BusinessCategory.restaurant => 'Restaurant',
        BusinessCategory.coffeeShop => 'Coffee Shop',
        BusinessCategory.office => 'Office',
        BusinessCategory.mall => 'Mall',
        BusinessCategory.retail => 'Retail Store',
        BusinessCategory.gym => 'Gym',
        BusinessCategory.hotel => 'Hotel',
        BusinessCategory.other => 'Other',
      };

  IconData get icon => switch (this) {
        BusinessCategory.restaurant => Icons.restaurant_rounded,
        BusinessCategory.coffeeShop => Icons.coffee_rounded,
        BusinessCategory.office => Icons.apartment_rounded,
        BusinessCategory.mall => Icons.local_mall_rounded,
        BusinessCategory.retail => Icons.storefront_rounded,
        BusinessCategory.gym => Icons.fitness_center_rounded,
        BusinessCategory.hotel => Icons.hotel_rounded,
        BusinessCategory.other => Icons.business_rounded,
      };
}

class Client {
  Client({
    required this.id,
    required this.businessName,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.category,
    required this.address,
    this.notes = '',
    this.status = ProjectStatus.lead,
    DateTime? createdAt,
    List<SitePhoto>? photos,
    List<MockupProject>? projects,
  })  : createdAt = createdAt ?? DateTime.now(),
        photos = photos ?? [],
        projects = projects ?? [];

  final String id;
  String businessName;
  String contactPerson;
  String phone;
  String email;
  BusinessCategory category;
  String address;
  String notes;
  ProjectStatus status;
  final DateTime createdAt;

  /// Site survey photos captured during a client visit.
  final List<SitePhoto> photos;

  /// Saved mockup projects for this client.
  final List<MockupProject> projects;

  Map<String, dynamic> toMap() => {
        'id': id,
        'businessName': businessName,
        'contactPerson': contactPerson,
        'phone': phone,
        'email': email,
        'category': category.name,
        'address': address,
        'notes': notes,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Client.fromMap(Map<String, dynamic> map) => Client(
        id: map['id'] as String,
        businessName: map['businessName'] as String? ?? '',
        contactPerson: map['contactPerson'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        email: map['email'] as String? ?? '',
        category: BusinessCategory.values.firstWhere(
            (c) => c.name == map['category'],
            orElse: () => BusinessCategory.other),
        address: map['address'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        status: ProjectStatus.values.firstWhere(
            (s) => s.name == map['status'],
            orElse: () => ProjectStatus.lead),
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
      );
}

/// A photo captured or uploaded at the client site. Bytes are kept in memory
/// for demo mode; when Firebase is enabled they are mirrored to Storage.
class SitePhoto {
  SitePhoto({
    required this.id,
    required this.bytes,
    DateTime? capturedAt,
    this.remoteUrl,
  }) : capturedAt = capturedAt ?? DateTime.now();

  final String id;
  final Uint8List bytes;
  final DateTime capturedAt;
  final String? remoteUrl;
}

// ---------------------------------------------------------------------------
// Mockup editor
// ---------------------------------------------------------------------------

enum OverlayKind {
  ledScreen,
  poster,
  vinylSticker,
  banner,
  standee,
  acrylicBoard,
  rollUpBanner,
  menuBoard,
  animation,
}

extension OverlayKindX on OverlayKind {
  String get label => switch (this) {
        OverlayKind.ledScreen => 'LED Screen',
        OverlayKind.poster => 'Poster',
        OverlayKind.vinylSticker => 'Vinyl Sticker',
        OverlayKind.banner => 'Banner',
        OverlayKind.standee => 'Standee',
        OverlayKind.acrylicBoard => 'Acrylic Board',
        OverlayKind.rollUpBanner => 'Roll-up Banner',
        OverlayKind.menuBoard => 'Menu Board',
        OverlayKind.animation => 'Animated LED',
      };

  IconData get icon => switch (this) {
        OverlayKind.ledScreen => Icons.tv_rounded,
        OverlayKind.poster => Icons.image_rounded,
        OverlayKind.vinylSticker => Icons.sticky_note_2_rounded,
        OverlayKind.banner => Icons.flag_rounded,
        OverlayKind.standee => Icons.accessibility_new_rounded,
        OverlayKind.acrylicBoard => Icons.crop_landscape_rounded,
        OverlayKind.rollUpBanner => Icons.view_day_rounded,
        OverlayKind.menuBoard => Icons.menu_book_rounded,
        OverlayKind.animation => Icons.play_circle_fill_rounded,
      };

  bool get isScreen =>
      this == OverlayKind.ledScreen || this == OverlayKind.animation;
}

enum MediaType { none, image, gif, lottie, video }

/// One draggable/resizable/rotatable element placed on top of a site photo.
class MockupOverlay {
  MockupOverlay({
    required this.id,
    required this.kind,
    this.mediaBytes,
    this.mediaType = MediaType.none,
    this.position = const Offset(120, 160),
    this.width = 200,
    this.height = 120,
    this.rotation = 0,
    this.tiltX = 0,
    this.tiltY = 0,
    this.brightness = 1.0,
    this.glow = true,
    this.shadow = true,
    this.reflection = false,
  });

  final String id;
  final OverlayKind kind;

  /// Uploaded artwork (PNG/JPG/GIF bytes, or Lottie JSON bytes).
  Uint8List? mediaBytes;
  MediaType mediaType;

  Offset position;
  double width;
  double height;

  /// Z-rotation in radians.
  double rotation;

  /// Perspective tilts in radians, applied with a perspective matrix so the
  /// artwork visually matches the wall plane.
  double tiltX;
  double tiltY;

  double brightness;
  bool glow;
  bool shadow;
  bool reflection;
}

/// A saved mockup: the flattened composited image plus its source photo.
class MockupProject {
  MockupProject({
    required this.id,
    required this.name,
    required this.beforeBytes,
    required this.afterBytes,
    this.folder = 'General',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  String folder;
  final Uint8List beforeBytes;
  final Uint8List afterBytes;
  final DateTime createdAt;
}

// ---------------------------------------------------------------------------
// AI analysis
// ---------------------------------------------------------------------------

enum ZoneKind { wall, window, counter, entrance, pillar, displayArea }

extension ZoneKindX on ZoneKind {
  String get label => switch (this) {
        ZoneKind.wall => 'Wall',
        ZoneKind.window => 'Window / Glass',
        ZoneKind.counter => 'Counter',
        ZoneKind.entrance => 'Entrance',
        ZoneKind.pillar => 'Pillar',
        ZoneKind.displayArea => 'Display Area',
      };

  Color get color => switch (this) {
        ZoneKind.wall => const Color(0xFFFF6A00),
        ZoneKind.window => const Color(0xFF4FC3F7),
        ZoneKind.counter => const Color(0xFFFFC24B),
        ZoneKind.entrance => const Color(0xFF3DDC84),
        ZoneKind.pillar => const Color(0xFFB388FF),
        ZoneKind.displayArea => const Color(0xFFFF5252),
      };
}

/// A detected placement zone, in normalized (0–1) photo coordinates.
class DetectedZone {
  const DetectedZone({
    required this.kind,
    required this.rect,
    required this.confidence,
    required this.recommended,
    this.estimatedWidthM,
    this.estimatedHeightM,
  });

  final ZoneKind kind;
  final Rect rect;
  final double confidence;

  /// True when the AI flags this zone as a top advertising location.
  final bool recommended;
  final double? estimatedWidthM;
  final double? estimatedHeightM;
}

class AiAnalysis {
  const AiAnalysis({
    required this.zones,
    required this.bestZoneIndex,
    required this.recommendedScreenInches,
    required this.recommendedPosterSize,
    required this.visibilityScore,
    required this.attentionScore,
    required this.estimatedRoomWidthM,
    required this.estimatedRoomDepthM,
    required this.estimatedCostInr,
    required this.narrative,
  });

  final List<DetectedZone> zones;
  final int bestZoneIndex;
  final int recommendedScreenInches;
  final String recommendedPosterSize;

  /// 0–100.
  final int visibilityScore;
  final int attentionScore;
  final double estimatedRoomWidthM;
  final double estimatedRoomDepthM;
  final double estimatedCostInr;
  final String narrative;
}

// ---------------------------------------------------------------------------
// Proposals
// ---------------------------------------------------------------------------

class ProposalLineItem {
  ProposalLineItem({
    required this.description,
    required this.dimensions,
    required this.location,
    required this.quantity,
    required this.unitPrice,
  });

  String description;
  String dimensions;
  String location;
  int quantity;
  double unitPrice;

  double get total => quantity * unitPrice;
}

// ---------------------------------------------------------------------------
// Users & dashboard
// ---------------------------------------------------------------------------

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.company = '',
    this.photoUrl,
  });

  final String uid;
  final String name;
  final String email;
  final String company;
  final String? photoUrl;
}

class DashboardStats {
  const DashboardStats({
    required this.totalClients,
    required this.totalProjects,
    required this.revenue,
    required this.pendingQuotes,
    required this.completedInstallations,
  });

  final int totalClients;
  final int totalProjects;
  final double revenue;
  final int pendingQuotes;
  final int completedInstallations;
}
