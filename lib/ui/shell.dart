import 'package:flutter/material.dart';
import 'package:futegestor/ui/arrival_page.dart';
import 'package:futegestor/ui/match_page.dart';
import 'package:futegestor/ui/queue_page.dart';
import 'package:futegestor/ui/history_page.dart';
import 'package:futegestor/ui/settings_page.dart';

class FutegestorShell extends StatefulWidget {
  const FutegestorShell({super.key});

  @override
  State<FutegestorShell> createState() => _FutegestorShellState();
}

class _FutegestorShellState extends State<FutegestorShell> {
  int index = 0;
  final pages = const [
    ArrivalPage(),
    MatchPage(),
    QueuePage(),
    HistoryPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: pages[index],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.group_add), label: 'Chegada'),
          NavigationDestination(icon: Icon(Icons.sports_soccer), label: 'Partida'),
          NavigationDestination(icon: Icon(Icons.view_list), label: 'Fila'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Histórico'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Config.'),
        ],
      ),
    );
  }
}
