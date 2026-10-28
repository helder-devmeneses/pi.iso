import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iso/utils/formatos.dart';

void main() {
  test('formatarMoeda separa milhares e usa vírgula', () {
    expect(formatarMoeda(1234.5), 'R\$ 1.234,50');
    expect(formatarMoeda(0), 'R\$ 0,00');
    expect(formatarMoeda(1000000), 'R\$ 1.000.000,00');
  });

  test('formatarMoeda marca valores negativos', () {
    expect(formatarMoeda(-800), '- R\$ 800,00');
  });

  test('formatarData e formatarDiaMes preenchem com zero', () {
    final data = DateTime(2026, 9, 7);

    expect(formatarData(data), '07/09/2026');
    expect(formatarDiaMes(data), '07/09');
  });

  test('nomeDoMes traduz o formato do banco', () {
    expect(nomeDoMes('2026-09'), 'Setembro de 2026');
    expect(nomeDoMes('texto estranho'), 'texto estranho');
  });

  test('lerValor aceita vírgula ou ponto e recusa entradas inválidas', () {
    expect(lerValor('250,00'), 250.0);
    expect(lerValor('250.5'), 250.5);
    expect(lerValor('abc'), isNull);
    expect(lerValor('1.000,00'), isNull); // ponto de milhar não é aceito
    expect(lerValor('-5'), isNull);
    expect(lerValor('1000000000'), isNull); // acima do limite
  });
}
