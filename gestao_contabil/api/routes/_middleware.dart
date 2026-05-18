import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

Handler middleware(Handler handler) {
  return (context) async {
    // 1. MAPEAMENTO DE CORS (Obrigatório para o iPhone Web funcionar)
    final originHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
    };

    // Se o navegador enviar um pré-vôo (OPTIONS), responde imediatamente OK
    if (context.request.method == HttpMethod.options) {
      return Response(statusCode: 204, headers: originHeaders);
    }

    // 2. ROTAS PÚBLICAS
    if (context.request.uri.path == '/login') {
      final response = await handler(context);
      return response
          .copyWith(headers: {...response.headers, ...originHeaders});
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

      final response = await handler(userContext);
      return response
          .copyWith(headers: {...response.headers, ...originHeaders});
    } catch (e) {
      return Response.json(
          body: {'erro': 'Token inválido ou expirado'}, statusCode: 401);
    }
  };
}
