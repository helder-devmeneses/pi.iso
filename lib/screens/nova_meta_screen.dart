import 'package:flutter/material.dart';
import '../data/banco_dados.dart';
import '../utils/formatos.dart';

class NovaMetaScreen extends StatefulWidget {
  // Nulo: cadastro. Preenchido: edição da meta recebida.
  final Map<String, dynamic>? metaInicial;

  const NovaMetaScreen({super.key, this.metaInicial});

  @override
  State<NovaMetaScreen> createState() => _NovaMetaScreenState();
}

class _NovaMetaScreenState extends State<NovaMetaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _objetivoController = TextEditingController();
  final _guardadoController = TextEditingController(text: '0');

  DateTime? _prazo;
  bool _salvando = false;

  bool get _editando => widget.metaInicial != null;

  @override
  void initState() {
    super.initState();

    final meta = widget.metaInicial;

    if (meta == null) return;

    _tituloController.text = meta['titulo'] as String;
    _objetivoController.text = _paraTexto(meta['objetivo'] as num);
    _guardadoController.text = _paraTexto(meta['guardado'] as num);
    _prazo = meta['prazo'] as DateTime?;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _objetivoController.dispose();
    _guardadoController.dispose();
    super.dispose();
  }

  // Mostra o valor no mesmo formato que o campo aceita de volta.
  String _paraTexto(num valor) => valor.toStringAsFixed(2).replaceAll('.', ',');

  String? _validarValor(String? texto, {required bool objetivo}) {
    final valor = lerValor(texto ?? '');

    if (valor == null) {
      return 'Use até 999999999,99, sem pontos de milhar.';
    }

    if (objetivo && valor < 0.01) {
      return 'O objetivo mínimo é R\$ 0,01.';
    }

    return null;
  }

  Future<void> _escolherPrazo() async {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final prazo = _prazo;

    // Meta em edição pode ter prazo vencido: o calendário precisa alcançá-lo.
    final primeiraData = prazo != null && prazo.isBefore(hoje) ? prazo : hoje;

    final escolhido = await showDatePicker(
      context: context,
      initialDate: prazo ?? hoje,
      firstDate: primeiraData,
      lastDate: DateTime(hoje.year + 50, 12, 31),
      helpText: 'Escolha o prazo da meta',
    );

    if (escolhido == null || !mounted) return;

    setState(() {
      _prazo = escolhido;
    });
  }

  Future<void> _salvarMeta() async {
    if (_salvando || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _salvando = true;
    });

    try {
      final meta = widget.metaInicial;

      if (meta == null) {
        await BancoDados.instancia.inserirMeta(
          titulo: _tituloController.text.trim(),
          objetivo: lerValor(_objetivoController.text)!,
          guardado: lerValor(_guardadoController.text)!,
          prazo: _prazo,
        );
      } else {
        await BancoDados.instancia.atualizarMeta(
          meta['id'] as int,
          titulo: _tituloController.text.trim(),
          objetivo: lerValor(_objetivoController.text)!,
          guardado: lerValor(_guardadoController.text)!,
          prazo: _prazo,
        );
      }
    } catch (erro) {
      debugPrint('Erro ao salvar meta: $erro');

      if (!mounted) return;

      setState(() {
        _salvando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar a meta. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    // Informa à tela anterior que houve gravação.
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_salvando,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4EEDB),
        appBar: AppBar(
          title: Text(_editando ? 'Editar meta' : 'Nova meta'),
          backgroundColor: const Color(0xFFF5C518),
          foregroundColor: const Color(0xFF111111),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _tituloController,
                      enabled: !_salvando,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Nome da meta',
                        hintText: 'Ex.: Reserva de emergência',
                        prefixIcon: Icon(Icons.flag_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (texto) {
                        if (texto == null || texto.trim().isEmpty) {
                          return 'Informe o nome da meta.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _objetivoController,
                      enabled: !_salvando,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor desejado',
                        prefixText: 'R\$ ',
                        hintText: 'Ex.: 5000,00',
                        border: OutlineInputBorder(),
                      ),
                      validator: (texto) =>
                          _validarValor(texto, objetivo: true),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _guardadoController,
                      enabled: !_salvando,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor já guardado',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (texto) =>
                          _validarValor(texto, objetivo: false),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'O valor guardado acompanha seu progresso. '
                      'Este cadastro não altera o saldo das transações.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: _salvando ? null : _escolherPrazo,
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        _prazo == null
                            ? 'Definir prazo (opcional)'
                            : 'Prazo: ${formatarData(_prazo!)}',
                      ),
                    ),
                    if (_prazo != null)
                      TextButton(
                        onPressed: _salvando
                            ? null
                            : () {
                                setState(() {
                                  _prazo = null;
                                });
                              },
                        child: const Text('Remover prazo'),
                      ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _salvando ? null : _salvarMeta,
                      icon: _salvando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _salvando
                            ? 'Salvando...'
                            : (_editando ? 'Salvar alterações' : 'Salvar meta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
