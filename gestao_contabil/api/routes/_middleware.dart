import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

Handler middleware(Handler handler) {
  return (context) async {
    // Permite acesso à rota de login sem autenticação
    if (context.request.uri.path == '/login') {
      return handler(context);
    }

    // Verifica o token JWT no header Authorization
    final authHeader = context.request.headers['Authorization'];

    if (authHeader == null || !authHeader.startsWith('Bearer')) {
      return Response.json(body: {'erro': 'Acesso negado'}, statusCode: 401);
    }

    final token = authHeader.substring(7);

    try {
      //verifica a validade do token
      final jwt =
          JWT.verify(token, SecretKey('sua_chave_secreta_muito_segura_123'));

      //injetar os dados do usuário no contexto para uso posterior
      final userContext = context.provide<Map<String, dynamic>>(
          () => jwt.payload as Map<String, dynamic>);

      return handler(userContext);
    } catch (e) {
      return Response.json(
          body: {'erro': 'Token inválido ou expirado'}, statusCode: 401);
    }
  };
}
