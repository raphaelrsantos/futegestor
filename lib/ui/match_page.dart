import 'package:flutter/material.dart';
import 'package:futegestor/state/app_state.dart';
import 'package:futegestor/state/app_state_scope.dart';
import 'package:futegestor/models/models.dart';
import 'package:uuid/v4.dart';

class MatchPage extends StatelessWidget {
  const MatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.appWatch();
    final match = state.currentMatch;
    final playersMap = {for (final p in state.players) p.id: p};
    return Scaffold(
      appBar: AppBar(title: const Text('Partida em Andamento')),
      body: match == null
          ? const Center(child: Text('Nenhuma partida em andamento'))
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _ScoreHeader(match: match),
                  const SizedBox(height: 8),
                  _TimerRow(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _TeamColumn(
                            teamLabel: 'Time A',
                            team: 'A',
                            playerIds: match.teamA,
                            playersMap: playersMap,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TeamColumn(
                            teamLabel: 'Time B',
                            team: 'B',
                            playerIds: match.teamB,
                            playersMap: playersMap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _EventBar(playersMap: playersMap),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _EventsList(events: match.events, playersMap: playersMap),
                  ),
                  SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.flag),
                        label: const Text('Finalizar Partida'),
                        onPressed: () => _showFinalizeDialog(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final MatchModel match;
  const _ScoreHeader({required this.match});

  @override
  Widget build(BuildContext context) {
    final state = context.appRead();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ScoreControl(
            label: 'Time A',
            score: match.scoreA,
            onAdd: () => state.changeScore(team: 'A', delta: 1),
            onRemove: () => state.changeScore(team: 'A', delta: -1),
          ),
          Text('${match.scoreA} x ${match.scoreB}', style: Theme.of(context).textTheme.headlineMedium),
          _ScoreControl(
            label: 'Time B',
            score: match.scoreB,
            onAdd: () => state.changeScore(team: 'B', delta: 1),
            onRemove: () => state.changeScore(team: 'B', delta: -1),
          ),
        ],
      ),
    );
  }
}

class _ScoreControl extends StatelessWidget {
  final String label;
  final int score;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _ScoreControl({
    required this.label,
    required this.score,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: onRemove),
        Column(
          children: [
            Text(label, style: textStyle),
          ],
        ),
        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: onAdd),
      ],
    );
  }
}

