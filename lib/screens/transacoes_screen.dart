import 'package:flutter/material.dart';

import '../data/banco_dados.dart';
import '../utils/formatos.dart';
import 'nova_transacao_screen.dart';

class TransacoesScreen extends StatefulWidget {
  const TransacoesScreen({super.key});

  @override
  State<TransacoesScreen> createState() => TransacoesScreenState();
}

class TransacoesScreenState extends State<TransacoesScreen> {
  final BancoDados _bancoDados = BancoDados.instancia;

  List<Map<String, dynamic>> _transacoes = [];
  bool _carregando = true;

  String _tipoFiltro = 'Todos';
  String _categoriaFiltro = 'Todas';
  DateTimeRange? _periodoFiltro;
  String _buscaDescricao = '';

  final List<String> _categoriasFiltro = [
    'Todas',
    'Alimentação',
    'Moradia',
    'Transporte',
    'Saúde',
    'Educação',
    'Lazer',
    'Salário',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final lista = await _bancoDados.listarTransacoes();

      if (!mounted) return;

      setState(() {
        _transacoes = lista;
        _carregando = false;
      });
    } catch (erro) {
      debugPrint('Erro ao carregar transações: $erro');

      if (!mounted) return;

      setState(() {
        _carregando = false;
      });
    }
  }

  // Chamado pela casca quando esta aba volta a aparecer.
  void recarregar() => _carregar();

  // Filtra apenas a exibição, mantendo os lançamentos originais.
  List<Map<String, dynamic>> get _transacoesFiltradas {
    return _transacoes.where((transacao) {
      final correspondeTipo =
          _tipoFiltro == 'Todos' ||
              transacao['tipo'] == _tipoFiltro;

      final correspondeCategoria =
          _categoriaFiltro == 'Todas' ||
              transacao['categoria'] == _categoriaFiltro;

      final periodo = _periodoFiltro;
      var correspondePeriodo = true;

      if (periodo != null) {
        final data = transacao['data'] as DateTime;

        // Compara apenas o dia, sem considerar o horário.
        final dia = DateTime(data.year, data.month, data.day);
        final inicio = DateTime(
          periodo.start.year,
          periodo.start.month,
          periodo.start.day,
        );
        final fim = DateTime(
          periodo.end.year,
          periodo.end.month,
          periodo.end.day,
        );

        correspondePeriodo =
            !dia.isBefore(inicio) && !dia.isAfter(fim);
      }

      final descricao =
          transacao['descricao']?.toString().toLowerCase() ?? '';

      final correspondeBusca =
      descricao.contains(_buscaDescricao.trim().toLowerCase());

      return correspondeTipo &&
          correspondeCategoria &&
          correspondePeriodo &&
          correspondeBusca;
    }).toList();
  }
  Future<void> _selecionarPeriodo() async {
    final periodo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
      initialDateRange: _periodoFiltro,
      helpText: 'Selecione o período',
      saveText: 'Aplicar',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      fieldStartLabelText: 'Data inicial',
      fieldEndLabelText: 'Data final',
    );

    // Cancelar mantém o filtro anterior.
    if (periodo == null || !mounted) return;

    setState(() {
      _periodoFiltro = periodo;
    });
  }

  Future<void> _editarTransacao(
      Map<String, dynamic> transacao,
      ) async {
    final atualizada = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => NovaTransacaoScreen(
          transacaoInicial: transacao,
        ),
      ),
    );

    if (atualizada == null || !mounted) {
      return;
    }

    try {
      final quantidade = await _bancoDados.atualizarTransacao(
        transacao['id'] as int,
        atualizada,
      );

      if (quantidade != 1) {
        throw StateError('Não foi possível encontrar o lançamento.');
      }
    } catch (erro) {
      debugPrint('Erro ao editar transação: $erro');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível concluir a edição. '
                'Recarregue a lista para conferir os dados.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (!mounted) {
      return;
    }

    await _carregar();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transação atualizada com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }
