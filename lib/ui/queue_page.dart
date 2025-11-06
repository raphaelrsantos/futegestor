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
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: waitingPlayers.length,
                    onReorder: (oldIndex, newIndex) {
                      // Find the global index in arrival order
                      final playerId = waitingPlayers[oldIndex];
                      final globalOldIndex = arrival.indexOf(playerId);

                      // Calculate the new global index
                      int globalNewIndex;
                      if (newIndex >= waitingPlayers.length) {
                        // Moving to the end
                        final lastWaitingPlayer = waitingPlayers.last;
                        globalNewIndex = arrival.indexOf(lastWaitingPlayer);
                      } else if (newIndex > oldIndex) {
                        // Moving down
                        final targetPlayer = waitingPlayers[newIndex];
                        globalNewIndex = arrival.indexOf(targetPlayer);
                      } else {
                        // Moving up
                        final targetPlayer = waitingPlayers[newIndex];
                        globalNewIndex = arrival.indexOf(targetPlayer);
                      }

                      state.reorderArrival(globalOldIndex, globalNewIndex);
                    },
                    buildDefaultDragHandles: true,
                    itemBuilder: (context, index) {
                      final player = playersById[waitingPlayers[index]];
                      if (player == null) return const SizedBox.shrink();

                      final position = index + 1;
                      final teamNumber = (index ~/ perTeam) + 1;
                      final positionInTeam = (index % perTeam) + 1;

                      // Determine team label and color
                      final isFirstTeam = index < perTeam;
                      final isSecondTeam = index >= perTeam && index < perTeam * 2;

                      Color? cardColor;
                      String teamLabel;

                      if (isFirstTeam) {
                        cardColor = Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3);
                        teamLabel = 'Time 1 - Pos $positionInTeam';
                      } else if (isSecondTeam) {
                        cardColor = Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3);
                        teamLabel = 'Time 2 - Pos $positionInTeam';
                      } else {
                        teamLabel = 'Time $teamNumber - Pos $positionInTeam';
                      }

                      return Card(
                        key: ValueKey(player.id),
                        margin: const EdgeInsets.only(bottom: 8),
                        color: cardColor,
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('$position'),
                          ),
                          title: Text(player.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_subtitleFor(player)),
                              Text(
                                teamLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
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
