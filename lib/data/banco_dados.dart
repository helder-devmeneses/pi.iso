import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BancoDados {
  BancoDados._();

  static final BancoDados instancia = BancoDados._();

  Future<Database>? _abertura;

  Future<Database> get banco {
    return _abertura ??= _abrirBanco();
  }

  Future<Database> _abrirBanco() async {
    try {
      final fabrica = kIsWeb ? databaseFactoryFfiWeb : databaseFactory;

      final caminho = kIsWeb
          ? 'pi_iso.db'
          : p.join(await getDatabasesPath(), 'pi_iso.db');

      return await fabrica.openDatabase(
        caminho,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, versao) async {
            await db.execute('''
              CREATE TABLE transacoes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                tipo TEXT NOT NULL
                  CHECK (tipo IN ('Receita', 'Despesa')),
                descricao TEXT NOT NULL,
                valor_centavos INTEGER NOT NULL
                  CHECK (valor_centavos > 0),
                categoria TEXT NOT NULL,
                data TEXT NOT NULL
              )
            ''');
            await _criarTabelaMetas(db);
            await _criarTabelaGeladeira(db);
          },
          onUpgrade: (db, versaoAntiga, novaVersao) async {
            if (versaoAntiga < 2) {
              await _criarTabelaMetas(db);
            }
            if (versaoAntiga < 3) {
              await _criarTabelaGeladeira(db);
            }
          },
        ),
      );
    } catch (erro) {
      _abertura = null;
      rethrow;
    }
  }

  // Cria a tabela que armazenará as metas financeiras.
  Future<void> _criarTabelaMetas(Database db) async {
    await db.execute('''
      CREATE TABLE metas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL CHECK (length(trim(titulo)) > 0),
        objetivo_centavos INTEGER NOT NULL
          CHECK (objetivo_centavos > 0),
        guardado_centavos INTEGER NOT NULL DEFAULT 0
          CHECK (guardado_centavos >= 0),
        prazo TEXT
      )
    ''');
  }

  // Guarda os desejos de compra que ficam esperando na Geladeira.
  Future<void> _criarTabelaGeladeira(Database db) async {
    await db.execute('''
      CREATE TABLE geladeira (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao TEXT NOT NULL CHECK (length(trim(descricao)) > 0),
        valor_centavos INTEGER NOT NULL CHECK (valor_centavos > 0),
        categoria TEXT NOT NULL,
        criado_em TEXT NOT NULL,
        espera_ate TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'esperando'
          CHECK (status IN ('esperando', 'comprado', 'desistido'))
      )
    ''');
  }

  Map<String, Object?> _paraRegistro(Map<String, dynamic> transacao) {
    final valor = (transacao['valor'] as num).toDouble();

    if (!valor.isFinite || valor <= 0) {
      throw ArgumentError('O valor deve ser positivo e válido.');
    }

    final centavos = (valor * 100).round();

    if (centavos <= 0) {
      throw ArgumentError('O valor mínimo é R\$ 0,01.');
    }

    return {
      'tipo': transacao['tipo'],
      'descricao': (transacao['descricao'] as String).trim(),
      'valor_centavos': centavos,
      'categoria': transacao['categoria'],
      'data': (transacao['data'] as DateTime).toIso8601String(),
    };
  }

  Future<int> inserirTransacao(Map<String, dynamic> transacao) async {
    final registro = _paraRegistro(transacao);
    final db = await banco;

    return await db.insert('transacoes', registro);
  }

  Future<List<Map<String, dynamic>>> listarTransacoes() async {
    final db = await banco;

    final registros = await db.query('transacoes', orderBy: 'id DESC');

    return registros.map((registro) {
      return <String, dynamic>{
        'id': registro['id'] as int,
        'tipo': registro['tipo'] as String,
        'descricao': registro['descricao'] as String,
        'valor': (registro['valor_centavos'] as int) / 100,
        'categoria': registro['categoria'] as String,
        'data': DateTime.parse(registro['data'] as String),
      };
    }).toList();
  }

  Future<int> atualizarTransacao(int id, Map<String, dynamic> transacao) async {
    final registro = _paraRegistro(transacao);
    final db = await banco;

    return await db.update(
      'transacoes',
      registro,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Valida os dados da meta e devolve o registro pronto para o banco.
  Map<String, Object?> _metaParaRegistro({
    required String titulo,
    required double objetivo,
    required double guardado,
    DateTime? prazo,
  }) {
    final tituloLimpo = titulo.trim();

    if (tituloLimpo.isEmpty) {
      throw ArgumentError('Informe o nome da meta.');
    }

    if (!objetivo.isFinite || objetivo <= 0) {
      throw ArgumentError('Informe um objetivo positivo e válido.');
    }

    if (!guardado.isFinite || guardado < 0) {
      throw ArgumentError('O valor guardado deve ser zero ou positivo.');
    }

    final objetivoCentavos = (objetivo * 100).round();

    if (objetivoCentavos < 1) {
      throw ArgumentError('O objetivo mínimo é R\$ 0,01.');
    }

    return {
      'titulo': tituloLimpo,
      'objetivo_centavos': objetivoCentavos,
      'guardado_centavos': (guardado * 100).round(),
      'prazo': prazo?.toIso8601String(),
    };
  }

  Future<int> inserirMeta({
    required String titulo,
    required double objetivo,
    double guardado = 0,
    DateTime? prazo,
  }) async {
    final registro = _metaParaRegistro(
      titulo: titulo,
      objetivo: objetivo,
      guardado: guardado,
      prazo: prazo,
    );

    final db = await banco;

    return await db.insert('metas', registro);
  }

  Future<int> atualizarMeta(
    int id, {
    required String titulo,
    required double objetivo,
    required double guardado,
    DateTime? prazo,
  }) async {
    final registro = _metaParaRegistro(
      titulo: titulo,
      objetivo: objetivo,
      guardado: guardado,
      prazo: prazo,
    );

    final db = await banco;

    return await db.update('metas', registro, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> excluirMeta(int id) async {
    final db = await banco;

    return await db.delete('metas', where: 'id = ?', whereArgs: [id]);
  }

  // Soma dentro do banco, não no aplicativo: dois depósitos seguidos
  // nunca sobrescrevem um ao outro.
  Future<int> depositarNaMeta(int id, double valor) async {
    if (!valor.isFinite || valor <= 0) {
      throw ArgumentError('Informe um valor positivo.');
    }

    final centavos = (valor * 100).round();

    if (centavos < 1) {
      throw ArgumentError('O valor mínimo é R\$ 0,01.');
    }

    final db = await banco;

    return await db.rawUpdate(
      'UPDATE metas SET guardado_centavos = guardado_centavos + ? '
      'WHERE id = ?',
      [centavos, id],
    );
  }

  Future<List<Map<String, dynamic>>> listarMetas() async {
    final db = await banco;

    final registros = await db.query('metas', orderBy: 'id DESC');

    return registros.map((registro) {
      final prazo = registro['prazo'] as String?;

      return <String, dynamic>{
        'id': registro['id'] as int,
        'titulo': registro['titulo'] as String,
        'objetivo': (registro['objetivo_centavos'] as int) / 100,
        'guardado': (registro['guardado_centavos'] as int) / 100,
        'prazo': prazo == null ? null : DateTime.parse(prazo),
      };
    }).toList();
  }

  Future<int> excluirTransacao(int id) async {
    final db = await banco;

    return await db.delete('transacoes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> importarTransacoesAntigas() async {
    final db = await banco;

    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS migracoes (
          nome TEXT PRIMARY KEY
        )
      ''');

      const nome = 'transacoes_shared_preferences_v1';

      final concluida = await txn.query(
        'migracoes',
        where: 'nome = ?',
        whereArgs: [nome],
      );

      if (concluida.isNotEmpty) {
        return;
      }

      final preferencias = SharedPreferencesAsync();
      final texto = await preferencias.getString('transacoes');

      if (texto != null && texto.isNotEmpty) {
        final lista = jsonDecode(texto) as List<dynamic>;

        for (final item in lista.reversed) {
          final transacao = Map<String, dynamic>.from(item as Map);

          transacao['data'] = DateTime.parse(transacao['data'] as String);

          await txn.insert('transacoes', _paraRegistro(transacao));
        }
      }

      await txn.insert('migracoes', {'nome': nome});
    });
  }

  Future<int> inserirDesejo({
    required String descricao,
    required double valor,
    required String categoria,
    required int diasDeEspera,
  }) async {
    final descricaoLimpa = descricao.trim();

    if (descricaoLimpa.isEmpty) {
      throw ArgumentError('Informe o que você deseja comprar.');
    }

    if (!valor.isFinite || valor <= 0) {
      throw ArgumentError('Informe um valor positivo e válido.');
    }

    final centavos = (valor * 100).round();

    if (centavos < 1) {
      throw ArgumentError('O valor mínimo é R\$ 0,01.');
    }

    // Zero dias libera a decisão no mesmo dia (útil em demonstrações).
    if (diasDeEspera < 0) {
      throw ArgumentError('O período de espera não pode ser negativo.');
    }

    final agora = DateTime.now();

    final db = await banco;

    return await db.insert('geladeira', {
      'descricao': descricaoLimpa,
      'valor_centavos': centavos,
      'categoria': categoria,
      'criado_em': agora.toIso8601String(),
      'espera_ate':
          agora.add(Duration(days: diasDeEspera)).toIso8601String(),
      'status': 'esperando',
    });
  }

  Future<List<Map<String, dynamic>>> listarDesejos() async {
    final db = await banco;

    // Os que ainda esperam aparecem primeiro; depois, o histórico.
    final registros = await db.query(
      'geladeira',
      orderBy: "CASE WHEN status = 'esperando' THEN 0 ELSE 1 END, id DESC",
    );

    return registros.map((registro) {
      return <String, dynamic>{
        'id': registro['id'] as int,
        'descricao': registro['descricao'] as String,
        'valor': (registro['valor_centavos'] as int) / 100,
        'categoria': registro['categoria'] as String,
        'criadoEm': DateTime.parse(registro['criado_em'] as String),
        'esperaAte': DateTime.parse(registro['espera_ate'] as String),
        'status': registro['status'] as String,
      };
    }).toList();
  }

  // Registra a decisão final: 'comprado' ou 'desistido'.
  Future<int> decidirDesejo(int id, String status) async {
    if (status != 'comprado' && status != 'desistido') {
      throw ArgumentError('Decisão inválida: $status');
    }

    final db = await banco;

    return await db.update(
      'geladeira',
      {'status': status},
      where: "id = ? AND status = 'esperando'",
      whereArgs: [id],
    );
  }

  Future<int> excluirDesejo(int id) async {
    final db = await banco;

    return await db.delete('geladeira', where: 'id = ?', whereArgs: [id]);
  }

  // Despesas somadas por categoria, da maior para a menor.
  Future<List<Map<String, dynamic>>> despesasPorCategoria() async {
    final db = await banco;

    final registros = await db.rawQuery('''
    SELECT categoria, SUM(valor_centavos) AS total
    FROM transacoes
    WHERE tipo = 'Despesa'
    GROUP BY categoria
    ORDER BY total DESC
  ''');

    return registros.map((registro) {
      return <String, dynamic>{
        'categoria': registro['categoria'] as String,
        'total': (registro['total'] as num) / 100,
      };
    }).toList();
  }

  // Receitas e despesas de cada mês, do mais recente para o mais antigo.
  Future<List<Map<String, dynamic>>> totaisPorMes() async {
    final db = await banco;

    final registros = await db.rawQuery('''
    SELECT substr(data, 1, 7) AS mes,
           SUM(CASE WHEN tipo = 'Receita' THEN valor_centavos ELSE 0 END)
             AS receitas,
           SUM(CASE WHEN tipo = 'Despesa' THEN valor_centavos ELSE 0 END)
             AS despesas
    FROM transacoes
    GROUP BY mes
    ORDER BY mes DESC
  ''');

    return registros.map((registro) {
      return <String, dynamic>{
        'mes': registro['mes'] as String,
        'receitas': (registro['receitas'] as num) / 100,
        'despesas': (registro['despesas'] as num) / 100,
      };
    }).toList();
  }

  // A despesa isolada mais alta. Nulo quando não há despesas.
  Future<Map<String, dynamic>?> maiorDespesa() async {
    final db = await banco;

    final registros = await db.query(
      'transacoes',
      where: 'tipo = ?',
      whereArgs: ['Despesa'],
      orderBy: 'valor_centavos DESC',
      limit: 1,
    );

    if (registros.isEmpty) return null;

    final registro = registros.first;

    return <String, dynamic>{
      'descricao': registro['descricao'] as String,
      'categoria': registro['categoria'] as String,
      'valor': (registro['valor_centavos'] as num) / 100,
      'data': DateTime.parse(registro['data'] as String),
    };
  }
}