double get _totalReceitas {
    return _transacoesFiltradas

        .where((transacao) => transacao['tipo'] == 'Receita')
        .fold(
      0.0,
          (total, transacao) =>
      total + (transacao['valor'] as num).toDouble(),
    );
  }

  double get _totalDespesas {
    return _transacoesFiltradas
        .where((transacao) => transacao['tipo'] == 'Despesa')
        .fold(
      0.0,
          (total, transacao) =>
      total + (transacao['valor'] as num).toDouble(),
    );
  }

  double get _saldo => _totalReceitas - _totalDespesas;

  Future<void> _confirmarExclusao(
      Map<String, dynamic> transacao,
      ) async {
    final descricao =
        transacao['descricao']?.toString() ?? 'esta transação';

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir transação'),
          content: Text(
            'Deseja realmente excluir "$descricao"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmou != true) {
      return;
    }

    try {
      final quantidade = await _bancoDados.excluirTransacao(
        transacao['id'] as int,
      );

      if (quantidade != 1) {
        throw StateError('Não foi possível encontrar o lançamento.');
      }
    } catch (erro) {
      debugPrint('Erro ao excluir transação: $erro');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível concluir a exclusão. '
                'Recarregue a lista para conferir os dados.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (!mounted) {
      return;
    }

    await _carregar();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transação excluída com sucesso.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _criarResumo({
    required String titulo,
    required double valor,
    required IconData icone,
    required Color cor,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cor.withValues(alpha: 0.12),
                child: Icon(icone, color: cor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatarMoeda(valor),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _criarTransacao(Map<String, dynamic> transacao) {
    final receita = transacao['tipo'] == 'Receita';
    final cor = receita ? Colors.green : Colors.red;
    final valor = (transacao['valor'] as num).toDouble();
    final data = transacao['data'] as DateTime;

    final descricao =
        transacao['descricao']?.toString() ?? 'Sem descrição';

    final categoria =
        transacao['categoria']?.toString() ?? 'Sem categoria';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          receita
              ? const Color(0xFFE8F5E9)
              : const Color(0xFFFFEBEE),
          child: Icon(
            receita ? Icons.arrow_upward : Icons.arrow_downward,
            color: cor,
          ),
        ),
        title: Text(
          descricao,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${formatarData(data)} • $categoria',
            ),
            const SizedBox(height: 3),
            Text(
              '${receita ? '+' : '-'} ${formatarMoeda(valor)}',
              style: TextStyle(
                color: cor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                _editarTransacao(transacao);
              },
              icon: const Icon(
                Icons.edit_outlined,
                color: Colors.blue,
              ),
              tooltip: 'Editar transação',
            ),
            IconButton(
              onPressed: () {
                _confirmarExclusao(transacao);
              },
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              tooltip: 'Excluir transação',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEDB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5C518),
        foregroundColor: const Color(0xFF111111),
        title: const Text('Transações'),
        centerTitle: true,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar pela descrição',
                    hintText: 'Digite parte da descrição',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (valor) {
                    setState(() {
                      _buscaDescricao = valor;
                    });
                  },
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _tipoFiltro,
                  decoration: const InputDecoration(
                    labelText: 'Tipo da transação',
                    prefixIcon: Icon(Icons.filter_list),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Todos',
                      child: Text('Todas as transações'),
                    ),
                    DropdownMenuItem(
                      value: 'Receita',
                      child: Text('Receitas'),
                    ),
                    DropdownMenuItem(
                      value: 'Despesa',
                      child: Text('Despesas'),
                    ),
                  ],
                  onChanged: (valor) {
                    if (valor == null) return;

                    setState(() {
                      _tipoFiltro = valor;
                    });
                  },
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _categoriaFiltro,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _categoriasFiltro.map((categoria) {
                    return DropdownMenuItem<String>(
                      value: categoria,
                      child: Text(categoria),
                    );
                  }).toList(),
                  onChanged: (valor) {
                    if (valor == null) return;

                    setState(() {
                      _categoriaFiltro = valor;
                    });
                  },
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _selecionarPeriodo,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _periodoFiltro == null
                            ? 'Período: todas as datas'
                            : '${formatarData(_periodoFiltro!.start)}'
                            ' até '
                            '${formatarData(_periodoFiltro!.end)}',
                      ),
                    ),
                    if (_periodoFiltro != null)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _periodoFiltro = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Limpar período'),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo das transações exibidas',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatarMoeda(_saldo),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _criarResumo(
                      titulo: 'Receitas',
                      valor: _totalReceitas,
                      icone: Icons.arrow_upward,
                      cor: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _criarResumo(
                      titulo: 'Despesas',
                      valor: _totalDespesas,
                      icone: Icons.arrow_downward,
                      cor: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Transações exibidas (${_transacoesFiltradas.length})',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (_transacoesFiltradas.isEmpty)
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
                              'Nenhuma transação para exibir.',
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
                  ..._transacoesFiltradas.map(_criarTransacao),
              ],
            ),
          ),
        ),
      ),
    );
  }
}