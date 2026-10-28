import 'package:flutter/material.dart';

import '../data/banco_dados.dart';
import '../utils/formatos.dart';
import '../widgets/grafico_rosca.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => RelatoriosScreenState();
}

class RelatoriosScreenState extends State<RelatoriosScreen> {
  final BancoDados _bancoDados = BancoDados.instancia;

  bool _carregando = true;
  bool _erro = false;

  List<Map<String, dynamic>> _despesasPorCategoria = [];
  List<Map<String, dynamic>> _totaisPorMes = [];
  Map<String, dynamic>? _maiorDespesa;

  @override
  void initState() {
    super.initState();
    _carregarRelatorios();
  }

  // Chamado pela casca quando esta aba volta a aparecer.
  void recarregar() => _carregarRelatorios();

  Future<void> _carregarRelatorios() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });

    try {
      final categorias = await _bancoDados.despesasPorCategoria();
      final meses = await _bancoDados.totaisPorMes();
      final maior = await _bancoDados.maiorDespesa();

      if (!mounted) {
        return;
      }

      setState(() {
        _despesasPorCategoria = categorias;
        _totaisPorMes = meses;
        _maiorDespesa = maior;
        _carregando = false;
      });
    } catch (erro) {
      debugPrint('Erro ao carregar relatórios: $erro');

      if (!mounted) {
        return;
      }

      setState(() {
        _carregando = false;
        _erro = true;
      });
    }
  }

  double get _totalDasDespesas {
    return _despesasPorCategoria.fold(
      0.0,
      (total, item) => total + (item['total'] as double),
    );
  }

  Widget _tituloDaSecao(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _cartaoVazio(String mensagem) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const Icon(
              Icons.bar_chart_outlined,
              color: Colors.black45,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _criarMaiorDespesa() {
    final maior = _maiorDespesa;

    if (maior == null) {
      return _cartaoVazio('Nenhuma despesa cadastrada ainda.');
    }

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFEBEE),
          child: Icon(Icons.warning_amber_outlined, color: Colors.red),
        ),
        title: Text(
          maior['descricao'] as String,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${formatarData(maior['data'] as DateTime)}'
          ' • ${maior['categoria']}',
        ),
        trailing: Text(
          formatarMoeda(maior['valor'] as double),
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // Gráfico de rosca com o total das despesas por categoria.
  Widget _criarRosca() {
    final fatias = _despesasPorCategoria
        .map(
          (item) => Fatia(
            rotulo: item['categoria'] as String,
            valor: item['total'] as double,
            cor: corDaCategoria(item['categoria'] as String),
          ),
        )
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            GraficoRosca(
              fatias: fatias,
              textoCentral: formatarMoeda(_totalDasDespesas),
              tamanho: 140,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: fatias.map((fatia) {
                  final porcentagem =
                      (fatia.valor / _totalDasDespesas * 100).round();

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

  Widget _criarCategoria(Map<String, dynamic> item) {
    final total = item['total'] as double;
    final totalGeral = _totalDasDespesas;
    final fracao = totalGeral <= 0 ? 0.0 : total / totalGeral;
    final porcentagem = (fracao * 100).toStringAsFixed(1);
    final cor = corDaCategoria(item['categoria'] as String);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 6, backgroundColor: cor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['categoria'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '-${formatarMoeda(total)}  ($porcentagem%)',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fracao,
                minHeight: 10,
                backgroundColor: const Color(0xFFEDE5CC),
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _criarMes(Map<String, dynamic> item) {
    final receitas = item['receitas'] as double;
    final despesas = item['despesas'] as double;
    final saldo = receitas - despesas;
    final corDoSaldo = saldo < 0 ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    nomeDoMes(item['mes'] as String),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  formatarMoeda(saldo),
                  style: TextStyle(
                    color: corDoSaldo,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  formatarMoeda(receitas),
                  style: const TextStyle(color: Colors.green),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_downward, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Text(
                  formatarMoeda(despesas),
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _criarConteudo() {
    if (_carregando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_erro) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              const Text(
                'Não foi possível carregar os relatórios.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _carregarRelatorios,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_despesasPorCategoria.isNotEmpty) ...[
          _tituloDaSecao('Visão geral das despesas'),
          _criarRosca(),
        ],
        _tituloDaSecao('Maior despesa'),
        _criarMaiorDespesa(),
        _tituloDaSecao('Despesas por categoria'),
        if (_despesasPorCategoria.isEmpty)
          _cartaoVazio('Cadastre despesas para ver a divisão por categoria.')
        else
          ..._despesasPorCategoria.map(_criarCategoria),
        _tituloDaSecao('Receitas e despesas por mês'),
        if (_totaisPorMes.isEmpty)
          _cartaoVazio('Cadastre lançamentos para ver os totais por mês.')
        else
          ..._totaisPorMes.map(_criarMes),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEDB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5C518),
        foregroundColor: const Color(0xFF111111),
        title: const Text('Relatórios'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: _criarConteudo(),
          ),
        ),
      ),
    );
  }
}
