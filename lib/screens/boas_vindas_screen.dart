import 'package:flutter/material.dart';

import '../data/biometria.dart';
import '../data/perfil.dart';
import 'cadastro_screen.dart';
import 'login_screen.dart';
import 'piso_shell.dart';

/// Primeira tela do aplicativo, como no protótipo da equipe:
/// boas-vindas com as opções Entrar e Criar conta.
///
/// Se a sessão anterior ficou aberta, entra direto — pedindo a
/// digital quando o aparelho tiver leitor.
class BoasVindasScreen extends StatefulWidget {
  const BoasVindasScreen({super.key});

  @override
  State<BoasVindasScreen> createState() => _BoasVindasScreenState();
}

class _BoasVindasScreenState extends State<BoasVindasScreen> {
  @override
  void initState() {
    super.initState();
    _entradaAutomatica();
  }

  Future<void> _entradaAutomatica() async {
    final senha = await Perfil.senha();
    final logado = await Perfil.estaLogado();

    if (senha == null || !logado || !mounted) return;

    if (await Biometria.disponivel()) {
      final confirmou = await Biometria.autenticar();

      if (!confirmou) return;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PisoShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEDB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 56,
                  backgroundColor: Color(0xFFF5C518),
                  child: Icon(Icons.balance, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'PI.ISO',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                    color: Color(0xFFD9682A),
                  ),
                ),
                const Text(
                  'Controle Financeiro',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.black54,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 36),
                const Text(
                  'Bem-vindo(a)!',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Controle seus gastos, cuide do seu bolso\n'
                  'e alcance suas metas financeiras.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, color: Colors.black54),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Entrar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CadastroScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFF5C518),
                        width: 2,
                      ),
                    ),
                    child: const Text(
                      'Criar conta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD9A928),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Seus dados ficam somente no seu aparelho\n'
                  'e funcionam sem internet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
