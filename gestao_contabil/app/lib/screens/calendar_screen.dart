import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DEPENDÊNCIA: Adicione ao pubspec.yaml:
//   table_calendar: ^3.1.2
// E rode: flutter pub get
//
// Para suporte à localização em pt_BR, adicione ao main.dart:
//   import 'package:flutter_localizations/flutter_localizations.dart';
//   MaterialApp(
//     localizationsDelegates: GlobalMaterialLocalizations.delegates,
//     supportedLocales: [Locale('pt', 'BR')],
//     ...
//   )
// ─────────────────────────────────────────────────────────────────────────────

class CalendarScreen extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onRefresh;

  const CalendarScreen({
    super.key,
    required this.refreshKey,
    required this.onRefresh,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ApiService _apiService = ApiService();
  Future<dynamic>? _future;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // Mapa de data normalizada (sem hora) → lista de tarefas
  Map<DateTime, List<Map<String, dynamic>>> _eventMap = {};

  @override
  void didUpdateWidget(CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      setState(() => _future = _loadTasks());
    }
  }

  Future<dynamic> _loadTasks() async {
    final data = await _apiService.getTarefas();
    if (data != null) {
      _buildEventMap(data['tarefas'] as List<dynamic>);
    }
    return data;
  }

  void _buildEventMap(List<dynamic> tarefas) {
    final map = <DateTime, List<Map<String, dynamic>>>{};
    for (final t in tarefas) {
      final tarefa = t as Map<String, dynamic>;
      final prazo = DateTime.parse(tarefa['prazo'] as String);
      final key = _normalizeDate(prazo);
      map.putIfAbsent(key, () => []).add(tarefa);
    }
    _eventMap = map;
  }

  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Map<String, dynamic>> _eventsForDay(DateTime day) =>
      _eventMap[_normalizeDate(day)] ?? [];

  List<Map<String, dynamic>> get _selectedEvents => _eventsForDay(_selectedDay);

  // Determina a "pior" cor para um conjunto de tarefas do dia
  Color _dotColor(List<Map<String, dynamic>> tasks) {
    final agora = DateTime.now();
    Color cor = Colors.green;
    for (final t in tasks) {
      final prazo = DateTime.parse(t['prazo'] as String);
      if (t['status'] != 'concluido' && prazo.isBefore(agora)) {
        return Colors.red; // pior caso → para imediatamente
      }
      if (t['status'] == 'pendente') cor = Colors.orange;
    }
    return cor;
  }

  @override
  Widget build(BuildContext context) {
    _future ??= _loadTasks();

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
                  'Erro ao carregar',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => setState(() => _future = _loadTasks()),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // ── Calendário ────────────────────────────────────────────────
            Container(
              color: Theme.of(context).cardColor,
              child: TableCalendar<Map<String, dynamic>>(
                locale: 'pt_BR',
                firstDay: DateTime.utc(2025, 1, 1),
                lastDay: DateTime.utc(2028, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                eventLoader: _eventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Mês',
                  CalendarFormat.twoWeeks: '2 Sem.',
                  CalendarFormat.week: 'Semana',
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFF4A47F5).withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xFF4A47F5),
                    shape: BoxShape.circle,
                  ),
                  markerSize: 0, // desativamos o marcador padrão
                ),
                headerStyle: HeaderStyle(
                  formatButtonDecoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF4A47F5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  formatButtonTextStyle: const TextStyle(
                    color: Color(0xFF4A47F5),
                  ),
                  titleCentered: true,
                  titleTextStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  leftChevronIcon: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF4A47F5),
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF4A47F5),
                  ),
                ),
                // ── Marcadores customizados (pontinho colorido) ───────────
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return const SizedBox.shrink();
                    final cor = _dotColor(events);
                    return Positioned(
                      bottom: 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cor,
                            ),
                          ),
                          // Segundo ponto se houver múltiplas tarefas
                          if (events.length > 1) ...[
                            const SizedBox(width: 2),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cor.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) {
                  _focusedDay = focused;
                },
              ),
            ),

            // ── Divider com legenda dos pontos ────────────────────────────
            Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(
                children: [
                  _legendaDot(Colors.red, 'Atrasada'),
                  const SizedBox(width: 16),
                  _legendaDot(Colors.orange, 'Pendente'),
                  const SizedBox(width: 16),
                  _legendaDot(Colors.green, 'Concluída'),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Cabeçalho do dia selecionado ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    _formatarDia(_selectedDay),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_selectedEvents.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A47F5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_selectedEvents.length} tarefa${_selectedEvents.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4A47F5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Lista de tarefas do dia ───────────────────────────────────
            Expanded(
              child: _selectedEvents.isEmpty
                  ? _buildEmptyDay()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _selectedEvents.length,
                      itemBuilder: (context, i) =>
                          _buildTaskCard(_selectedEvents[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ───────────────────────── Widgets de Apoio ──────────────────────────────

  Widget _legendaDot(Color cor, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: cor),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color:
                Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54,
          ),
        ),
      ],
    );
  }

  String _formatarDia(DateTime d) {
    final semana = [
      '',
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];
    final meses = [
      '',
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    final diaSemana = semana[d.weekday];
    return '$diaSemana, ${d.day} de ${meses[d.month]}';
  }

  Widget _buildEmptyDay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 56,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhuma tarefa neste dia',
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> tarefa) {
    final prazo = DateTime.parse(tarefa['prazo'] as String);
    final agora = DateTime.now();
    final isAtrasada = prazo.isBefore(agora) && tarefa['status'] != 'concluido';
    final isConcluida = tarefa['status'] == 'concluido';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color borderColor = Colors.orange;
    if (isConcluida) borderColor = Colors.green;
    if (isAtrasada) borderColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                tarefa['cliente'] as String,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            if (tarefa['urgente'] == true)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.warning_rounded, color: Colors.red, size: 18),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tarefa['tipo'] as String,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'CNPJ: ${tarefa['cnpj']}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            if (isAtrasada)
              Text(
                'ATRASADA',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
          onSelected: (v) {
            if (v == 'edit') _abrirModalDetalhes(tarefa);
            if (v == 'delete') _confirmarExclusao(tarefa['id'] as int);
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

  // ───────────────────── Modal de Edição (igual ao Home) ───────────────────

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
    bool isUrgente = tarefa['urgente'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return Padding(
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
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
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
                      labelText: 'Status',
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
                  const SizedBox(height: 14),
                  CheckboxListTile(
                    title: Text(
                      'Marcar como Urgente',
                      style: GoogleFonts.poppins(),
                    ),
                    value: isUrgente,
                    onChanged: (value) {
                      setModal(() => isUrgente = value ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
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
                      final ok = await _apiService
                          .atualizarTarefa(tarefa['id'] as int, {
                            'status': statusAtual,
                            'observacao': obsCtrl.text,
                            'prazo': dataFormatada,
                            'urgente': isUrgente,
                          });
                      if (ok && ctx.mounted) {
                        Navigator.pop(ctx);
                        setState(() => _future = _loadTasks());
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
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
              if (ok) setState(() => _future = _loadTasks());
            },
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
