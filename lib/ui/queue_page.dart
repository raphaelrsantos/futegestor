import 'package:flutter/material.dart';
import 'package:futegestor/models/player.dart';
import 'package:futegestor/state/app_state.dart';
import 'package:futegestor/state/app_state_scope.dart';

class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.appWatch();
    final playersById = {for (final p in state.players) p.id: p};
    final arrival = state.arrivalOrder;
    final perTeam = state.settings.playersPerTeam;

    // Get players who are already in active teams
    final activePlayers = <String>{};
    if (state.currentMatch != null) {
      activePlayers.addAll(state.currentMatch!.teamA);
      activePlayers.addAll(state.currentMatch!.teamB);
    }
    if (state.hasTeamsPrepared) {
      activePlayers.addAll(state.preparedTeamA!);
      activePlayers.addAll(state.preparedTeamB!);
    }

    // Filter waiting players (not in active teams)
    final waitingPlayers = arrival.where((id) => !activePlayers.contains(id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fila de Espera'),
      ),
      body: waitingPlayers.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Não há jogadores na fila de espera.\nTodos estão jogando ou preparados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Próximos Times - Jogadores aguardando (${waitingPlayers.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: (waitingPlayers.length / perTeam).ceil(),
                    itemBuilder: (context, teamIndex) {
                      final start = teamIndex * perTeam;
                      final end = (teamIndex + 1) * perTeam;
                      final teamPlayers = waitingPlayers.sublist(
                        start,
                        end > waitingPlayers.length ? waitingPlayers.length : end,
                      );
                      final teamNumber = teamIndex + 1;

                      String title;
                      if (teamNumber == 1) {
                        title = 'Time 3 (próximo)';
                      } else {
                        title = 'Time ${teamNumber + 2}';
                      }

                      return _TeamCard(
                        title: title,
                        players: teamPlayers.map((id) => playersById[id]!).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String _subtitleFor(Player p) {
    final pos = p.position?.name ?? 'Sem posição';
    final lvl = p.level?.name ?? 'Sem nível';
    return '$pos · $lvl';
  }
}

class _TeamCard extends StatelessWidget {
  final String title;
  final List<Player> players;

  const _TeamCard({required this.title, required this.players});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: players.length,
              itemBuilder: (context, index) {
                return _PlayerTile(player: players[index], position: index + 1);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final Player player;
  final int position;

  const _PlayerTile({required this.player, required this.position});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text('$position'),
      ),
      title: Text(player.name),
      subtitle: Text(_subtitleFor(player)),
    );
  }

  String _subtitleFor(Player p) {
    final pos = p.position?.name ?? 'Sem posição';
    final lvl = p.level?.name ?? 'Sem nível';
    return '$pos · $lvl';
  }
}
