import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iso/main.dart';

void main() {
  testWidgets('Exibe o login e valida campos vazios', (tester) async {
    await tester.pumpWidget(const PisoApp());

    expect(find.text('PI.ISO'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);

    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu e-mail'), findsOneWidget);
    expect(find.text('Informe sua senha'), findsOneWidget);
  });
}