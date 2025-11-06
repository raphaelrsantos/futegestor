import 'package:flutter/material.dart';
import 'package:futegestor/models/player.dart';
import 'package:futegestor/state/app_state.dart';
import 'package:futegestor/state/app_state_scope.dart';
import 'package:futegestor/ui/players_management_page.dart';

class ArrivalPage extends StatelessWidget {
  const ArrivalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.appWatch();
    final playersById = {for (final p in state.players) p.id: p};
    final arrival = state.arrivalOrder;
    final settings = state.settings;
    final missingInfo = settings.drawModeActive &&
        arrival.any((id) => playersById[id]?.position == null || playersById[id]?.level == null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Chegada'),
        actions: [
          IconButton(
            tooltip: 'Gerenciar Jogadores Cadastrados',
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayersManagementPage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Adicionar 8 jogadores de teste',
            icon: const Icon(Icons.science),
            onPressed: () {
              context.appRead().seedTestPlayers();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('8 jogadores de teste adicionados')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AddToArrivalSection(),
            const SizedBox(height: 16),
            if (missingInfo)
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('⚠️ Jogadores sem posição/nível – sorteio pode falhar'),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Text(
              'Jogadores na Fila (${arrival.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: arrival.isEmpty
                  ? const Center(child: Text('Nenhum jogador na fila ainda.\nAdicione jogadores usando o botão acima.'))
                  : ReorderableListView.builder(
                      itemCount: arrival.length,
                      onReorder: (o, n) => state.reorderArrival(o, n),
                      buildDefaultDragHandles: true,
                      itemBuilder: (context, i) {
                        final p = playersById[arrival[i]];
                        if (p == null) return const SizedBox.shrink();
                        return Card(
                          key: ValueKey(p.id),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${i + 1}')),
                            title: Text(p.name),
                            subtitle: Text(_subtitleFor(p)),
                            trailing: IconButton(
                              icon: Icon(Icons.remove_circle, color: Theme.of(context).colorScheme.error),
                              tooltip: 'Remover da fila',
                              onPressed: () => state.removePlayerFromArrival(p.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: Text('Iniciar Jogo (${arrival.length}/${settings.minPlayersToStart})'),
                      onPressed: state.hasMinPlayers
                          ? () {
                              try {
                                state.startMatch();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Partida iniciada!')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao iniciar partida: $e'),
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                  ),
                                );
                              }
                            }
                          : null,
                    ),
                  ),
                  if (settings.drawModeActive) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.balance),
                        label: const Text('Iniciar com Times Balanceados'),
                        onPressed: state.hasMinPlayers
                            ? () {
                                try {
                                  state.startMatch(useBalancedTeams: true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Partida iniciada com times balanceados!')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erro ao balancear times: $e'),
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitleFor(Player p) {
    final pos = p.position?.name ?? 'Sem posição';
    final lvl = p.level?.name ?? 'Sem nível';
    return '$pos · $lvl';
  }
}

class _AddToArrivalSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.appWatch();
    final allPlayers = state.players;
    final arrival = state.arrivalOrder;

    // Filter players not yet in arrival queue
    final availablePlayers = allPlayers.where((p) => !arrival.contains(p.id)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Adicionar à Fila',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlayersManagementPage()),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Novo Jogador'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (availablePlayers.isEmpty)
              const Text('Todos os jogadores cadastrados já estão na fila.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availablePlayers.map((p) {
                  return ActionChip(
                    avatar: CircleAvatar(
                      child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?'),
                    ),
                    label: Text(p.name),
                    onPressed: () {
                      state.addPlayerToArrival(p.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${p.name} adicionado à fila')),
                      );
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
