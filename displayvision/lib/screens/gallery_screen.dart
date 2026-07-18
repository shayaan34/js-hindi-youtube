import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'before_after_screen.dart';

/// Project gallery: all saved mockups grouped into folders, with export
/// and share actions.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  String? _folder;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final text = Theme.of(context).textTheme;

    final all = <MockupProject>[
      for (final client in state.clients) ...client.projects,
    ];
    final folders = all.map((p) => p.folder).toSet().toList()..sort();
    final visible = _folder == null
        ? all
        : all.where((p) => p.folder == _folder).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text('Project Gallery', style: text.headlineSmall),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('${all.length} saved mockups', style: text.bodySmall),
          ),
          if (folders.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: const Icon(Icons.folder_rounded,
                          size: 16, color: DVColors.orange),
                      label: const Text('All folders'),
                      selected: _folder == null,
                      selectedColor: DVColors.orange.withOpacity(0.2),
                      onSelected: (_) => setState(() => _folder = null),
                    ),
                  ),
                  ...folders.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: const Icon(Icons.folder_outlined,
                            size: 16, color: DVColors.textSecondary),
                        label: Text(f),
                        selected: _folder == f,
                        selectedColor: DVColors.orange.withOpacity(0.2),
                        onSelected: (sel) =>
                            setState(() => _folder = sel ? f : null),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_outlined,
                            size: 44, color: DVColors.textSecondary),
                        const SizedBox(height: 10),
                        Text(
                          'No mockups yet.\nOpen a client photo in the '
                          'Mockup Studio to create one.',
                          style: text.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: visible.length,
                    itemBuilder: (context, i) {
                      final project = visible[i];
                      return FadeSlideIn(
                        delayMs: (i * 50).clamp(0, 300).toInt(),
                        child: _MockupCard(project: project),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MockupCard extends StatelessWidget {
  const _MockupCard({required this.project});

  final MockupProject project;

  Future<void> _export(BuildContext context) async {
    await Share.shareXFiles(
      [
        XFile.fromData(project.afterBytes,
            mimeType: 'image/png', name: '${project.name}.png'),
        XFile.fromData(project.beforeBytes,
            mimeType: 'image/png', name: '${project.name}-before.png'),
      ],
      text: '${project.name} — created with DisplayVision',
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BeforeAfterScreen(project: project))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                width: double.infinity,
                child: Image.memory(project.afterBytes, fit: BoxFit.cover),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.name,
                          style: text.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(project.folder,
                          style: text.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Export / share',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.ios_share_rounded,
                      size: 18, color: DVColors.orange),
                  onPressed: () => _export(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
