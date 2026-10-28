import 'package:flutter/material.dart';

import '../utils/formatos.dart';

class NovaTransacaoScreen extends StatefulWidget {
  final String tipoInicial;
  final Map<String, dynamic>? transacaoInicial;

  const NovaTransacaoScreen({
    super.key,
    this.tipoInicial = 'Despesa',
    this.transacaoInicial,
  });

  @override
  State<NovaTransacaoScreen> createState() => _NovaTransacaoScreenState();
}

class _NovaTransacaoScreenState extends State<NovaTransacaoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();

  late String _tipoSelecionado;
  String _categoriaSelecionada = 'Alimentação';
  DateTime _dataSelecionada = DateTime.now();
  @override
  void initState() {
    super.initState();

    _tipoSelecionado = widget.tipoInicial;

    final transacao = widget.transacaoInicial;

    if (transacao != null) {
      _tipoSelecionado = transacao['tipo'] as String;
      _descricaoController.text = transacao['descricao'] as String;
      _valorController.text = (transacao['valor'] as num)
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      _categoriaSelecionada = transacao['categoria'] as String;
      _dataSelecionada = transacao['data'] as DateTime;
    }
  }

  final List<String> _categorias = [
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
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (dataEscolhida != null) {
      setState(() {
        _dataSelecionada = dataEscolhida;
      });
    }
  }

  void _salvarTransacao() {
    if (_formKey.currentState!.validate()) {
      final valorConvertido = double.parse(
        _valorController.text.replaceAll(',', '.'),
      );

      Navigator.pop(
        context,
        {
          'tipo': _tipoSelecionado,
          'descricao': _descricaoController.text.trim(),
          'valor': valorConvertido,
          'categoria': _categoriaSelecionada,
          'data': _dataSelecionada,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transacaoInicial == null
              ? 'Nova Transação'
              : 'Editar Transação',
        ),
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
              DropdownButtonFormField<String>(
                initialValue: _tipoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo da transação',
                  prefixIcon: Icon(Icons.swap_vert),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Receita',
                    child: Text('Receita'),
                  ),
                  DropdownMenuItem(
                    value: 'Despesa',
                    child: Text('Despesa'),
                  ),
                ],
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() {
                      _tipoSelecionado = valor;
                    });
                  }
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Exemplo: Compra no supermercado',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Digite uma descrição';
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
                  labelText: 'Valor',
                  hintText: '0,00',
                  prefixText: 'R\$ ',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Digite o valor da transação';
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
              InkWell(
                onTap: _selecionarData,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(formatarData(_dataSelecionada)),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _salvarTransacao,
                  icon: const Icon(Icons.save),
                  label: Text(
                    widget.transacaoInicial == null
                        ? 'Salvar transação'
                        : 'Salvar alterações',
                    style: const TextStyle(fontSize: 17),
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
