import 'dart:convert';
import 'package:api/database/db_helper.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;
  final params = context.request.uri.queryParameters;
  final cnpj = params['cnpj'];
  final idParam = params['id'];

  switch (method) {
    case HttpMethod.get:
      return _handleGet(cnpj, idParam);
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

Response _handleGet(String? cnpj, String? id) {
  if (id != null) {
    final res = dbHelper.db
        .select('SELECT * FROM pendencias WHERE id = ?', [int.tryParse(id)]);
    if (res.isEmpty) return Response(statusCode: 404);
    final row = res.first;
    return Response.json(body: {
      'id': row['id'],
      'cliente_cnpj': row['cliente_cnpj'],
      'titulo': row['titulo'],
      'descricao': row['descricao'],
      'fonte_site': row['fonte_site'],
      'tem_prazo': (row['tem_prazo'] as int) == 1,
      'prazo': row['prazo'],
      'status': row['status'],
      'criado_em': row['criado_em'],
    });
  }

  if (cnpj != null) {
    final resultados = dbHelper.db.select(
        'SELECT * FROM pendencias WHERE cliente_cnpj = ? ORDER BY criado_em DESC',
        [cnpj]);
    final lista = resultados.map((row) {
      return {
        'id': row['id'],
        'cliente_cnpj': row['cliente_cnpj'],
        'titulo': row['titulo'],
        'descricao': row['descricao'],
        'fonte_site': row['fonte_site'],
        'tem_prazo': (row['tem_prazo'] as int) == 1,
        'prazo': row['prazo'],
        'status': row['status'],
        'criado_em': row['criado_em'],
      };
    }).toList();
    return Response.json(body: lista);
  }

  final resultados =
      dbHelper.db.select('SELECT * FROM pendencias ORDER BY criado_em DESC');
  final lista = resultados.map((row) {
    return {
      'id': row['id'],
      'cliente_cnpj': row['cliente_cnpj'],
      'titulo': row['titulo'],
      'descricao': row['descricao'],
      'fonte_site': row['fonte_site'],
      'tem_prazo': (row['tem_prazo'] as int) == 1,
      'prazo': row['prazo'],
      'status': row['status'],
      'criado_em': row['criado_em'],
    };
  }).toList();
  return Response.json(body: lista);
}

Future<Response> _handlePost(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final now = DateTime.now().toIso8601String();
  dbHelper.db.execute(
    'INSERT INTO pendencias (cliente_cnpj, titulo, descricao, fonte_site, tem_prazo, prazo, status, criado_em, logs) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      body['cliente_cnpj'],
      body['titulo'],
      body['descricao'] ?? '',
      body['fonte_site'] ?? '',
      body['tem_prazo'] == true ? 1 : 0,
      body['prazo'] ?? '',
      'pendente',
      now,
      jsonEncode(['Criado em $now']),
    ],
  );
  return Response.json(
      statusCode: 201, body: {'id': dbHelper.db.lastInsertRowId});
}

Future<Response> _handlePut(RequestContext context, String? id) async {
  if (id == null) return Response(statusCode: 400);
  final idInt = int.tryParse(id);
  final body = await context.request.json() as Map<String, dynamic>;
  final res =
      dbHelper.db.select('SELECT * FROM pendencias WHERE id = ?', [idInt]);
  if (res.isEmpty) return Response(statusCode: 404);
  final row = res.first;
  dbHelper.db.execute(
    'UPDATE pendencias SET titulo = ?, descricao = ?, fonte_site = ?, tem_prazo = ?, prazo = ?, status = ? WHERE id = ?',
    [
      body['titulo'] ?? row['titulo'],
      body['descricao'] ?? row['descricao'],
      body['fonte_site'] ?? row['fonte_site'],
      body['tem_prazo'] == true
          ? 1
          : (body['tem_prazo'] == false ? 0 : row['tem_prazo']),
      body['prazo'] ?? row['prazo'],
      body['status'] ?? row['status'],
      idInt,
    ],
  );
  return Response.json(body: {'mensagem': 'Atualizado com sucesso'});
}

Response _handleDelete(String? id) {
  if (id == null) return Response(statusCode: 400);
  final idInt = int.tryParse(id);
  dbHelper.db.execute('DELETE FROM pendencias WHERE id = ?', [idInt]);
  return Response(statusCode: 204);
}
