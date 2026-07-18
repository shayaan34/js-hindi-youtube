import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'client_detail_screen.dart';
import 'client_form_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _query = '';
  ProjectStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    var results = state.searchClients(_query);
    if (_statusFilter != null) {
      results = results.where((c) => c.status == _statusFilter).toList();
    }
    final text = Theme.of(context).textTheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-client',
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ClientFormScreen())),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add client'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('Clients', style: text.headlineSmall),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search by name, contact, phone, area…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _statusFilter == null,
                      selectedColor: DVColors.orange.withOpacity(0.2),
                      onSelected: (_) =>
                          setState(() => _statusFilter = null),
                    ),
                  ),
                  ...ProjectStatus.values.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s.label),
                        selected: _statusFilter == s,
                        selectedColor: s.color.withOpacity(0.2),
                        onSelected: (sel) => setState(
                            () => _statusFilter = sel ? s : null),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 42, color: DVColors.textSecondary),
                          const SizedBox(height: 8),
                          Text('No clients found', style: text.bodySmall),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final client = results[i];
                        return FadeSlideIn(
                          delayMs: (i * 40).clamp(0, 240).toInt(),
                          child: _ClientCard(client: client),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ClientDetailScreen(clientId: client.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: DVColors.orangeGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(client.category.icon,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.businessName, style: text.titleMedium),
                    Text(client.category.label, style: text.bodySmall),
                  ],
                ),
              ),
              StatusChip(
                  label: client.status.label, color: client.status.color),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: DVColors.textSecondary),
              const SizedBox(width: 4),
              Text(client.contactPerson, style: text.bodySmall),
              const SizedBox(width: 14),
              const Icon(Icons.phone_outlined,
                  size: 14, color: DVColors.textSecondary),
              const SizedBox(width: 4),
              Text(client.phone, style: text.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: DVColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(client.address,
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text(
                '${client.photos.length} photos • ${client.projects.length} mockups',
                style: text.bodySmall!.copyWith(color: DVColors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
