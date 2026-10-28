/// Funções de formatação usadas por todas as telas.
///
/// Antes da etapa 11, cada tela tinha a sua própria cópia destas
/// funções. Agora existe uma única versão, em um único lugar.
library;

const List<String> nomesDosMeses = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

/// 1234.5 vira "R$ 1.234,50"; valores negativos ganham o sinal "-".
String formatarMoeda(double valor) {
  final sinal = valor < 0 ? '-' : '';
  final partes = valor.abs().toStringAsFixed(2).split('.');

  final parteInteira = partes[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (resultado) => '${resultado[1]}.',
  );

  return '$sinal R\$ $parteInteira,${partes[1]}'.trim();
}

/// "dd/mm/aaaa".
String formatarData(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');

  return '$dia/$mes/${data.year}';
}

/// "dd/mm", para listas compactas.
String formatarDiaMes(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');

  return '$dia/$mes';
}

/// 9 e 2026 viram "Setembro de 2026".
String nomeDoMesEAno(int mes, int ano) {
  if (mes < 1 || mes > 12) return '$mes/$ano';

  return '${nomesDosMeses[mes - 1]} de $ano';
}

/// "2026-09" (formato do banco) vira "Setembro de 2026".
String nomeDoMes(String mes) {
  final partes = mes.split('-');

  if (partes.length != 2) return mes;

  final numeroDoMes = int.tryParse(partes[1]);
  final ano = int.tryParse(partes[0]);

  if (numeroDoMes == null || ano == null) return mes;

  return nomeDoMesEAno(numeroDoMes, ano);
}

/// Lê um valor digitado, aceitando vírgula ou ponto e até duas
/// casas. Devolve nulo quando o texto não é um valor válido.
double? lerValor(String texto) {
  final normalizado = texto.trim().replaceAll(',', '.');

  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalizado)) return null;

  final valor = double.tryParse(normalizado);

  if (valor == null || !valor.isFinite) return null;
  if (valor > 999999999.99) return null;

  return valor;
}
