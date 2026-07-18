import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_config.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';

/// Admin dashboard: company-wide KPIs and a pipeline breakdown.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stats = state.stats;
    final text = Theme.of(context).textTheme;
    final currency = NumberFormat.compactCurrency(
        locale: 'en_IN', symbol: AppConfig.currencySymbol);

    final byStatus = <ProjectStatus, int>{
      for (final s in ProjectStatus.values)
        s: state.clients.where((c) => c.status == s).length,
    };
    final maxCount =
        byStatus.values.fold<int>(1, (m, v) => v > m ? v : m);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FadeSlideIn(
              child: Text('Admin Dashboard', style: text.headlineSmall)),
          const SizedBox(height: 4),
          Text('Company-wide performance overview', style: text.bodySmall),
          const SizedBox(height: 20),
          FadeSlideIn(
            delayMs: 60,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount:
                  MediaQuery.of(context).size.width > 700 ? 5 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                StatTile(
                    icon: Icons.people_rounded,
                    label: 'Total clients',
                    value: '${stats.totalClients}'),
                StatTile(
                    icon: Icons.movie_filter_rounded,
                    label: 'Projects',
                    value: '${stats.totalProjects}',
                    accent: DVColors.orangeBright),
                StatTile(
                    icon: Icons.payments_rounded,
                    label: 'Revenue',
                    value: currency.format(stats.revenue),
                    accent: DVColors.success),
                StatTile(
                    icon: Icons.pending_actions_rounded,
                    label: 'Pending quotes',
                    value: '${stats.pendingQuotes}',
                    accent: DVColors.warning),
                StatTile(
                    icon: Icons.task_alt_rounded,
                    label: 'Installations',
                    value: '${stats.completedInstallations}',
                    accent: const Color(0xFFB388FF)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const FadeSlideIn(
              delayMs: 120,
              child: SectionHeader(title: 'Sales pipeline')),
          FadeSlideIn(
            delayMs: 160,
            child: GlassCard(
              child: Column(
                children: ProjectStatus.values.map((s) {
                  final count = byStatus[s]!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 100,
                            child:
                                Text(s.label, style: text.bodySmall)),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                  begin: 0, end: count / maxCount),
                              duration:
                                  const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) =>
                                  LinearProgressIndicator(
                                value: value,
                                minHeight: 10,
                                color: s.color,
                                backgroundColor: DVColors.stroke,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          child: Text('$count',
                              textAlign: TextAlign.end,
                              style: text.titleMedium),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const FadeSlideIn(
              delayMs: 200,
              child: SectionHeader(title: 'Cloud & team')),
          FadeSlideIn(
            delayMs: 240,
            child: GlassCard(
              child: Column(
                children: [
                  _row(
                      context,
                      Icons.cloud_done_rounded,
                      'Cloud storage',
                      AppConfig.useFirebase
                          ? 'Firebase Storage connected'
                          : 'Demo mode — enable Firebase in AppConfig',
                      AppConfig.useFirebase
                          ? DVColors.success
                          : DVColors.warning),
                  const Divider(height: 20),
                  _row(
                      context,
                      Icons.sync_rounded,
                      'Offline sync queue',
                      state.pendingSyncCount == 0
                          ? 'All changes synced'
                          : '${state.pendingSyncCount} pending',
                      state.pendingSyncCount == 0
                          ? DVColors.success
                          : DVColors.warning),
                  const Divider(height: 20),
                  _row(context, Icons.groups_rounded, 'Team',
                      '1 active member (multi-user via Firebase Auth)',
                      DVColors.orange),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String title,
      String subtitle, Color color) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleMedium),
              Text(subtitle, style: text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
