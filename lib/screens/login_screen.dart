import 'package:flutter/material.dart';

import '../data/biometria.dart';
import '../data/perfil.dart';
import 'cadastro_screen.dart';
import 'piso_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _ocultarSenha = true;
  bool _digitalDisponivel = false;
  bool _lembrarEmail = true;

  @override
  void initState() {
    super.initState();
    _prepararTela();
  }

  // Lembra o e-mail cadastrado e verifica se há leitor de digital.
  Future<void> _prepararTela() async {
    final senha = await Perfil.senha();
    final lembrarEmail = await Perfil.lembrarEmail();
    final emailLembrado = await Perfil.emailLembrado();
    final emailDoPerfil = await Perfil.email();
    final digital = await Biometria.disponivel();

    if (!mounted) return;

    setState(() {
      _lembrarEmail = lembrarEmail;
      _emailController.text =
          lembrarEmail ? (emailLembrado ?? emailDoPerfil) : '';
      _digitalDisponivel = senha != null && digital;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _abrirAplicativo() async {
    await Perfil.salvarPreferenciaEmail(
      lembrar: _lembrarEmail,
      email: _emailController.text,
    );
    await Perfil.salvarSessao(true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const PisoShell(),
      ),
    );
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;

    // Enquanto o usuário não definir a senha em Perfil → Segurança,
    // qualquer senha com 6 ou mais caracteres entra.
    final senhaSalva = await Perfil.senha();

    if (!mounted) return;

    if (senhaSalva != null && _senhaController.text != senhaSalva) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha incorreta.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _abrirAplicativo();
  }

  Future<void> _entrarComDigital() async {
    final confirmou = await Biometria.autenticar();

    if (!confirmou || !mounted) return;

    await _abrirAplicativo();
  }

  void _avisarLoginSocial(String rede) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'O login com $rede será ativado em uma versão futura.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEDB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.balance,
                        size: 72,
                        color: Color(0xFFD9A928),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'PI.ISO',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Controle Financeiro',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) {
                            return 'Informe seu e-mail';
                          }

                          if (!valor.contains('@')) {
                            return 'Informe um e-mail válido';
                          }

                          return null;
                        },
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Lembrar meu e-mail'),
                        value: _lembrarEmail,
                        onChanged: (valor) {
                          setState(() {
                            _lembrarEmail = valor ?? false;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _senhaController,
                        obscureText: _ocultarSenha,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _ocultarSenha = !_ocultarSenha;
                              });
                            },
                            icon: Icon(
                              _ocultarSenha
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (valor) {
                          if (valor == null || valor.isEmpty) {
                            return 'Informe sua senha';
                          }

                          if (valor.length < 6) {
                            return 'A senha deve ter pelo menos 6 caracteres';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _entrar,
                          child: const Text(
                            'Entrar',
                            style: TextStyle(fontSize: 17),
                          ),
                        ),
                      ),
                      if (_digitalDisponivel) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _entrarComDigital,
                            icon: const Icon(Icons.fingerprint, size: 28),
                            label: const Text(
                              'Entrar com digital',
                              style: TextStyle(fontSize: 17),
                            ),
                          ),
                        ),
                      ],
                      TextButton(
                        onPressed: () {},
                        child: const Text('Esqueci minha senha'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CadastroScreen(),
                            ),
                          );
                        },
                        child: const Text('Não tenho conta — criar conta'),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'ou continue com',
                              style: TextStyle(color: Colors.black45),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _avisarLoginSocial('Google'),
                              icon: const Icon(Icons.g_mobiledata, size: 28),
                              label: const Text('Google'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _avisarLoginSocial('Apple'),
                              icon: const Icon(Icons.apple, size: 22),
                              label: const Text('Apple'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
