import 'package:flutter/material.dart';

import '../data/banco_dados.dart';
import '../utils/formatos.dart';

class GeladeiraScreen extends StatefulWidget {
  const GeladeiraScreen({super.key});

  @override
  State<GeladeiraScreen> createState() => GeladeiraScreenState();
}

class GeladeiraScreenState extends State<GeladeiraScreen> {
  final BancoDados _bancoDados = BancoDados.instancia;

  List<Map<String, dynamic>> _desejos = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDesejos();
  }

  // Chamado pela casca quando esta aba volta a aparecer.
  void recarregar() => _carregarDesejos();

  Future<void> _carregarDesejos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final desejos = await _bancoDados.listarDesejos();

      if (!mounted) return;

      setState(() {
        _desejos = desejos;
        _carregando = false;
      });
    } catch (erro) {
      debugPrint('Erro ao carregar a Geladeira: $erro');

      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar a Geladeira.';
        _carregando = false;
      });
    }
  }

  void _avisar(String mensagem, {required bool falhou}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: falhou ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _abrirFormulario() async {
    final gravou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const _NovoDesejoScreen(),
      ),
    );

    if (gravou == true && mounted) {
      await _carregarDesejos();
    }
  }

  // Compra liberada: cria a despesa no extrato e fecha o desejo.
  Future<void> _comprar(Map<String, dynamic> desejo) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar compra'),
        content: Text(
          'O período de espera terminou. Comprar '
          '"${desejo['descricao']}" por '
          '${formatarMoeda(desejo['valor'] as double)}? '
          'A despesa entrará no extrato.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.shopping_cart_checkout),
            label: const Text('Comprar'),
          ),
        ],
      ),
    );

    if (confirmou != true || !mounted) return;

    try {
      final quantidade = await _bancoDados.decidirDesejo(
        desejo['id'] as int,
        'comprado',
      );

      if (quantidade != 1) {
        throw StateError('O desejo não está mais esperando.');
      }

      await _bancoDados.inserirTransacao({
        'tipo': 'Despesa',
        'descricao': desejo['descricao'],
        'valor': desejo['valor'],
        'categoria': desejo['categoria'],
        'data': DateTime.now(),
      });
    } catch (erro) {
      debugPrint('Erro ao comprar desejo: $erro');

      if (!mounted) return;

      _avisar('Não foi possível registrar a compra.', falhou: true);
      return;
    }

    await _carregarDesejos();

    if (!mounted) return;

    _avisar('Compra registrada no extrato.', falhou: false);
  }

  Future<void> _desistir(Map<String, dynamic> desejo) async {
    final valor = formatarMoeda(desejo['valor'] as double);

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desistir da compra'),
        content: Text(
          'Desistir de "${desejo['descricao']}"? '
          'Você economiza $valor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.thumb_up_alt_outlined),
            label: const Text('Desistir'),
          ),
        ],
      ),
    );

    if (confirmou != true || !mounted) return;

    try {
      final quantidade = await _bancoDados.decidirDesejo(
        desejo['id'] as int,
        'desistido',
      );

      if (quantidade != 1) {
        throw StateError('O desejo não está mais esperando.');
      }
    } catch (erro) {
      debugPrint('Erro ao desistir do desejo: $erro');

      if (!mounted) return;

      _avisar('Não foi possível registrar a desistência.', falhou: true);
      return;
    }

    await _carregarDesejos();

    if (!mounted) return;

    _avisar('Parabéns! Você economizou $valor.', falhou: false);
  }

  Future<void> _confirmarExclusao(Map<String, dynamic> desejo) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir da Geladeira'),
        content: Text('Deseja realmente excluir "${desejo['descricao']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou != true || !mounted) return;

    try {
      final quantidade =
          await _bancoDados.excluirDesejo(desejo['id'] as int);

      if (quantidade != 1) {
        throw StateError('Desejo não encontrado.');
      }
    } catch (erro) {
      debugPrint('Erro ao excluir desejo: $erro');

      if (!mounted) return;

      _avisar('Não foi possível excluir.', falhou: true);
      return;
    }

    await _carregarDesejos();

    if (!mounted) return;

    _avisar('Desejo excluído.', falhou: false);
  }

  Widget _criarDesejo(Map<String, dynamic> desejo) {
    final status = desejo['status'] as String;
    final esperaAte = desejo['esperaAte'] as DateTime;
    final esperando = status == 'esperando';
    final liberado = esperando && !DateTime.now().isBefore(esperaAte);
    final diasRestantes =
        esperaAte.difference(DateTime.now()).inDays + 1;

    final Color corDoStatus;
    final IconData iconeDoStatus;
    final String textoDoStatus;

    if (status == 'comprado') {
      corDoStatus = Colors.blueGrey;
      iconeDoStatus = Icons.shopping_bag_outlined;
      textoDoStatus = 'Comprado';
    } else if (status == 'desistido') {
      corDoStatus = Colors.green;
      iconeDoStatus = Icons.thumb_up_alt_outlined;
      textoDoStatus = 'Desistiu — valor economizado';
    } else if (liberado) {
      corDoStatus = const Color(0xFFD9A928);
      iconeDoStatus = Icons.lock_open_outlined;
      textoDoStatus = 'Espera concluída: hora de decidir!';
    } else {
      corDoStatus = Colors.blue;
      iconeDoStatus = Icons.ac_unit;
      textoDoStatus = diasRestantes == 1
          ? 'Esfriando: falta 1 dia (até ${formatarData(esperaAte)})'
          : 'Esfriando: faltam $diasRestantes dias '
              '(até ${formatarData(esperaAte)})';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    desejo['descricao'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  formatarMoeda(desejo['valor'] as double),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${desejo['categoria']} • registrado em '
              '${formatarData(desejo['criadoEm'] as DateTime)}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(iconeDoStatus, color: corDoStatus, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    textoDoStatus,
                    style: TextStyle(
                      color: corDoStatus,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (liberado)
                  FilledButton.icon(
                    onPressed: () => _comprar(desejo),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text('Comprar'),
                  ),
                if (esperando)
                  OutlinedButton.icon(
                    onPressed: () => _desistir(desejo),
                    icon: const Icon(Icons.thumb_up_alt_outlined),
                    label: const Text('Desistir'),
                  ),
                TextButton.icon(
                  onPressed: () => _confirmarExclusao(desejo),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Excluir',
                    style: TextStyle(color: Colors.red),
                  ),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_erro!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _carregarDesejos,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_desejos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.ac_unit, size: 56, color: Colors.black54),
              SizedBox(height: 16),
              Text(
                'A Geladeira está vazia.\n'
                'Antes de uma compra por impulso, coloque o desejo '
                'aqui para esfriar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _criarResumo(),
        const SizedBox(height: 18),
        ..._desejos.map(_criarDesejo),
      ],
    );
  }

  // Cartão azul com o total economizado (desistências) e o total
  // ainda esperando na Geladeira, como no design da equipe.
  Widget _criarResumo() {
    double somar(String status) {
      return _desejos
          .where((desejo) => desejo['status'] == status)
          .fold(
            0.0,
            (total, desejo) => total + (desejo['valor'] as double),
          );
    }

    final economizado = somar('desistido');
    final congelado = somar('esperando');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.ac_unit, color: Colors.white, size: 32),
          const SizedBox(height: 10),
          const Text(
            'Você já economizou',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            formatarMoeda(economizado),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ao esfriar seus impulsos!',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total na Geladeira',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                formatarMoeda(congelado),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEDB),
      appBar: AppBar(
        title: const Text('Geladeira'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5C518),
        foregroundColor: const Color(0xFF111111),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SizedBox(width: double.infinity, child: _criarConteudo()),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        tooltip: 'Colocar desejo na Geladeira',
        backgroundColor: const Color(0xFFF5C518),
        foregroundColor: const Color(0xFF111111),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Formulário para colocar um novo desejo de compra na Geladeira.
class _NovoDesejoScreen extends StatefulWidget {
  const _NovoDesejoScreen();

  @override
  State<_NovoDesejoScreen> createState() => _NovoDesejoScreenState();
}

class _NovoDesejoScreenState extends State<_NovoDesejoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();

  String _categoriaSelecionada = 'Lazer';
  int _diasDeEspera = 7;

  static const List<String> _categorias = [
    'Alimentação',
    'Moradia',
    'Transporte',
    'Saúde',
    'Educação',
    'Lazer',
    'Outros',
  ];

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final valor = double.parse(
      _valorController.text.replaceAll(',', '.'),
    );

    try {
      await BancoDados.instancia.inserirDesejo(
        descricao: _descricaoController.text,
        valor: valor,
        categoria: _categoriaSelecionada,
        diasDeEspera: _diasDeEspera,
      );
    } catch (erro) {
      debugPrint('Erro ao guardar o desejo: $erro');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível guardar o desejo.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo desejo'),
        backgroundColor: const Color(0xFFF5C518),
        foregroundColor: const Color(0xFF111111),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sentiu vontade de comprar algo? Coloque aqui para '
                'esfriar. Depois do período de espera, você decide '
                'com calma: comprar ou desistir.',
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'O que você quer comprar?',
                  hintText: 'Exemplo: Fone de ouvido novo',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Digite o que deseja comprar';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _valorController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor aproximado',
                  hintText: '0,00',
                  prefixText: 'R\$ ',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Digite o valor aproximado';
                  }

                  final numero = double.tryParse(
                    valor.replaceAll(',', '.'),
                  );

                  if (numero == null || numero <= 0) {
                    return 'Digite um valor válido';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: _categoriaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categorias.map((categoria) {
                  return DropdownMenuItem(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() {
                      _categoriaSelecionada = valor;
                    });
                  }
                },
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<int>(
                initialValue: _diasDeEspera,
                decoration: const InputDecoration(
                  labelText: 'Período de espera',
                  prefixIcon: Icon(Icons.hourglass_bottom),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 0,
                    child: Text('Liberar hoje (demonstração)'),
                  ),
                  DropdownMenuItem(value: 1, child: Text('1 dia')),
                  DropdownMenuItem(value: 3, child: Text('3 dias')),
                  DropdownMenuItem(value: 7, child: Text('7 dias')),
                  DropdownMenuItem(value: 15, child: Text('15 dias')),
                  DropdownMenuItem(value: 30, child: Text('30 dias')),
                ],
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() {
                      _diasDeEspera = valor;
                    });
                  }
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _salvar,
                  icon: const Icon(Icons.ac_unit),
                  label: const Text(
                    'Colocar na Geladeira',
                    style: TextStyle(fontSize: 17),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5C518),
                    foregroundColor: const Color(0xFF111111),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
