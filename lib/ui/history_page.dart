import 'package:flutter/material.dart';
import 'package:futegestor/state/app_state.dart';
import 'package:futegestor/state/app_state_scope.dart';
import 'package:futegestor/models/models.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.appWatch().history;
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Partidas')),
      body: items.isEmpty
          ? const Center(child: Text('Nenhuma partida finalizada ainda.'))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, i) {
                final m = items[i];
                return ListTile(
                  title: Text('${_fmtDate(m.createdAt)} • ${m.scoreA} x ${m.scoreB}'),
                  subtitle: Text('Time A vs Time B'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openDetails(context, m),
                );
              },
            ),
    );
  }

  String _fmtDate(DateTime d) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
}

void _openDetails(BuildContext context, MatchModel m) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detalhes da Partida', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Placar final: ${m.scoreA} x ${m.scoreB}'),
          const SizedBox(height: 8),
          Text('Duração: ${m.durationMinutes} min'),
          const SizedBox(height: 12),
          Text('Eventos:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (m.events.isEmpty) const Text('Sem eventos registrados.') else ...[
            SizedBox(
              height: 240,
              child: ListView.builder(
                itemCount: m.events.length,
                itemBuilder: (context, i) {
                  final e = m.events[i];
                  return ListTile(
                    title: Text('${e.type.name} • ${e.minute}\''),
                    subtitle: Text('Time ${e.team}'),
                  );
                },
              ),
            )
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar'),
              onPressed: () => Navigator.pop(context),
            ),
          )
        ],
      ),
    ),
  );
}
