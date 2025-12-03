import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentora_app/theme.dart';
import 'package:mentora_app/models/roadmap_node.dart';
import 'package:mentora_app/providers/app_providers.dart';

class RoadmapPage extends ConsumerStatefulWidget {
  const RoadmapPage({super.key});

  @override
  ConsumerState<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends ConsumerState<RoadmapPage> {
  NodeStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox();

        final nodesAsync = ref.watch(roadmapNodesProvider(user.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Roadmap'),
            actions: [
              PopupMenuButton<NodeStatus?>(
                icon: const Icon(Icons.filter_list),
                onSelected: (status) => setState(() => _filterStatus = status),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: null, child: Text('All')),
                  const PopupMenuItem(value: NodeStatus.unlocked, child: Text('Unlocked')),
                  const PopupMenuItem(value: NodeStatus.inProgress, child: Text('In Progress')),
                  const PopupMenuItem(value: NodeStatus.completed, child: Text('Completed')),
                  const PopupMenuItem(value: NodeStatus.locked, child: Text('Locked')),
                ],
              ),
            ],
          ),
          body: nodesAsync.when(
            data: (nodes) {
              final filteredNodes = _filterStatus == null
                  ? nodes
                  : nodes.where((n) => n.status == _filterStatus).toList();

              if (filteredNodes.isEmpty) {
                return const Center(child: Text('No nodes found'));
              }

              final regions = <String, List<RoadmapNode>>{};
              for (final node in filteredNodes) {
                regions.putIfAbsent(node.region, () => []).add(node);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: regions.length,
                itemBuilder: (context, index) {
                  final region = regions.keys.elementAt(index);
                  final regionNodes = regions[region]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppGradients.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getRegionEmoji(region),
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              region,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...regionNodes.map((node) => RoadmapNodeCard(node: node)),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  String _getRegionEmoji(String region) {
    switch (region) {
      case 'Grasslands':
        return '🌱';
      case 'Forest':
        return '🌲';
      case 'Mountains':
        return '⛰️';
      case 'City':
        return '🏙️';
      case 'Futuristic':
        return '🚀';
      default:
        return '📍';
    }
  }
}

class RoadmapNodeCard extends ConsumerWidget {
  final RoadmapNode node;

  const RoadmapNodeCard({super.key, required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getNodeColor(node.status);
    final icon = _getNodeIcon(node.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showNodeDetails(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _getStatusText(node.status),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.xpGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.xpGold, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${node.xpReward} XP',
                          style: const TextStyle(
                            color: AppColors.xpGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                node.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${node.estimatedHours}h',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (node.providerName != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.school, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      node.providerName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
              if (node.status == NodeStatus.inProgress && node.progress > 0) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: node.progress,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getNodeColor(NodeStatus status) {
    switch (status) {
      case NodeStatus.completed:
        return AppColors.nodeCompleted;
      case NodeStatus.inProgress:
        return AppColors.nodeInProgress;
      case NodeStatus.unlocked:
        return AppColors.nodeUnlocked;
      case NodeStatus.locked:
        return AppColors.nodeLocked;
    }
  }

  IconData _getNodeIcon(NodeType type) {
    switch (type) {
      case NodeType.course:
        return Icons.school;
      case NodeType.project:
        return Icons.construction;
      case NodeType.skillCheck:
        return Icons.quiz;
      case NodeType.bossChallenge:
        return Icons.shield;
      case NodeType.restStop:
        return Icons.local_cafe;
      case NodeType.bonus:
        return Icons.card_giftcard;
    }
  }

  String _getStatusText(NodeStatus status) {
    switch (status) {
      case NodeStatus.completed:
        return 'Completed ✓';
      case NodeStatus.inProgress:
        return 'In Progress...';
      case NodeStatus.unlocked:
        return 'Available';
      case NodeStatus.locked:
        return 'Locked 🔒';
    }
  }

  void _showNodeDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    node.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(context, 'XP Reward', '${node.xpReward} XP', Icons.star),
                    _buildDetailRow(context, 'Estimated Time', '${node.estimatedHours} hours', Icons.access_time),
                    if (node.providerName != null)
                      _buildDetailRow(context, 'Provider', node.providerName!, Icons.school),
                    if (node.skills.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Skills',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: node.skills.map((skill) => Chip(
                          label: Text(skill),
                          backgroundColor: AppColors.gradientBlue.withValues(alpha: 0.15),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (node.status == NodeStatus.unlocked)
              ElevatedButton(
                onPressed: () async {
                  final roadmapService = ref.read(roadmapServiceProvider);
                  await roadmapService.updateNode(
                    node.copyWith(status: NodeStatus.inProgress, startedAt: DateTime.now()),
                  );
                  ref.invalidate(roadmapNodesProvider);
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gradientBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Start Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.gradientBlue),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
