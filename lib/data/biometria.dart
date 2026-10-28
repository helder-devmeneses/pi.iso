import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Entrada com a digital (ou rosto) usando o leitor do aparelho.
///
/// No Chrome (web) a biometria não existe; os métodos devolvem
/// falso e o aplicativo segue pelo e-mail e senha normalmente.
class Biometria {
  Biometria._();

  static final LocalAuthentication _autenticador = LocalAuthentication();

  static Future<bool> disponivel() async {
    if (kIsWeb) return false;

    try {
      final suportada = await _autenticador.isDeviceSupported();
      final cadastradas = await _autenticador.getAvailableBiometrics();

      return suportada && cadastradas.isNotEmpty;
    } catch (erro) {
      debugPrint('Biometria indisponível: $erro');
      return false;
    }
  }

  static Future<bool> autenticar() async {
    try {
      return await _autenticador.authenticate(
        localizedReason: 'Confirme sua identidade para entrar no PI.ISO',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (erro) {
      debugPrint('Erro na biometria: $erro');
      return false;
    }
  }
}
