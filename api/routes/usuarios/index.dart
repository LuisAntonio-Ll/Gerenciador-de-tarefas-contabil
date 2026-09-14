import 'package:api/database/db_helper.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.get) return _handleGet();
  return Response(statusCode: 405);
}

Response _handleGet() {
  final resultados =
      dbHelper.db.select('SELECT username, nome FROM usuarios ORDER BY nome');
  final lista = resultados.map((row) {
    return {
      'username': row['username'],
      'nome': row['nome'],
    };
  }).toList();
  return Response.json(body: lista);
}
