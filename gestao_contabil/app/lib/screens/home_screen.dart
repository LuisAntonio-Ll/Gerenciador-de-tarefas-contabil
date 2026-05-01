import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/api/api_service.dart';

class HomeScreen extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onNavigateToConcluidas;
  final VoidCallback onRefresh;

  const HomeScreen({
    super.key,
    required this.refreshKey,
    required this.onNavigateToConcluidas,
    required this.onRefresh,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  // Nullable para evitar LateInitializationError no IndexedStack
  Future<dynamic>? _future;

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      setState(() => _future = _apiService.getTarefas());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Inicialização lazy: só chama a API na primeira vez que o widget é renderizado
    _future ??= _apiService.getTarefas();

    return FutureBuilder<dynamic>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'Erro ao carregar dados',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      setState(() => _future = _apiService.getTarefas()),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data as Map<String, dynamic>;
        final resumo = data['resumo'] as Map<String, dynamic>;
        final tarefas = data['tarefas'] as List<dynamic>;
        final agora = DateTime.now();

        // ── Painel de Urgências: atrasadas + vencendo em até 3 dias ──────────
        final limite = agora.add(const Duration(days: 3));
        final urgentes =
            tarefas.where((t) {
              if (t['status'] == 'concluido') return false;
              final prazo = DateTime.parse(t['prazo'] as String);
              // Inclui tarefas já atrasadas E as que vencem nos próximos 3 dias
              return prazo.isBefore(limite);
            }).toList()..sort(
              (a, b) => DateTime.parse(
                a['prazo'] as String,
              ).compareTo(DateTime.parse(b['prazo'] as String)),
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(agora),
            _buildSummaryCards(resumo),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Text(
                    'ATENÇÃO NECESSÁRIA',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (urgentes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${urgentes.length}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: urgentes.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: urgentes.length,
                      itemBuilder: (context, index) =>
                          _buildTaskCard(urgentes[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ───────────────────────────── Widgets de Apoio ──────────────────────────

  Widget _buildHeader(DateTime agora) {
    final meses = [
      '',
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    final dataStr = '${agora.day} de ${meses[agora.month]}, ${agora.year}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoje,',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            dataStr,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> resumo) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 16, 0, 16),
      child: Row(
        children: [
          _statusCard(
            'Pendentes',
            resumo['pendentes'].toString(),
            const Color(0xFFFFF3E0),
            Colors.orange,
          ),
          _statusCard(
            'Atrasadas',
            resumo['atrasadas'].toString(),
            const Color(0xFFFFEBEE),
            Colors.red,
          ),
          // Card de Concluídas é um botão que abre a aba de histórico
          GestureDetector(
            onTap: widget.onNavigateToConcluidas,
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                _statusCard(
                  'Concluídas',
                  resumo['concluidas'].toString(),
                  const Color(0xFFE8F5E9),
                  Colors.green,
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(String label, String value, Color bg, Color textCol) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textCol,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textCol,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 72,
            color: Colors.green[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Tudo em dia! 🎉',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nenhuma tarefa urgente no momento.\nUse o Calendário para ver o planejamento.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(dynamic tarefa) {
    final prazo = DateTime.parse(tarefa['prazo'] as String);
    final agora = DateTime.now();
    final isAtrasada = prazo.isBefore(agora) && tarefa['status'] != 'concluido';
    final diffDias = prazo
        .difference(DateTime(agora.year, agora.month, agora.day))
        .inDays;

    Color statusColor = Colors.orange;
    String statusLabel = 'Pendente';
    if (isAtrasada) {
      statusColor = Colors.red;
      statusLabel = 'ATRASADA';
    } else if (diffDias == 0) {
      statusColor = Colors.red;
      statusLabel = 'Vence HOJE';
    } else if (diffDias == 1) {
      statusColor = Colors.deepOrange;
      statusLabel = 'Vence amanhã';
    } else {
      statusLabel = 'Em $diffDias dias';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          tarefa['cliente'] as String,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tarefa['tipo'] as String,
              style: TextStyle(
                color: const Color(0xFF4A47F5),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'CNPJ: ${tarefa['cnpj']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (tarefa['observacao'] != null &&
                (tarefa['observacao'] as String).isNotEmpty)
              Text(
                'Obs: ${tarefa['observacao']}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    '${tarefa['prazo'].toString().split('T')[0].split('-').reversed.join('/')}  •  $statusLabel',
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) {
            if (value == 'edit')
              _abrirModalDetalhes(tarefa as Map<String, dynamic>);
            if (value == 'delete') _confirmarExclusao(tarefa['id'] as int);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Modal de Edição ───────────────────────────────

  void _abrirModalDetalhes(Map<String, dynamic> tarefa) {
    final obsCtrl = TextEditingController(
      text: tarefa['observacao'] as String? ?? '',
    );
    final partes = (tarefa['prazo'] as String).split('T')[0].split('-');
    final prazoCtrl = TextEditingController(
      text: '${partes[2]}/${partes[1]}/${partes[0]}',
    );
    final prazoMask = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {'#': RegExp(r'[0-9]')},
    );
    String statusAtual = tarefa['status'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  tarefa['cliente'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'CNPJ: ${tarefa['cnpj']}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const Divider(height: 28),
                TextField(
                  controller: prazoCtrl,
                  inputFormatters: [prazoMask],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Editar Prazo',
                    hintText: 'DD/MM/AAAA',
                    prefixIcon: const Icon(Icons.calendar_month),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: statusAtual,
                  decoration: InputDecoration(
                    labelText: 'Status da Tarefa',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'pendente',
                      child: Text('Pendente'),
                    ),
                    DropdownMenuItem(
                      value: 'concluido',
                      child: Text('Concluída ✓'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setModal(() => statusAtual = v);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: obsCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Observações',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    'SALVAR ALTERAÇÕES',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    String dataFormatada = tarefa['prazo'] as String;
                    if (prazoCtrl.text.length == 10) {
                      final p = prazoCtrl.text.split('/');
                      dataFormatada = '${p[2]}-${p[1]}-${p[0]}T00:00:00';
                    }
                    final sucesso = await _apiService
                        .atualizarTarefa(tarefa['id'] as int, {
                          'status': statusAtual,
                          'observacao': obsCtrl.text,
                          'prazo': dataFormatada,
                        });
                    if (sucesso && ctx.mounted) {
                      Navigator.pop(ctx);
                      setState(() => _future = _apiService.getTarefas());
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmarExclusao(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir Tarefa?'),
        content: const Text('Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () async {
              final ok = await _apiService.deletarTarefa(id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (ok) {
                setState(() => _future = _apiService.getTarefas());
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao excluir tarefa no servidor'),
                  ),
                );
              }
            },
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
