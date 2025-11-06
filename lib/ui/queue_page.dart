import 'package:flutter/material.dart';
import 'package:futegestor/state/app_state.dart';
import 'package:futegestor/state/app_state_scope.dart';
import 'package:futegestor/models/player.dart';

class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.appWatch();
    final perTeam = state.settings.playersPerTeam;
    final arrival = state.arrivalOrder;
    // Generate queue from arrival after first two teams
    final remaining = arrival.skip(perTeam * 2).toList();
    final teams = <List<String>>[];
    for (var i = 0; i < remaining.length; i += perTeam) {
      teams.add(remaining.sublist(i, (i + perTeam).clamp(0, remaining.length)));
    }
    final playersMap = {for (final p in state.players) p.id: p};

    return Scaffold(
      appBar: AppBar(title: const Text('Próximos Times')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: teams.isEmpty
            ? const Center(child: Text('Nenhum time aguardando.'))
            : _TeamsQueue(teams: teams, playersMap: playersMap),
      ),
    );
  }
}

class _TeamsQueue extends StatefulWidget {
  final List<List<String>> teams;
  final Map<String, Player> playersMap;
  const _TeamsQueue({required this.teams, required this.playersMap});

  @override
  State<_TeamsQueue> createState() => _TeamsQueueState();
}

class _TeamsQueueState extends State<_TeamsQueue> {
  late List<List<String>> teams;

  @override
  void initState() {
    super.initState();
    teams = widget.teams.map((e) => [...e]).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            itemCount: teams.length,
            onReorder: (o, n) {
              setState(() {
                if (n > o) n -= 1;
                final item = teams.removeAt(o);
                teams.insert(n, item);
              });
            },
            itemBuilder: (context, i) {
              final team = teams[i];
              return Card(
                key: ValueKey('team-$i'),
                child: ListTile(
                  title: Text('Time ${i + 1 + 2}'),
                  subtitle: Text(team.map((id) => widget.playersMap[id]?.name ?? '').join(', ')),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Atualizar Ordem'),
            onPressed: () {
              // Persist by rewriting arrival tail in state
              final state = context.appRead();
              final head = state.arrivalOrder.take(state.settings.playersPerTeam * 2).toList();
              final newTail = teams.expand((e) => e).toList();
              // Re-compose arrival
              final merged = [...head, ...newTail];
              // Direct write: Use internal method via reorder operations is verbose; call private replacement via settings update
              // Since we don't expose a setter, do it using edit of storage keys minimally via state: temporary method below
              _applyNewArrival(state, merged);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ordem atualizada')));
            },
          ),
        ),
      ],
    );
  }

  void _applyNewArrival(AppState state, List<String> merged) {
    // Minimal hack: directly update via reflection of state internals is not allowed.
    // Provide a dedicated method on AppState ideally. For now, use edit by removing/adding in order.
    // We'll call a method on AppState by name using cascade that we add shortly.
    state.replaceArrival(merged);
  }
}
