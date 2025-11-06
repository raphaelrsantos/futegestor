import 'package:flutter/material.dart';
import 'package:futegestor/models/player.dart';
import 'package:futegestor/state/app_state.dart';
import 'package:futegestor/state/app_state_scope.dart';

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
            tooltip: 'Adicionar 8 jogadores de teste',
            icon: const Icon(Icons.science),
            onPressed: () {
              context.appRead().seedTestPlayers();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('8 jogadores de teste adicionados à chegada')),
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
            _AddPlayerCard(),
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
            Expanded(
              child: arrival.isEmpty
                  ? const Center(child: Text('Nenhum jogador adicionado ainda.'))
                  : ReorderableListView.builder(
                      itemCount: arrival.length,
                      onReorder: (o, n) => state.reorderArrival(o, n),
                      buildDefaultDragHandles: true,
                      itemBuilder: (context, i) {
                        final p = playersById[arrival[i]]!;
                        return Card(
                          key: ValueKey(p.id),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${i + 1}')),
                            title: Text(p.name),
                            subtitle: Text(_subtitleFor(p)),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                              onPressed: () => state.removePlayer(p.id),
                            ),
                            onTap: () => _openEditPlayer(context, p),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: Text('Iniciar Jogo (${arrival.length}/${settings.minPlayersToStart})'),
                  onPressed: state.hasMinPlayers ? () {
                    state.startMatch();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Partida iniciada!')),);
                  } : null,
                ),
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

class _AddPlayerCard extends StatefulWidget {
  @override
  State<_AddPlayerCard> createState() => _AddPlayerCardState();
}

class _AddPlayerCardState extends State<_AddPlayerCard> {
  final nameCtrl = TextEditingController();
  Position? position;
  SkillLevel? level;

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do Jogador',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Position>(
                    value: position,
                    decoration: const InputDecoration(labelText: 'Posição (opcional)'),
                    items: Position.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                        .toList(),
                    onChanged: (v) => setState(() => position = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<SkillLevel>(
                    value: level,
                    decoration: const InputDecoration(labelText: 'Nível Técnico (opcional)'),
                    items: SkillLevel.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                        .toList(),
                    onChanged: (v) => setState(() => level = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Adicionar Jogador'),
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Informe o nome do jogador'), backgroundColor: scheme.error),
                    );
                    return;
                  }
                  context.appRead().addPlayer(name, position: position, level: level);
                  setState(() {
                    nameCtrl.clear();
                    position = null;
                    level = null;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openEditPlayer(BuildContext context, Player p) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _EditPlayerSheet(player: p),
  );
}

class _EditPlayerSheet extends StatefulWidget {
  final Player player;
  const _EditPlayerSheet({required this.player});

  @override
  State<_EditPlayerSheet> createState() => _EditPlayerSheetState();
}

class _EditPlayerSheetState extends State<_EditPlayerSheet> {
  late TextEditingController nameCtrl;
  Position? position;
  SkillLevel? level;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.player.name);
    position = widget.player.position;
    level = widget.player.level;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          Text('Editar Jogador', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Position>(
            value: position,
            decoration: const InputDecoration(labelText: 'Posição'),
            items: Position.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: (v) => setState(() => position = v),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<SkillLevel>(
            value: level,
            decoration: const InputDecoration(labelText: 'Nível técnico'),
            items: SkillLevel.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: (v) => setState(() => level = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salvar'),
                onPressed: () {
                  context.appRead().editPlayer(widget.player.id,
                      name: nameCtrl.text.trim(), position: position, level: level);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
