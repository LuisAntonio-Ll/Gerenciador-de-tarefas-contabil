enum StatusDocumento { pendente, concluido, atrasado }

class TarefaContabil {
  final int id; // Agora é int
  final String clienteNome;
  final String cnpj;
  final String tipoDocumento; //dentro vai ser "tarefa"
  final DateTime prazo;
  final StatusDocumento status;
  final String? observacao; // ADICIONADO
  final List<String> logs;

  TarefaContabil({
    required this.id,
    required this.clienteNome,
    required this.cnpj,
    required this.tipoDocumento,
    required this.prazo,
    this.status = StatusDocumento.pendente,
    this.observacao,
    this.logs = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'cliente': clienteNome,
        'cnpj': cnpj,
        'tipo': tipoDocumento,
        'prazo': prazo.toIso8601String(),
        'status': status.name,
        'observacao': observacao,
        'logs': logs,
      };
}
