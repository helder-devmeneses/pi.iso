import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Cores fixas por categoria, seguindo o protótipo da equipe.
const Map<String, Color> coresDasCategorias = {
  'Alimentação': Color(0xFF42A5F5),
  'Transporte': Color(0xFF66BB6A),
  'Moradia': Color(0xFFFFB300),
  'Lazer': Color(0xFF1565C0),
  'Saúde': Color(0xFFEF5350),
  'Educação': Color(0xFFAB47BC),
  'Salário': Color(0xFF26A69A),
  'Outros': Color(0xFF90A4AE),
};

Color corDaCategoria(String categoria) {
  return coresDasCategorias[categoria] ?? const Color(0xFF90A4AE);
}

/// Uma fatia do gráfico: categoria, valor somado e cor.
class Fatia {
  final String rotulo;
  final double valor;
  final Color cor;

  const Fatia({
    required this.rotulo,
    required this.valor,
    required this.cor,
  });
}

/// Gráfico de rosca com o total no centro, desenhado com CustomPaint
/// (sem biblioteca externa).
class GraficoRosca extends StatelessWidget {
  final List<Fatia> fatias;
  final String textoCentral;
  final double tamanho;

  const GraficoRosca({
    super.key,
    required this.fatias,
    required this.textoCentral,
    this.tamanho = 150,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: CustomPaint(
        painter: _PintorDaRosca(fatias),
        child: Center(
          child: Text(
            textoCentral,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _PintorDaRosca extends CustomPainter {
  final List<Fatia> fatias;

  _PintorDaRosca(this.fatias);

  @override
  void paint(Canvas canvas, Size size) {
    final total = fatias.fold(0.0, (soma, fatia) => soma + fatia.valor);

    final espessura = size.width * 0.16;
    final centro = Offset(size.width / 2, size.height / 2);
    final raio = (size.width - espessura) / 2;

    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessura;

    if (total <= 0) {
      pincel.color = Colors.black12;
      canvas.drawCircle(centro, raio, pincel);
      return;
    }

    // Começa no topo (meio-dia) e segue no sentido horário.
    var anguloInicial = -math.pi / 2;

    for (final fatia in fatias) {
      final varredura = (fatia.valor / total) * 2 * math.pi;

      pincel.color = fatia.cor;

      canvas.drawArc(
        Rect.fromCircle(center: centro, radius: raio),
        anguloInicial,
        varredura,
        false,
        pincel,
      );

      anguloInicial += varredura;
    }
  }

  @override
  bool shouldRepaint(_PintorDaRosca anterior) {
    return anterior.fatias != fatias;
  }
}
