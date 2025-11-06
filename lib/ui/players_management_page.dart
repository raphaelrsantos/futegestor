import 'package:flutter/material.dart';
import 'package:futegestor/models/player.dart';
import 'package:futegestor/state/app_state.dart';
import 'package:futegestor/state/app_state_scope.dart';

/// Page for managing all registered players (CRUD operations)
class PlayersManagementPage extends StatelessWidget {
  const PlayersManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.appWatch();
    final players = state.players;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Jogadores'),
      ),
      body: players.isEmpty
          ? const Center(child: Text('Nenhum jogador cadastrado ainda.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: players.length,
              itemBuilder: (context, i) {
                final p = players[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?'),
                    ),
                    title: Text(p.name),
                    subtitle: Text(_subtitleFor(p)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openEditPlayer(context, p),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                          onPressed: () => _confirmDelete(context, p),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddPlayer(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Jogador'),
      ),
    );
  }

  String _subtitleFor(Player p) {
    final pos = p.position?.name ?? 'Sem posição';
    final lvl = p.level?.name ?? 'Sem nível';
    return '$pos · $lvl';
  }

  void _confirmDelete(BuildContext context, Player p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Tem certeza que deseja excluir o jogador "${p.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              context.appRead().removePlayer(p.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Jogador "${p.name}" removido')),
              );
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

void _openAddPlayer(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const _PlayerFormSheet(),
  );
}

void _openEditPlayer(BuildContext context, Player player) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _PlayerFormSheet(player: player),
  );
}

class _PlayerFormSheet extends StatefulWidget {
  final Player? player;
  const _PlayerFormSheet({this.player});

  @override
  State<_PlayerFormSheet> createState() => _PlayerFormSheetState();
}

class _PlayerFormSheetState extends State<_PlayerFormSheet> {
  late TextEditingController nameCtrl;
  Position? position;
  SkillLevel? level;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.player?.name ?? '');
    position = widget.player?.position;
    level = widget.player?.level;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  bool get isEditing => widget.player != null;

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
          Text(
            isEditing ? 'Editar Jogador' : 'Novo Jogador',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nome *',
              border: OutlineInputBorder(),
            ),
            autofocus: !isEditing,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Position>(
            value: position,
            decoration: const InputDecoration(
              labelText: 'Posição *',
              border: OutlineInputBorder(),
            ),
            items: Position.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: (v) => setState(() => position = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SkillLevel>(
            value: level,
            decoration: const InputDecoration(
              labelText: 'Nível Técnico *',
              border: OutlineInputBorder(),
            ),
            items: SkillLevel.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: (v) => setState(() => level = v),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: Icon(isEditing ? Icons.save : Icons.add),
                label: Text(isEditing ? 'Salvar' : 'Adicionar'),
                onPressed: _save,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _save() {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o nome do jogador')),
      );
      return;
    }
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione a posição')),
      );
      return;
    }
    if (level == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione o nível técnico')),
      );
      return;
    }

    final state = context.appRead();
    if (isEditing) {
      state.editPlayer(
        widget.player!.id,
        name: name,
        position: position,
        level: level,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jogador atualizado com sucesso')),
      );
    } else {
      state.addPlayer(name, position: position, level: level);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jogador adicionado com sucesso')),
      );
    }
  }
}
