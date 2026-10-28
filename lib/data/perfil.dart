import 'package:shared_preferences/shared_preferences.dart';

/// Dados do usuário e preferências, guardados no aparelho.
///
/// O SQLite guarda os lançamentos; aqui ficam apenas chaves simples
/// de perfil, então o shared_preferences é suficiente.
class Perfil {
  Perfil._();

  static final SharedPreferencesAsync _preferencias =
      SharedPreferencesAsync();

  static Future<String> nome() async {
    final valor = await _preferencias.getString('perfil_nome');

    return (valor == null || valor.trim().isEmpty) ? 'Helder' : valor;
  }

  static Future<String> email() async {
    final valor = await _preferencias.getString('perfil_email');

    return (valor == null || valor.trim().isEmpty)
        ? 'helder@piiso.com'
        : valor;
  }

  static Future<void> salvarPerfil({
    required String nome,
    required String email,
  }) async {
    await _preferencias.setString('perfil_nome', nome.trim());
    await _preferencias.setString('perfil_email', email.trim());
  }

  /// Nulo enquanto o usuário não definir uma senha própria.
  static Future<String?> senha() {
    return _preferencias.getString('perfil_senha');
  }

  static Future<void> salvarSenha(String senha) {
    return _preferencias.setString('perfil_senha', senha);
  }

  /// Verdadeiro enquanto o usuário estiver com a sessão aberta:
  /// o aplicativo entra direto, sem pedir e-mail e senha de novo.
  static Future<bool> estaLogado() async {
    return await _preferencias.getBool('sessao_ativa') ?? false;
  }

  static Future<void> salvarSessao(bool ativa) {
    return _preferencias.setBool('sessao_ativa', ativa);
  }

  static Future<bool> lembrarEmail() async {
    return await _preferencias.getBool('lembrar_email') ?? true;
  }

  static Future<String?> emailLembrado() {
    return _preferencias.getString('login_email_lembrado');
  }

  static Future<void> salvarPreferenciaEmail({
    required bool lembrar,
    required String email,
  }) async {
    await _preferencias.setBool('lembrar_email', lembrar);

    if (lembrar) {
      await _preferencias.setString(
        'login_email_lembrado',
        email.trim(),
      );
    } else {
      await _preferencias.remove('login_email_lembrado');
    }
  }

  static Future<bool> notificacao(String chave) async {
    return await _preferencias.getBool('notif_$chave') ?? true;
  }

  static Future<void> salvarNotificacao(String chave, bool ligada) {
    return _preferencias.setBool('notif_$chave', ligada);
  }
}
