import 'package:api/database/db_helper.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final user = body['username'] as String;
  final pass = body['password'] as String;

  final resultado = dbHelper.db.select(
    'SELECT * FROM usuarios WHERE username = ? AND password = ?',
    [user, pass],
  );

  if (resultado.isNotEmpty) {
    // Cria um payload para o JWT com as informações do usuário
    final jwt = JWT(
      {
        'username': resultado.first['username'],
        'nome': resultado.first['nome'],
      },
    );

    // Gera o token JWT usando uma chave secreta
    final token = jwt.sign(SecretKey('sua_chave_secreta_muito_segura_123'));

    return Response.json(body: {
      'status': 'sucesso',
      'token': token,
      'usuario': resultado.first['nome'],
    });
  }

  return Response.json(
    body: {'erro': 'Usuário ou senha inválidos'},
    statusCode: 401,
  );
}
