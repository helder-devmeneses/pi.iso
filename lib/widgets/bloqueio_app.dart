import 'package:flutter/material.dart';

import '../data/biometria.dart';
import '../data/perfil.dart';

/// Bloqueia o conteúdo quando o aplicativo sai do primeiro plano.
///
/// O usuário retorna exatamente à tela em que estava depois de confirmar
/// a identidade por biometria ou pela senha cadastrada no PI.ISO.
class BloqueioApp extends StatefulWidget {
  const BloqueioApp({required this.child, super.key});

  final Widget child;

  @override
  State<BloqueioApp> createState() => _BloqueioAppState();
}

class _BloqueioAppState extends State<BloqueioApp>
    with WidgetsBindingObserver {
  final _senhaController = TextEditingController();

  bool _bloqueado = false;
  bool _autenticando = false;
  bool _digitalDisponivel = false;
  bool _ocultarSenha = true;
  String _email = '';
  AppLifecycleState? _ultimoEstado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _senhaController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final estadoAnterior = _ultimoEstado;
    _ultimoEstado = state;

    if (_autenticando) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _bloquearSeNecessario();
      return;
    }

    if (state == AppLifecycleState.resumed &&
        estadoAnterior != null &&
        estadoAnterior != AppLifecycleState.resumed) {
      _prepararDesbloqueio();
    }
  }

  Future<void> _bloquearSeNecessario() async {
    if (!await Perfil.estaLogado() || !mounted) return;

    setState(() => _bloqueado = true);
  }

  Future<void> _prepararDesbloqueio() async {
    if (!await Perfil.estaLogado() || !mounted) return;

    final email = await Perfil.email();
    final digital = await Biometria.disponivel();

    if (!mounted) return;

    setState(() {

      _email = email;
      _digitalDisponivel = digital;
    });


  }

  Future<void> _usarBiometria() async {
    if (_autenticando) return;

    setState(() => _autenticando = true);
    final confirmou = await Biometria.autenticar();

    if (!mounted) return;

    setState(() {
      _autenticando = false;
      if (confirmou) {
        _bloqueado = false;
        _senhaController.clear();
      }
    });
  }

  Future<void> _usarSenha() async {
    final senha = await Perfil.senha();

    if (!mounted) return;

    if (senha != null && _senhaController.text == senha) {
      setState(() {
        _bloqueado = false;
        _senhaController.clear();
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Senha incorreta.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_bloqueado)
          Positioned.fill(
            child: Material(
              color: const Color(0xFFF4EEDB),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                size: 64,
                                color: Color(0xFFD9A928),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'PI.ISO bloqueado',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _email,
                                style: const TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _senhaController,
                                obscureText: _ocultarSenha,
                                onSubmitted: (_) => _usarSenha(),
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  prefixIcon:
                                      const Icon(Icons.lock_outline),
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
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: FilledButton(
                                  onPressed: _usarSenha,
                                  child: const Text('Entrar com senha'),
                                ),
                              ),
                              if (_digitalDisponivel) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _autenticando ? null : _usarBiometria,
                                    icon: const Icon(
                                      Icons.fingerprint,
                                      size: 28,
                                    ),
                                    label: Text(
                                      _autenticando
                                          ? 'Aguardando biometria...'
                                          : 'Entrar com biometria',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
