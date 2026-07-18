import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'ai_suggestions_screen.dart';
import 'ar_preview_screen.dart';
import 'before_after_screen.dart';
import 'client_form_screen.dart';
import 'mockup_editor_screen.dart';
import 'proposal_screen.dart';

/// Client profile: site photos, saved mockups and workflow actions.
class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  final _picker = ImagePicker();

  Future<void> _capturePhoto(Client client) async {
    final state = context.read<AppState>();
    try {
      final shot = await _picker.pickImage(
          source: ImageSource.camera, maxWidth: 1920, imageQuality: 88);
      if (shot == null) return;
      state.addPhoto(client, await shot.readAsBytes());
    } catch (_) {
      // Camera unavailable (desktop/web) — fall back to gallery.
      await _uploadPhotos(client);
    }
  }

  Future<void> _uploadPhotos(Client client) async {
    final state = context.read<AppState>();
    final files = await _picker.pickMultiImage(
        maxWidth: 1920, imageQuality: 88);
    for (final f in files) {
      state.addPhoto(client, await f.readAsBytes());
    }
  }

  void _openEditor(Client client, SitePhoto photo) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MockupEditorScreen(client: client, photo: photo)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final client = state.clients.firstWhere(
      (c) => c.id == widget.clientId,
      orElse: () => Client(
          id: '',
          businessName: 'Deleted',
          contactPerson: '',
          phone: '',
          email: '',
          category: BusinessCategory.other,
          address: ''),
    );
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(client.businessName),
        actions: [
          IconButton(
            tooltip: 'Edit client',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ClientFormScreen(existing: client))),
          ),
          IconButton(
            tooltip: 'Delete client',
            icon: const Icon(Icons.delete_outline, color: DVColors.danger),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: DVColors.surfaceRaised,
                  title: const Text('Delete client?'),
                  content: Text(
                      'This removes ${client.businessName}, all photos and mockups.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete',
                            style: TextStyle(color: DVColors.danger))),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                context.read<AppState>().deleteClient(client);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FadeSlideIn(
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: DVColors.orangeGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(client.category.icon,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(client.businessName,
                                  style: text.titleLarge),
                              Text(client.category.label,
                                  style: text.bodySmall),
                            ],
                          ),
                        ),
                        StatusChip(
                            label: client.status.label,
                            color: client.status.color),
                      ],
                    ),
                    const Divider(height: 24),
                    _infoRow(Icons.person_outline, client.contactPerson),
                    _infoRow(Icons.phone_outlined, client.phone),
                    _infoRow(Icons.mail_outline, client.email),
                    _infoRow(Icons.location_on_outlined, client.address),
                    if (client.notes.isNotEmpty)
                      _infoRow(Icons.notes_outlined, client.notes),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delayMs: 80,
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.photo_camera_rounded,
                      label: 'Capture',
                      onTap: () => _capturePhoto(client),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.upload_rounded,
                      label: 'Upload',
                      onTap: () => _uploadPhotos(client),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.view_in_ar_rounded,
                      label: 'AR view',
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  ARPreviewScreen(client: client))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.description_rounded,
                      label: 'Proposal',
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  ProposalScreen(client: client))),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Site photos (${client.photos.length})',
              trailing: TextButton.icon(
                onPressed: () => _uploadPhotos(client),
                icon: const Icon(Icons.add_photo_alternate_outlined,
                    size: 18, color: DVColors.orange),
                label: const Text('Add',
                    style: TextStyle(color: DVColors.orange)),
              ),
            ),
            if (client.photos.isEmpty)
              GlassCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const Icon(Icons.photo_camera_back_outlined,
                        size: 40, color: DVColors.textSecondary),
                    const SizedBox(height: 10),
                    Text(
                      'No photos yet. Capture the walls, counters and '
                      'entrance to start building mockups.',
                      style: text.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 4 / 3,
                ),
                itemCount: client.photos.length,
                itemBuilder: (context, i) {
                  final photo = client.photos[i];
                  return _PhotoTile(
                    photo: photo,
                    onEdit: () => _openEditor(client, photo),
                    onAnalyze: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => AiSuggestionsScreen(
                                client: client, photo: photo))),
                  );
                },
              ),
            const SizedBox(height: 24),
            SectionHeader(title: 'Mockups (${client.projects.length})'),
            if (client.projects.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Open a site photo in the editor to create your first mockup.',
                  style: text.bodySmall,
                ),
              )
            else
              ...client.projects.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: const EdgeInsets.all(10),
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                BeforeAfterScreen(project: p))),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(p.afterBytes,
                              width: 88, height: 60, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: text.titleMedium),
                              Text(p.folder, style: text.bodySmall),
                            ],
                          ),
                        ),
                        const Icon(Icons.compare_rounded,
                            color: DVColors.orange),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: DVColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: DVColors.orange),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile(
      {required this.photo, required this.onEdit, required this.onAnalyze});

  final SitePhoto photo;
  final VoidCallback onEdit;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(photo.bytes, fit: BoxFit.cover),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _chipButton(
                      context, Icons.auto_awesome_rounded, 'AI', onAnalyze),
                  _chipButton(
                      context, Icons.design_services_rounded, 'Mockup', onEdit),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipButton(BuildContext context, IconData icon, String label,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: DVColors.orange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
