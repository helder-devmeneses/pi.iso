import 'package:flutter/material.dart';
import '../data/banco_dados.dart';
import '../utils/formatos.dart';
import 'nova_meta_screen.dart';

class MetasScreen extends StatefulWidget {
  const MetasScreen({super.key});

  @override
  State<MetasScreen> createState() => MetasScreenState();
}

class MetasScreenState extends State<MetasScreen> {
  final BancoDados _bancoDados = BancoDados.instancia;

  List<Map<String, dynamic>> _metas = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarMetas();
  }

  // Chamado pela casca quando esta aba volta a aparecer.
  void recarregar() => _carregarMetas();

  Future<void> _carregarMetas() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final metas = await _bancoDados.listarMetas();

      if (!mounted) return;

      setState(() {
        _metas = metas;
        _carregando = false;
      });
    } catch (erro) {
      debugPrint('Erro ao carregar metas: $erro');

      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar as metas.';
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

  // Sem meta: cadastro. Com meta: edição.
  Future<void> _abrirFormulario({Map<String, dynamic>? meta}) async {
    final gravou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => NovaMetaScreen(metaInicial: meta),
      ),
    );

    if (gravou == true && mounted) {
      await _carregarMetas();
    }
  }

  Future<void> _confirmarExclusao(Map<String, dynamic> meta) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir meta'),
        content: Text('Deseja realmente excluir "${meta['titulo']}"?'),
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
      final quantidade = await _bancoDados.excluirMeta(meta['id'] as int);

      if (quantidade != 1) {
        throw StateError('Meta não encontrada.');
      }
    } catch (erro) {
      debugPrint('Erro ao excluir meta: $erro');

      if (!mounted) return;

      _avisar('Não foi possível excluir a meta.', falhou: true);
      return;
    }

    await _carregarMetas();

    if (!mounted) return;

    _avisar('Meta excluída.', falhou: false);
  }

  Future<void> _depositar(Map<String, dynamic> meta) async {
    final chaveFormulario = GlobalKey<FormState>();

    // O Form guarda o valor pelo onSaved: sem controlador, nada a liberar.
    double? valorLido;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Depositar em "${meta['titulo']}"'),
        content: Form(
          key: chaveFormulario,
          child: TextFormField(
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor do depósito',
              prefixText: 'R\$ ',
              hintText: 'Ex.: 250,00',
              border: OutlineInputBorder(),
            ),
            validator: (texto) {
              final lido = lerValor(texto ?? '');

              if (lido == null || lido < 0.01) {
                return 'Informe de R\$ 0,01 até 999999999,99.';
              }

              return null;
            },
            onSaved: (texto) => valorLido = lerValor(texto ?? ''),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              final formulario = chaveFormulario.currentState!;

              if (!formulario.validate()) return;

              formulario.save();
              Navigator.pop(context, true);
            },
            icon: const Icon(Icons.savings_outlined),
            label: const Text('Depositar'),
          ),
        ],
      ),
    );

    final valor = valorLido;

    if (confirmou != true || valor == null || !mounted) return;

    try {
      final quantidade = await _bancoDados.depositarNaMeta(
        meta['id'] as int,
        valor,
      );

      if (quantidade != 1) {
        throw StateError('Meta não encontrada.');
      }
    } catch (erro) {
      debugPrint('Erro ao depositar na meta: $erro');

      if (!mounted) return;

      _avisar('Não foi possível registrar o depósito.', falhou: true);
      return;
    }

    await _carregarMetas();

    if (!mounted) return;

    _avisar('Depósito de ${formatarMoeda(valor)} registrado.', falhou: false);
  }

  Widget _criarMeta(Map<String, dynamic> meta) {
    final objetivo = (meta['objetivo'] as num).toDouble();
    final guardado = (meta['guardado'] as num).toDouble();
    final prazo = meta['prazo'] as DateTime?;

    // A barra vai até 100%, mesmo quando o valor supera o objetivo.
    final progresso = objetivo > 0
        ? (guardado / objetivo).clamp(0.0, 1.0).toDouble()
        : 0.0;

    final concluida = guardado >= objetivo;
    final falta = (objetivo - guardado).clamp(0.0, objetivo).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meta['titulo'] as String,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '${formatarMoeda(guardado)} guardados de '
              '${formatarMoeda(objetivo)}',
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progresso,
              minHeight: 10,
              color: concluida ? Colors.green : const Color(0xFFF5C518),
              backgroundColor: Colors.black12,
            ),
            const SizedBox(height: 10),
            Text(
              concluida ? 'Meta alcançada!' : 'Faltam ${formatarMoeda(falta)}',
              style: TextStyle(
                color: concluida ? Colors.green : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (prazo != null) ...[
              const SizedBox(height: 8),
              Text('Prazo: ${formatarData(prazo)}'),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _depositar(meta),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF5C518),
                    foregroundColor: const Color(0xFF111111),
                  ),
                  icon: const Icon(Icons.savings_outlined),
                  label: const Text('Depositar'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _abrirFormulario(meta: meta),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmarExclusao(meta),
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
                onPressed: _carregarMetas,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_metas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_outlined, size: 56, color: Colors.black54),
              SizedBox(height: 16),
              Text(
                'Nenhuma meta cadastrada.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _metas.length,
      itemBuilder: (context, indice) => _criarMeta(_metas[indice]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEDB),
      appBar: AppBar(
        title: const Text('Metas financeiras'),
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
        onPressed: () => _abrirFormulario(),
        tooltip: 'Nova meta',
        backgroundColor: const Color(0xFFF5C518),
        foregroundColor: const Color(0xFF111111),
        child: const Icon(Icons.add),
      ),
    );
  }
}
