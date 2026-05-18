import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

Handler middleware(Handler handler) {
  return (context) async {
    // 1. Definição rígida dos cabeçalhos CORS (Adicionamos o cabeçalho do ngrok aqui também!)
    final corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers':
          'Origin, Content-Type, Authorization, ngrok-skip-browser-warning',
    };

    // Se for uma requisição OPTIONS (pré-vôo do navegador), responde imediatamente
    if (context.request.method == HttpMethod.options) {
      return Response(statusCode: 204, headers: corsHeaders);
    }

    // 2. Rota de Login (Pública)
    if (context.request.uri.path == '/login') {
      final response = await handler(context);
      return response.copyWith(headers: {...response.headers, ...corsHeaders});
    }

    // 3. Validação das demais rotas (Protegidas)
    final authHeader = context.request.headers['Authorization'];

    // CORREÇÃO: Caso dê erro de acesso negado, INJETA os cabeçalhos CORS para o Flutter não travar
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(
        body: {'erro': 'Acesso negado'},
        statusCode: 401,
        headers: corsHeaders, // Fundamental estar aqui!
      );
    }

    final token = authHeader.substring(7);

    try {
      final jwt =
          JWT.verify(token, SecretKey('sua_chave_secreta_muito_segura_123'));
      final userContext = context.provide<Map<String, dynamic>>(
          () => jwt.payload as Map<String, dynamic>);

      // Executa a rota com sucesso e adiciona os cabeçalhos
      final response = await handler(userContext);
      return response.copyWith(headers: {...response.headers, ...corsHeaders});
    } catch (e) {
      // CORREÇÃO: Caso o token seja inválido/expirado, também injeta o CORS
      return Response.json(
        body: {'erro': 'Token inválido ou expirado'},
        statusCode: 401,
        headers: corsHeaders, // Fundamental estar aqui!
      );
    }
  };
}
