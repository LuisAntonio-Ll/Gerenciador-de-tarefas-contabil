import 'package:sqlite3/sqlite3.dart';
import 'dart:convert';

class DbHelper {
  late final Database _db;

  DbHelper() {
    _db = sqlite3.open('contabil.db');
    _init();
  }

  void _init() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios(
        username TEXT PRIMARY KEY,
        password TEXT,
        nome TEXT
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS tarefas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente TEXT,
        cnpj TEXT,
        tipo TEXT,
        prazo TEXT,
        status TEXT,
        observacao TEXT,
        logs TEXT,
        urgente INTEGER DEFAULT 0
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        cnpj TEXT UNIQUE
      );
    ''');

    final check = _db.select('SELECT COUNT(*) as count FROM usuarios');
    if (check.first['count'] == 0) {
      _db.execute(
          "INSERT INTO usuarios VALUES ('Nayara', '1234', 'Nayara Rodrigues')");
      _db.execute(
          "INSERT INTO usuarios VALUES ('Joao', '1029384756', 'João Pedro')");
      _db.execute(
          "INSERT INTO usuarios VALUES ('Luis', 'lajp12', 'Luís Antônio')");
      _db.execute(
          "INSERT INTO usuarios VALUES ('Islane', '1234', 'Islane Oliveira')");
    }

    final checkTarefas = _db.select('SELECT COUNT(*) as count FROM tarefas');
    if (checkTarefas.first['count'] == 0) {
      // Tarefa 1: Pendente e Urgente (Dia 15)
      _db.execute('''
      INSERT INTO tarefas (cliente, cnpj, tipo, prazo, status, observacao, logs, urgente) 
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)''', [
        'Posto Quixadá',
        '12.345.678/0001-99',
        'DAS SIMPLES',
        '2026-03-15T00:00:00',
        'pendente',
        'Observação para a tarefa 1',
        jsonEncode(['Criado pelo sistema']),
        1
      ]);

      // Tarefa 2: Em Prazo
      _db.execute('''
      INSERT INTO tarefas (cliente, cnpj, tipo, prazo, status, observacao, logs, urgente) 
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)''', [
        'Mercadinho Fortaleza',
        '98.765.432/0001-11',
        'Tirar INSS',
        '2026-04-10T00:00:00',
        'concluido',
        'Observação para a tarefa 2',
        jsonEncode(['Criado pelo sistema']),
        0
      ]);

      // Tarefa 3: Atrasada (Prazo no passado)
      _db.execute('''
      INSERT INTO tarefas (cliente, cnpj, tipo, prazo, status, observacao, logs, urgente) 
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)''', [
        'Oficina Sertão',
        '44.555.666/0001-00',
        'Folha de pagamento',
        '2026-02-20T00:00:00',
        'pendente',
        'Observação para a tarefa 3',
        jsonEncode(['Criado pelo sistema']),
        0
      ]);
    }
  }

  Database get db => _db;
}

final dbHelper = DbHelper();
