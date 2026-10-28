import 'package:flutter/material.dart';

import '../data/perfil.dart';
import 'boas_vindas_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String _nome = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final nome = await Perfil.nome();
    final email = await Perfil.email();

    if (!mounted) return;

    setState(() {
      _nome = nome;
      _email = email;
    });
  }

  void _avisar(String mensagem, {required bool falhou}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: falhou ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _editarPerfil() async {
    final chaveFormulario = GlobalKey<FormState>();
    final nomeController = TextEditingController(text: _nome);
    final emailController = TextEditingController(text: _email);

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar perfil'),
        content: Form(
          key: chaveFormulario,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomeController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Informe seu nome';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || !valor.contains('@')) {
                    return 'Informe um e-mail válido';
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (!chaveFormulario.currentState!.validate()) return;

              Navigator.pop(context, true);
            },
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      await Perfil.salvarPerfil(
        nome: nomeController.text,
        email: emailController.text,
      );

      if (!mounted) return;

      await _carregarPerfil();

      if (!mounted) return;

      _avisar('Perfil atualizado.', falhou: false);
    }

    nomeController.dispose();
    emailController.dispose();
  }

  Future<void> _alterarSenha() async {
    final chaveFormulario = GlobalKey<FormState>();
    final senhaController = TextEditingController();
    final confirmacaoController = TextEditingController();

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Segurança'),
        content: Form(
          key: chaveFormulario,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Defina a senha usada para entrar no aplicativo.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova senha',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.length < 6) {
                    return 'Use pelo menos 6 caracteres';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmacaoController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Repita a nova senha',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor != senhaController.text) {
                    return 'As senhas não são iguais';
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (!chaveFormulario.currentState!.validate()) return;

              Navigator.pop(context, true);
            },
            icon: const Icon(Icons.shield_outlined),
            label: const Text('Salvar senha'),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      await Perfil.salvarSenha(senhaController.text);

      if (!mounted) return;

      _avisar(
        'Senha alterada. Use a nova senha no próximo acesso.',
        falhou: false,
      );
    }

    senhaController.dispose();
    confirmacaoController.dispose();
  }

  void _abrirNotificacoes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const _NotificacoesScreen(),
      ),
    );
  }

  void _abrirAjuda() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda'),
        content: const SingleChildScrollView(
          child: Text(
            'O PI.ISO ajuda você a controlar suas finanças:\n\n'
            '• Início: resumo do saldo, receitas e despesas.\n'
            '• Transações: extrato completo, com busca, filtros, '
            'edição e exclusão.\n'
            '• Metas: objetivos de economia com depósitos e progresso.\n'
            '• Relatórios: maior despesa, gastos por categoria e '
            'totais por mês.\n'
            '• Geladeira: registre um desejo de compra e espere ele '
            'esfriar antes de decidir.\n\n'
            'Os dados ficam gravados no seu aparelho e funcionam '
            'sem internet.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Future<void> _sair() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja sair do aplicativo?'),
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
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmou != true || !mounted) return;

    // Encerra a sessão: o próximo acesso pedirá login de novo.
    await Perfil.salvarSessao(false);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const BoasVindasScreen()),
      (rota) => false,
    );
  }

  Widget _criarOpcao({
    required IconData icone,
    required String titulo,
    required VoidCallback aoTocar,
    Color? cor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icone, color: cor ?? const Color(0xFFD9A928)),
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: cor,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: aoTocar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEDB),
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5C518),
        foregroundColor: const Color(0xFF111111),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const CircleAvatar(
                  radius: 48,
                  backgroundColor: Color(0xFFF5C518),
                  child: Icon(
                    Icons.person,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _nome,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 28),
                _criarOpcao(
                  icone: Icons.person_outline,
                  titulo: 'Editar perfil',
                  aoTocar: _editarPerfil,
                ),
                _criarOpcao(
                  icone: Icons.shield_outlined,
                  titulo: 'Segurança',
                  aoTocar: _alterarSenha,
                ),
                _criarOpcao(
                  icone: Icons.notifications_outlined,
                  titulo: 'Notificações',
                  aoTocar: _abrirNotificacoes,
                ),
                _criarOpcao(
                  icone: Icons.help_outline,
                  titulo: 'Ajuda',
                  aoTocar: _abrirAjuda,
                ),
                _criarOpcao(
                  icone: Icons.logout,
                  titulo: 'Sair',
                  cor: Colors.red,
                  aoTocar: _sair,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Preferências de aviso, guardadas no aparelho. Os alertas em si
// serão implementados na etapa de orientação financeira.
class _NotificacoesScreen extends StatefulWidget {
  const _NotificacoesScreen();

  @override
  State<_NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<_NotificacoesScreen> {
  bool _alertaDeGastos = true;
  bool _lembreteDeMetas = true;
  bool _avisoDaGeladeira = true;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final gastos = await Perfil.notificacao('gastos');
    final metas = await Perfil.notificacao('metas');
    final geladeira = await Perfil.notificacao('geladeira');

    if (!mounted) return;

    setState(() {
      _alertaDeGastos = gastos;
      _lembreteDeMetas = metas;
      _avisoDaGeladeira = geladeira;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEDB),
      appBar: AppBar(
        title: const Text('Notificações'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5C518),
        foregroundColor: const Color(0xFF111111),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      child: SwitchListTile(
                        title: const Text('Alerta de gastos'),
                        subtitle: const Text(
                          'Avisar quando as despesas do mês crescerem '
                          'demais.',
                        ),
                        value: _alertaDeGastos,
                        onChanged: (ligada) {
                          setState(() => _alertaDeGastos = ligada);
                          Perfil.salvarNotificacao('gastos', ligada);
                        },
                      ),
                    ),
                    Card(
                      child: SwitchListTile(
                        title: const Text('Lembrete de metas'),
                        subtitle: const Text(
                          'Lembrar de depositar nas metas.',
                        ),
                        value: _lembreteDeMetas,
                        onChanged: (ligada) {
                          setState(() => _lembreteDeMetas = ligada);
                          Perfil.salvarNotificacao('metas', ligada);
                        },
                      ),
                    ),
                    Card(
                      child: SwitchListTile(
                        title: const Text('Aviso da Geladeira'),
                        subtitle: const Text(
                          'Avisar quando um desejo terminar a espera.',
                        ),
                        value: _avisoDaGeladeira,
                        onChanged: (ligada) {
                          setState(() => _avisoDaGeladeira = ligada);
                          Perfil.salvarNotificacao('geladeira', ligada);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'As preferências ficam salvas no aparelho. O envio '
                      'dos avisos será ativado na etapa de orientação '
                      'financeira.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
