import 'dart:convert';
import 'package:api/database/db_helper.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;
  final params = context.request.uri.queryParameters;
  final idParam = params['id'];

  switch (method) {
    case HttpMethod.get:
      // PASSAMOS o idParam aqui
      return _handleGet(idParam);
    case HttpMethod.post:
      return _handlePost(context);
    case HttpMethod.put:
      return _handlePut(context, idParam);
    case HttpMethod.delete:
      return _handleDelete(idParam);
    default:
      return Response(statusCode: 405);
  }
}

Response _handleGet(String? id) {
  try {
    // 1. Busca os dados no banco
    final resultados = (id != null)
        ? dbHelper.db
            .select('SELECT * FROM tarefas WHERE id = ?', [int.tryParse(id)])
        : dbHelper.db.select('SELECT * FROM tarefas');

    if (id != null && resultados.isEmpty) {
      return Response.json(
          body: {'erro': 'Tarefa não encontrada'}, statusCode: 404);
    }

    final agora = DateTime.now();

    final lista = resultados.map((row) {
      List<dynamic> logsLista;
      try {
        logsLista = jsonDecode(row['logs'] as String) as List<dynamic>;
      } catch (e) {
        logsLista = [];
      }

      final prazo = DateTime.parse(row['prazo'] as String);
      final status = row['status'] as String;

      return {
        'id': row['id'],
        'cliente': row['cliente'],
        'cnpj': row['cnpj'],
        'tipo': row['tipo'], //tarefa
        'prazo': row['prazo'],
        'status': status,
        'observacao': row['observacao'],
        'logs': logsLista,
        'urgente': _verificarUrgencia(row['prazo'] as String, status),
      };
    }).toList();

    // 2. Se for a listagem geral, calculamos o resumo para os cards da foto
    if (id == null) {
      final resumo = {
        // PENDENTES: Somente aquelas que não venceram ainda
        'pendentes': lista
            .where(
              (t) =>
                  t['status'] != 'concluido' &&
                  !DateTime.parse(t['prazo'] as String).isBefore(agora),
            )
            .length,

        // CONCLUÍDAS: Independente da data
        'concluidas': lista.where((t) => t['status'] == 'concluido').length,

        // ATRASADAS: Aquelas que venceram e não foram concluídas
        'atrasadas': lista.where((t) {
          final prazo = DateTime.parse(t['prazo'] as String);
          return prazo.isBefore(agora) && t['status'] != 'concluido';
        }).length,
      };

      return Response.json(
        body: {
          'resumo': resumo,
          'tarefas': lista,
        },
      );
    }

    return Response.json(body: lista.first);
  } catch (e) {
    return Response.json(
      body: {'erro': 'Falha ao buscar tarefas', 'detalhe': e.toString()},
      statusCode: 500,
    );
  }
}

bool _verificarUrgencia(String prazoStr, String status) {
  final data = DateTime.parse(prazoStr);
  final dia = data.day;
  return (dia == 15 || dia == 20) && status != 'validado';
}

Future<Response> _handlePost(RequestContext context) async {
  // EXTRAÇÃO JWT: Pegamos o nome do usuário injetado pelo Middleware
  final userData = context.read<Map<String, dynamic>>();
  final autor = userData['nome'] as String;

  final body = await context.request.json() as Map<String, dynamic>;
  final logsIniciais = jsonEncode(['Criado por $autor em ${DateTime.now()}']);

  dbHelper.db.execute(
    'INSERT INTO tarefas (cliente, cnpj, tipo, prazo, status, observacao, logs) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [
      body['cliente'],
      body['cnpj'],
      body['tipo'], //tarefa
      body['prazo'],
      'pendente',
      body['observacao'] ?? '',
      logsIniciais
    ],
  );

  final lastId = dbHelper.db.lastInsertRowId;
  return Response.json(statusCode: 201, body: {'id': lastId, 'autor': autor});
}

Future<Response> _handlePut(RequestContext context, String? id) async {
  if (id == null) return Response(statusCode: 400);
  final idInt = int.tryParse(id);

  // EXTRAÇÃO JWT: Nome do autor vem do Token, não do Body
  final userData = context.read<Map<String, dynamic>>();
  final autor = userData['nome'] as String;

  final resultado =
      dbHelper.db.select('SELECT * FROM tarefas WHERE id = ?', [idInt]);
  if (resultado.isEmpty) return Response(statusCode: 404);

  final body = await context.request.json() as Map<String, dynamic>;
  final row = resultado.first;

  final logsAtuais =
      List<dynamic>.from(jsonDecode(row['logs'] as String) as List);

  if (body['status'] != null) {
    logsAtuais.add(
        'Status alterado para [${body['status']}] por $autor em ${DateTime.now()}');
  }

  dbHelper.db.execute(
    'UPDATE tarefas SET cliente = ?, cnpj = ?, tipo = ?, prazo = ?, status = ?, observacao = ?, logs = ? WHERE id = ?',
    [
      body['cliente'] ?? row['cliente'],
      body['cnpj'] ?? row['cnpj'],
      body['tipo'] ?? row['tipo'], //tarefa
      body['prazo'] ?? row['prazo'],
      body['status'] ?? row['status'],
      body['observacao'] ?? row['observacao'],
      jsonEncode(logsAtuais),
      idInt
    ],
  );

  return Response.json(body: {'mensagem': 'Atualizado com sucesso por $autor'});
}

Response _handleDelete(String? id) {
  if (id == null) return Response(statusCode: 400);
  final idInt = int.tryParse(id);
  dbHelper.db.execute('DELETE FROM tarefas WHERE id = ?', [idInt]);
  return Response(statusCode: 204);
}
