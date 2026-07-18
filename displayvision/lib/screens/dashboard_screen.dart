import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_config.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'client_detail_screen.dart';
import 'client_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stats = state.stats;
    final text = Theme.of(context).textTheme;
    final currency = NumberFormat.compactCurrency(
        locale: 'en_IN', symbol: AppConfig.currencySymbol);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FadeSlideIn(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, ${state.user?.name ?? ''} 👋',
                          style: text.headlineSmall),
                      const SizedBox(height: 2),
                      Text(
                          state.user?.company.isNotEmpty == true
                              ? state.user!.company
                              : AppConfig.companyName,
                          style: text.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: () => context.read<AppState>().signOut(),
                  icon: const Icon(Icons.logout_rounded,
                      color: DVColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideIn(
            delayMs: 60,
            child: GlassCard(
              glow: true,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start a site survey', style: text.titleLarge),
                        const SizedBox(height: 6),
                        Text(
                          'Add a client, capture photos and build a mockup '
                          'they can approve on the spot.',
                          style: text.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: 170,
                          child: FilledButton.icon(
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ClientFormScreen())),
                            icon: const Icon(Icons.person_add_alt_1_rounded,
                                size: 18),
                            label: const Text('New client'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: DVColors.orangeGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.storefront_rounded,
                        color: Colors.white, size: 40),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideIn(
            delayMs: 120,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount:
                  MediaQuery.of(context).size.width > 700 ? 4 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                StatTile(
                    icon: Icons.people_rounded,
                    label: 'Total clients',
                    value: '${stats.totalClients}'),
                StatTile(
                    icon: Icons.movie_filter_rounded,
                    label: 'Mockups created',
                    value: '${stats.totalProjects}',
                    accent: DVColors.orangeBright),
                StatTile(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Pipeline revenue',
                    value: currency.format(stats.revenue),
                    accent: DVColors.success),
                StatTile(
                    icon: Icons.pending_actions_rounded,
                    label: 'Pending quotes',
                    value: '${stats.pendingQuotes}',
                    accent: DVColors.warning),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideIn(
            delayMs: 180,
            child: SectionHeader(title: 'Recent clients'),
          ),
          ...List.generate(state.clients.take(4).length, (i) {
            final client = state.clients[i];
            return FadeSlideIn(
              delayMs: 220 + i * 60,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecentClientTile(client: client),
              ),
            );
          }),
          if (state.clients.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No clients yet — add your first client to begin.',
                  style: text.bodySmall, textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}

class _RecentClientTile extends StatelessWidget {
  const _RecentClientTile({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ClientDetailScreen(clientId: client.id))),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DVColors.orange.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(client.category.icon,
                color: DVColors.orange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.businessName, style: text.titleMedium),
                const SizedBox(height: 2),
                Text('${client.contactPerson} • ${client.address}',
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(label: client.status.label, color: client.status.color),
        ],
      ),
    );
  }
}
