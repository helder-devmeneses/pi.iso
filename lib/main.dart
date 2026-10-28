import 'package:flutter/material.dart';
import 'screens/boas_vindas_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'widgets/bloqueio_app.dart';

void main() {
  runApp(const PisoApp());
}

class PisoApp extends StatelessWidget {
  const PisoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      title: 'PI.ISO',
      builder: (context, child) => BloqueioApp(
        child: child ?? const SizedBox.shrink(),
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF5C518),
          primary: const Color(0xFFF5C518),
          surface: const Color(0xFFF8F8F5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4EEDB),
        useMaterial3: true,
      ),
      home: const BoasVindasScreen(),
    );
  }
}

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEDB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5C518),
        foregroundColor: const Color(0xFF111111),
        title: const Text('PI.ISO'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 90,
              color: Color(0xFFD9A928),
            ),
            SizedBox(height: 24),
            Text(
              'Controle Financeiro',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Controle seus gastos, cuide do seu bolso.',
              style: TextStyle(
                fontSize: 17,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
