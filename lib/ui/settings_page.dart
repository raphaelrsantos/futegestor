import 'package:flutter/material.dart';
import 'package:futegestor/state/app_state.dart';
import 'package:futegestor/state/app_state_scope.dart';
import 'package:futegestor/models/models.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = context.appRead().settings;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.appWatch();
    final players = state.players;
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações da Pelada')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildConfigCard(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cadastro de Jogadores', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ...players.map((p) => ListTile(
                        title: Text(p.name),
                        subtitle: Text('${p.position?.name ?? ''} • ${p.level?.name ?? ''}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                          onPressed: () => state.removePlayer(p.id),
                        ),
                      )),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text('Novo Jogador'),
                      onPressed: () => _openQuickAdd(context),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Regras da Pelada', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _settings.matchMinutes.toString(),
                    decoration: const InputDecoration(labelText: 'Tempo da partida (min)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _settings.matchMinutes = int.tryParse(v) ?? _settings.matchMinutes,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _settings.playersPerTeam.toString(),
                    decoration: const InputDecoration(labelText: 'Jogadores por time'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _settings.playersPerTeam = int.tryParse(v) ?? _settings.playersPerTeam,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _settings.minPlayersToStart.toString(),
                    decoration: const InputDecoration(labelText: 'Mínimo para iniciar'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _settings.minPlayersToStart = int.tryParse(v) ?? _settings.minPlayersToStart,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _settings.tiebreaker,
                    decoration: const InputDecoration(labelText: 'Critério de desempate'),
                    items: const [
                      DropdownMenuItem(value: 'mais_gols', child: Text('Quem marcou mais gols')),
                      DropdownMenuItem(value: 'primeiro_gol', child: Text('Quem marcou primeiro')),
                    ],
                    onChanged: (v) => setState(() => _settings.tiebreaker = v ?? 'mais_gols'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Modo sorteio (por posição/nível técnico)'),
              value: _settings.drawModeActive,
              onChanged: (v) => setState(() => _settings.drawModeActive = v),
            ),
            if (_settings.drawModeActive) DropdownButtonFormField<String>(
              value: _settings.drawCriterion,
              decoration: const InputDecoration(labelText: 'Critério de sorteio'),
              items: const [
                DropdownMenuItem(value: 'posicao', child: Text('Posição')),
                DropdownMenuItem(value: 'nivel', child: Text('Nível técnico')),
              ],
              onChanged: (v) => setState(() => _settings.drawCriterion = v ?? 'posicao'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salvar Configurações'),
                onPressed: () {
                  context.appRead().updateSettings(_settings);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Configurações salvas')));
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  void _openQuickAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        Position? pos;
        SkillLevel? lvl;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Novo Jogador', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome')),
              const SizedBox(height: 8),
              DropdownButtonFormField<Position>(
                decoration: const InputDecoration(labelText: 'Posição'),
                items: Position.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
                onChanged: (v) => pos = v,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<SkillLevel>(
                decoration: const InputDecoration(labelText: 'Nível técnico'),
                items: SkillLevel.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
                onChanged: (v) => lvl = v,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Adicionar'),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    context.appRead().addPlayer(name, position: pos, level: lvl);
                    Navigator.pop(ctx);
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
