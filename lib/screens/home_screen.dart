
import '../data/banco_dados.dart';
import '../data/perfil.dart';
import '../utils/formatos.dart';
import '../widgets/grafico_rosca.dart';
import 'package:flutter/material.dart';

import 'nova_transacao_screen.dart';
import 'perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  /// Pede à casca para trocar de aba (1 = Transações, 2 = Metas,
  /// 3 = Relatórios, 4 = Geladeira).
  final void Function(int indice)? aoIrParaAba;

  const HomeScreen({super.key, this.aoIrParaAba});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _transacoes = [];
  final BancoDados _bancoDados = BancoDados.instancia;

  String _nome = '';
  bool _ocultarSaldo = false;

  @override
  void initState() {
    super.initState();
    _carregarTransacoes();
  }

  // Chamado pela casca quando esta aba volta a aparecer.
  void recarregar() => _carregarTransacoes();

  Future<void> _carregarTransacoes() async {
    try {
      await _bancoDados.importarTransacoesAntigas();

      final nome = await Perfil.nome();

      if (!mounted) {
        return;
      }

      setState(() {
        _nome = nome;
      });

      final lista = await _bancoDados.listarTransacoes();

      if (!mounted) {
        return;
      }

      setState(() {
        _transacoes
          ..clear()
          ..addAll(lista);
      });
    } catch (erro) {
      debugPrint('Erro ao carregar transações: $erro');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível carregar os lançamentos. '
                'Tente novamente mais tarde.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double get _totalReceitas {
    return _transacoes
        .where((transacao) => transacao['tipo'] == 'Receita')
        .fold(
      0.0,
          (total, transacao) => total + (transacao['valor'] as double),
    );
  }

  double get _totalDespesas {
    return _transacoes
        .where((transacao) => transacao['tipo'] == 'Despesa')
        .fold(
      0.0,
          (total, transacao) => total + (transacao['valor'] as double),
    );
  }

  double get _saldoTotal => _totalReceitas - _totalDespesas;

  // Apenas os lançamentos do mês atual.
  List<Map<String, dynamic>> get _transacoesDoMes {
    final agora = DateTime.now();

    return _transacoes.where((transacao) {
      final data = transacao['data'] as DateTime;

      return data.year == agora.year && data.month == agora.month;
    }).toList();
  }

  double _somarNoMes(String tipo) {
    return _transacoesDoMes
        .where((transacao) => transacao['tipo'] == tipo)
        .fold(
      0.0,
          (total, transacao) => total + (transacao['valor'] as double),
    );
  }

  // Despesas do mês somadas por categoria, da maior para a menor.
  List<Fatia> get _fatiasDoMes {
    final somas = <String, double>{};

    for (final transacao in _transacoesDoMes) {
      if (transacao['tipo'] != 'Despesa') continue;

      final categoria = transacao['categoria'] as String;

      somas[categoria] =
          (somas[categoria] ?? 0) + (transacao['valor'] as double);
    }

    final fatias = somas.entries
        .map(
          (entrada) => Fatia(
            rotulo: entrada.key,
            valor: entrada.value,
            cor: corDaCategoria(entrada.key),
          ),
        )
        .toList()
      ..sort((a, b) => b.valor.compareTo(a.valor));

    return fatias;
  }

  Future<void> _abrirNovaTransacao({
    String tipo = 'Despesa',
  }) async {
    final transacao = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => NovaTransacaoScreen(
          tipoInicial: tipo,
        ),
      ),
    );

    if (transacao == null || !mounted) {
      return;
    }

    try {
      final id = await _bancoDados.inserirTransacao(transacao);

      if (!mounted) {
        return;
      }

      setState(() {
        _transacoes.insert(0, {
          ...transacao,
          'id': id,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transação salva com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (erro) {
      debugPrint('Erro ao salvar transação: $erro');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar a transação.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _criarCardTransacao(Map<String, dynamic> transacao) {
    final bool receita = transacao['tipo'] == 'Receita';
    final Color cor = receita ? Colors.green : Colors.red;
    final String sinal = receita ? '+' : '-';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          receita ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
          child: Icon(
            receita ? Icons.arrow_upward : Icons.arrow_downward,
            color: cor,
          ),
        ),
        title: Text(transacao['descricao']),
        subtitle: Text(
          '${formatarDiaMes(transacao['data'])} • ${transacao['categoria']}',
        ),
        trailing: Text(
          '$sinal ${formatarMoeda(transacao['valor'])}',
          style: TextStyle(
            color: cor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // O cabeçalho em degradê laranja, como no protótipo da equipe.
  Widget _criarCabecalho() {
    final agora = DateTime.now();
    final mesAtual = nomeDoMesEAno(agora.month, agora.year);

    final receitasDoMes = _somarNoMes('Receita');
    final despesasDoMes = _somarNoMes('Despesa');
    final economiaDoMes = receitasDoMes - despesasDoMes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF57F17), Color(0xFFF5C518)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, $_nome!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            mesAtual,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                'Saldo total',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  setState(() {
                    _ocultarSaldo = !_ocultarSaldo;
                  });
                },
                child: Icon(
                  _ocultarSaldo
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _ocultarSaldo ? 'R\$ ••••••' : formatarMoeda(_saldoTotal),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _criarChipDoMes('Receitas', receitasDoMes),
              const SizedBox(width: 10),
              _criarChipDoMes('Despesas', despesasDoMes),
              const SizedBox(width: 10),
              _criarChipDoMes('Economia', economiaDoMes),
            ],
          ),
        ],
      ),
    );
  }

  Widget _criarChipDoMes(String titulo, double valor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              titulo,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                _ocultarSaldo ? 'R\$ ••••' : formatarMoeda(valor),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Text(
              'Este mês',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _criarAcaoRapida({
    required IconData icone,
    required String rotulo,
    required Color cor,
    required Color fundo,
    required VoidCallback aoTocar,
  }) {
    return Expanded(
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: fundo,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icone, color: cor, size: 28),
            ),
            const SizedBox(height: 6),
            Text(rotulo, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _criarResumoDoMes() {
    final fatias = _fatiasDoMes;

    if (fatias.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(Icons.pie_chart_outline, color: Colors.black45),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cadastre despesas neste mês para ver o gráfico.',
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalDoMes =
        fatias.fold(0.0, (soma, fatia) => soma + fatia.valor);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            GraficoRosca(
              fatias: fatias,
              textoCentral:
                  _ocultarSaldo ? 'R\$ ••••' : formatarMoeda(totalDoMes),
              tamanho: 140,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: fatias.map((fatia) {
                  final porcentagem =
                      (fatia.valor / totalDoMes * 100).round();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 5, backgroundColor: fatia.cor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fatia.rotulo,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$porcentagem%',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ultimas = _transacoes.take(5).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4EEDB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5C518),
        foregroundColor: const Color(0xFF111111),
        title: const Text('PI.ISO'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // Ao voltar, recarrega: o nome pode ter mudado.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PerfilScreen(),
                ),
              ).then((_) => _carregarTransacoes());
            },
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _criarCabecalho(),
                const SizedBox(height: 24),
                const Text(
                  'Ações rápidas',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _criarAcaoRapida(
                      icone: Icons.arrow_downward,
                      rotulo: 'Despesa',
                      cor: Colors.red,
                      fundo: const Color(0xFFFFEBEE),
                      aoTocar: () => _abrirNovaTransacao(tipo: 'Despesa'),
                    ),
                    _criarAcaoRapida(
                      icone: Icons.arrow_upward,
                      rotulo: 'Receita',
                      cor: Colors.green,
                      fundo: const Color(0xFFE8F5E9),
                      aoTocar: () => _abrirNovaTransacao(tipo: 'Receita'),
                    ),
                    _criarAcaoRapida(
                      icone: Icons.ac_unit,
                      rotulo: 'Geladeira',
                      cor: const Color(0xFF1565C0),
                      fundo: const Color(0xFFE3F2FD),
                      aoTocar: () => widget.aoIrParaAba?.call(4),
                    ),
                    _criarAcaoRapida(
                      icone: Icons.flag_outlined,
                      rotulo: 'Meta',
                      cor: const Color(0xFFF57F17),
                      fundo: const Color(0xFFFFF8E1),
                      aoTocar: () => widget.aoIrParaAba?.call(2),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Resumo do mês',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _criarResumoDoMes(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Últimas transações',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => widget.aoIrParaAba?.call(1),
                      child: const Text('ver todas'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (ultimas.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            color: Colors.black45,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Nenhuma transação cadastrada.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...ultimas.map(_criarCardTransacao),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirNovaTransacao(),
        tooltip: 'Nova transação',
        backgroundColor: const Color(0xFFF5C518),
        foregroundColor: const Color(0xFF111111),
        child: const Icon(Icons.add),
      ),
    );
  }
}
