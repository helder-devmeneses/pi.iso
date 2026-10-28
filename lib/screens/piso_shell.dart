import 'package:flutter/material.dart';

import 'geladeira_screen.dart';
import 'home_screen.dart';
import 'metas_screen.dart';
import 'relatorios_screen.dart';
import 'transacoes_screen.dart';

/// A "casca" do aplicativo: menu inferior fixo e as cinco telas
/// dentro de um PageView, permitindo deslizar de uma para outra.
class PisoShell extends StatefulWidget {
  const PisoShell({super.key});

  @override
  State<PisoShell> createState() => _PisoShellState();
}

class _PisoShellState extends State<PisoShell> {
  final PageController _controlador = PageController();

  final _chaveInicio = GlobalKey<HomeScreenState>();
  final _chaveTransacoes = GlobalKey<TransacoesScreenState>();
  final _chaveMetas = GlobalKey<MetasScreenState>();
  final _chaveRelatorios = GlobalKey<RelatoriosScreenState>();
  final _chaveGeladeira = GlobalKey<GeladeiraScreenState>();

  int _indice = 0;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  // Uma aba pode ficar montada com dados antigos; ao voltar a
  // aparecer, ela recarrega do banco.
  void _aoMudarDePagina(int indice) {
    setState(() {
      _indice = indice;
    });

    switch (indice) {
      case 0:
        _chaveInicio.currentState?.recarregar();
      case 1:
        _chaveTransacoes.currentState?.recarregar();
      case 2:
        _chaveMetas.currentState?.recarregar();
      case 3:
        _chaveRelatorios.currentState?.recarregar();
      case 4:
        _chaveGeladeira.currentState?.recarregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controlador,
        onPageChanged: _aoMudarDePagina,
        children: [
          HomeScreen(
            key: _chaveInicio,
            aoIrParaAba: (indice) {
              _controlador.animateToPage(
                indice,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          TransacoesScreen(key: _chaveTransacoes),
          MetasScreen(key: _chaveMetas),
          RelatoriosScreen(key: _chaveRelatorios),
          GeladeiraScreen(key: _chaveGeladeira),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (indice) {
          _controlador.animateToPage(
            indice,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Transações',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            label: 'Metas',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Relatórios',
          ),
          NavigationDestination(
            icon: Icon(Icons.ac_unit),
            label: 'Geladeira',
          ),
        ],
      ),
    );
  }
}
