import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String ngrokUrl =
      "https://removable-dorian-frostier.ngrok-free.dev";

  final String baseUrl = kIsWeb
      ? ngrokUrl // iPhone Web
      : (defaultTargetPlatform == TargetPlatform.android && !kReleaseMode
            ? "http://10.0.2.2:8080" // Emulador Android do PC (Modo Debug)
            : ngrokUrl);

  //salva token para não ter que logar toda hora
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        // Adicione o header abaixo, é fundamental para APIs JSON
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // CORREÇÃO AQUI: No seu backend a chave é 'usuario', não 'nome'
        await _saveToken(data['token'], data['usuario']);

        return data;
      }
      return null;
    } catch (e) {
      print("Erro no login: $e");
      return null;
    }
  }

  Future<void> _saveToken(String token, String usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('usuario', usuario);
  }

  Future<dynamic> getTarefas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse('$baseUrl/tarefas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("DADOS DA API: $data"); // Importante para debug no terminal!
        return data;
      }
      throw Exception('Falha ao carregar: ${response.statusCode}');
    } catch (e) {
      print("Erro no getTarefas: $e");
      return null;
    }
  }

  Future<bool> criarTarefas(Map<String, dynamic> novaTarefa) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.post(
        Uri.parse('$baseUrl/tarefas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(novaTarefa),
      );

      return response.statusCode == 201;
    } catch (e) {
      print("Erro ao criar tarefa: $e");
      return false;
    }
  }

  Future<List<dynamic>?> getClientes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse('$baseUrl/clientes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as List<dynamic>;
      }
      throw Exception('Falha ao carregar clientes: ${response.statusCode}');
    } catch (e) {
      print("Erro no getClientes: $e");
      return null;
    }
  }

  Future<bool> criarCliente(Map<String, dynamic> novoCliente) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.post(
        Uri.parse('$baseUrl/clientes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(novoCliente),
      );

      return response.statusCode == 201;
    } catch (e) {
      print("Erro ao criar cliente: $e");
      return false;
    }
  }

  Future<bool> atualizarCliente(int id, Map<String, dynamic> dados) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.put(
        Uri.parse('$baseUrl/clientes?id=$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(dados),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Erro ao atualizar cliente: $e");
      return false;
    }
  }

  Future<bool> deletarCliente(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.delete(
        Uri.parse('$baseUrl/clientes?id=$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Erro ao deletar cliente: $e");
      return false;
    }
  }

  Future<bool> atualizarTarefa(int id, Map<String, dynamic> dados) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.put(
        Uri.parse('$baseUrl/tarefas?id=$id'), // Passando o ID na URL
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(dados),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Erro ao atualizar tarefa: $e");
      return false;
    }
  }

  Future<bool> deletarTarefa(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.delete(
        Uri.parse('$baseUrl/tarefas?id=$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Geralmente APIs retornam 200 (OK) ou 204 (No Content) ao deletar
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Erro ao deletar tarefa: $e");
      return false;
    }
  }
}