class _TimerRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.appWatch();
    final match = state.currentMatch!;
    final mins = (match.elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (match.elapsedSeconds % 60).toString().padLeft(2, '0');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$mins:$secs', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(state.timerRunning ? Icons.pause_circle : Icons.play_circle),
          onPressed: () => state.timerRunning ? state.pauseTimer() : state.resumeTimer(),
        ),
        IconButton(
          icon: const Icon(Icons.restart_alt),
          onPressed: () => state.resetTimer(),
        ),
      ],
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final String teamLabel;
  final String team; // 'A' or 'B'
  final List<String> playerIds;
  final Map<String, Player> playersMap;
  const _TeamColumn({
    required this.teamLabel,
    required this.team,
    required this.playerIds,
    required this.playersMap,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.appRead();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(teamLabel, style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  tooltip: 'Adicionar jogador',
                  onPressed: () => _openAddPlayerToTeam(context, team),
                  icon: const Icon(Icons.person_add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: playerIds.length,
                onReorder: (o, n) => context.appRead().reorderTeam(team, o, n),
                itemBuilder: (context, index) {
                  final p = playersMap[playerIds[index]];
                  if (p == null) {
                    return const SizedBox();
                  }
                  return ListTile(
                    key: ValueKey(p.id),
                    title: Text(p.name),
                    subtitle: Text('${p.position?.name ?? ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          onPressed: () => state.moveBetweenTeams(from: team, index: index),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                          onPressed: () => state.removeFromTeam(team, index),
                        ),
                      ],
                    ),
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

class _EventBar extends StatelessWidget {
  final Map<String, Player> playersMap;
  const _EventBar({required this.playersMap});

  @override
  Widget build(BuildContext context) {
    final state = context.appWatch();
    final disabled = !state.timerRunning;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: disabled ? null : () => _openGoalDialog(context, playersMap, 'A'),
            icon: const Icon(Icons.sports_soccer),
            label: const Text('Gol A'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: disabled ? null : () => _openGoalDialog(context, playersMap, 'B'),
            icon: const Icon(Icons.sports_soccer),
            label: const Text('Gol B'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Amarelo',
          onPressed: disabled ? null : () => _addCard(context, playersMap, EventType.amarelo),
          icon: Icon(Icons.square_rounded, color: Theme.of(context).colorScheme.tertiary),
        ),
        IconButton(
          tooltip: 'Vermelho',
          onPressed: disabled ? null : () => _addCard(context, playersMap, EventType.vermelho),
          icon: Icon(Icons.square_rounded, color: Theme.of(context).colorScheme.error),
        ),
      ],
    );
  }

  Future<void> _addCard(BuildContext context, Map<String, Player> map, EventType type) async {
    final state = context.appRead();
    final match = state.currentMatch!;
    final allIds = [...match.teamA, ...match.teamB];
    String? selected;
    await showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type == EventType.amarelo ? 'Cartão Amarelo' : 'Cartão Vermelho',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              items: allIds
                  .map((id) => DropdownMenuItem(value: id, child: Text(map[id]?.name ?? '')))
                  .toList(),
              onChanged: (v) => selected = v,
              decoration: const InputDecoration(labelText: 'Jogador'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () {
                  if (selected == null) return;
                  final team = match.teamA.contains(selected) ? 'A' : 'B';
                  state.addEvent(MatchEvent(
                    id: const UuidV4().generate(),
                    type: type,
                    team: team,
                    minute: match.elapsedSeconds ~/ 60,
                    primaryPlayerId: selected,
                  ));
                  Navigator.pop(context);
                },
                child: const Text('Registrar'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _EventsList extends StatelessWidget {
  final List<MatchEvent> events;
  final Map<String, Player> playersMap;
  const _EventsList({required this.events, required this.playersMap});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox();
    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, i) {
        final e = events[i];
        final p1 = e.primaryPlayerId != null ? playersMap[e.primaryPlayerId]?.name : null;
        final p2 = e.secondaryPlayerId != null ? playersMap[e.secondaryPlayerId]?.name : null;
        final icon = e.type == EventType.gol
            ? const Icon(Icons.sports_soccer)
            : e.type == EventType.amarelo
                ? Icon(Icons.square_rounded, color: Theme.of(context).colorScheme.tertiary)
                : Icon(Icons.square_rounded, color: Theme.of(context).colorScheme.error);
        final title = e.type == EventType.gol
            ? 'Gol do Time ${e.team}'
            : (e.type == EventType.amarelo ? 'Cartão Amarelo' : 'Cartão Vermelho');
        final subtitle = p2 != null && p2.isNotEmpty ? '$p1 (assist. $p2)' : (p1 ?? '');
        return ListTile(
          leading: icon,
          title: Text('$title • ${e.minute}\''),
          subtitle: Text(subtitle),
        );
      },
    );
  }
}

Future<void> _openGoalDialog(
  BuildContext context,
  Map<String, Player> map,
  String team,
) async {
  final state = context.appRead();
  final match = state.currentMatch!;
  final teamIds = team == 'A' ? match.teamA : match.teamB;
  String? author;
  String? assist;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Registrar Gol — Time $team', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            items: teamIds
                .map((id) => DropdownMenuItem(value: id, child: Text(map[id]?.name ?? '')))
                .toList(),
            onChanged: (v) => author = v,
            decoration: const InputDecoration(labelText: 'Autor do Gol'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            items: [null, ...teamIds]
                .map((id) => DropdownMenuItem(
                      value: id,
                      child: Text(id == null ? 'Sem assistência' : (map[id]?.name ?? '')),
                    ))
                .toList(),
            onChanged: (v) => assist = v,
            decoration: const InputDecoration(labelText: 'Assistente (opcional)'),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () {
                if (author == null) return;
                state.addEvent(MatchEvent(
                  id: const UuidV4().generate(),
                  type: EventType.gol,
                  team: team,
                  minute: match.elapsedSeconds ~/ 60,
                  primaryPlayerId: author,
                  secondaryPlayerId: assist,
                ));
                Navigator.pop(context);
              },
              child: const Text('Registrar Gol'),
            ),
          )
        ],
      ),
    ),
  );
}

void _openAddPlayerToTeam(BuildContext context, String team) {
  final state = context.appRead();
  final all = state.players;
  showModalBottomSheet(
    context: context,
    builder: (_) => ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Adicionar ao $team', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...all.map((p) => ListTile(
              title: Text(p.name),
              onTap: () {
                state.addToTeam(team, p.id);
                Navigator.pop(context);
              },
            )),
      ],
    ),
  );
}

void _showFinalizeDialog(BuildContext context) {
  final state = context.appRead();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Finalizar Partida'),
      content: const Text('Deseja encerrar a partida atual e iniciar a próxima?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            state.finalizeMatch();
            Navigator.pop(ctx);

            // Check if we can start next match
            final nextMatch = state.prepareNextMatch();
            if (nextMatch != null) {
              _showNextMatchDialog(context, nextMatch);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Partida finalizada! Não há jogadores suficientes para a próxima.')),
              );
            }
          },
          child: const Text('Finalizar'),
        ),
      ],
    ),
  );
}

void _showNextMatchDialog(
  BuildContext context,
  ({List<String> teamA, List<String> teamB, List<String> waiting}) nextMatch,
) {
  final state = context.appRead();
  final playersMap = {for (final p in state.players) p.id: p};

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Próxima Partida'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Times da próxima partida:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Time A:', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            ...nextMatch.teamA.map((id) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text('• ${playersMap[id]?.name ?? 'Desconhecido'}'),
            )),
            const SizedBox(height: 12),
            Text('Time B:', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
            ...nextMatch.teamB.map((id) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text('• ${playersMap[id]?.name ?? 'Desconhecido'}'),
            )),
            if (nextMatch.waiting.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Aguardando:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...nextMatch.waiting.map((id) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text('• ${playersMap[id]?.name ?? 'Desconhecido'}'),
              )),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Não Iniciar'),
        ),
        FilledButton(
          onPressed: () {
            state.startMatchWithTeams(nextMatch.teamA, nextMatch.teamB);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nova partida iniciada!')),
            );
          },
          child: const Text('Iniciar Partida'),
        ),
      ],
    ),
  );
}
