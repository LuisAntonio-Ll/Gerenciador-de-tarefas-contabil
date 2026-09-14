import 'package:api/database/db_helper.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _handleGet();
    case HttpMethod.post:
      return _handlePost(context);
    case HttpMethod.put:
      return _handlePut(context);
    case HttpMethod.delete:
      return _handleDelete(context.request.uri.queryParameters['id']);
    default:
      return Response(statusCode: 405);
  }
}

Response _handleGet() {
  final resultados = dbHelper.db.select('SELECT * FROM clientes ORDER BY nome');
  final lista = resultados.map((row) {
    final cnpj = row['cnpj'] as String;
    final tarefasCountRes = dbHelper.db
        .select('SELECT COUNT(*) as count FROM tarefas WHERE cnpj = ?', [cnpj]);
    final tarefasCount = tarefasCountRes.first['count'] as int;
    final pendenciasCountRes = dbHelper.db.select(
        'SELECT COUNT(*) as count FROM pendencias WHERE cliente_cnpj = ?',
        [cnpj]);
    final pendenciasCount = pendenciasCountRes.first['count'] as int;

    return {
      'id': row['id'],
      'nome': row['nome'],
      'cnpj': cnpj,
      'tarefas_count': tarefasCount,
      'pendencias_count': pendenciasCount,
    };
  }).toList();
  return Response.json(body: lista);
}

Future<Response> _handlePost(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;
  dbHelper.db.execute(
    'INSERT INTO clientes (nome, cnpj) VALUES (?, ?)',
    [body['nome'], body['cnpj']],
  );
  return Response.json(
      statusCode: 201, body: {'id': dbHelper.db.lastInsertRowId});
}

Future<Response> _handlePut(RequestContext context) async {
  final idParam = context.request.uri.queryParameters['id'];
  final id = int.tryParse(idParam ?? '');
  if (id == null) return Response(statusCode: 400);

  final body = await context.request.json() as Map<String, dynamic>;
  dbHelper.db.execute(
    'UPDATE clientes SET nome = ?, cnpj = ? WHERE id = ?',
    [body['nome'], body['cnpj'], id],
  );
  return Response.json(body: {'mensagem': 'Cliente atualizado com sucesso'});
}

Response _handleDelete(String? idParam) {
  if (idParam == null) return Response(statusCode: 400);
  final id = int.tryParse(idParam);
  if (id == null) return Response(statusCode: 400);

  dbHelper.db.execute('DELETE FROM clientes WHERE id = ?', [id]);
  return Response(statusCode: 204);
}
