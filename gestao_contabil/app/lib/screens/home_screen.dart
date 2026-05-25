import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/api/api_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onTasksChanged;

  const HomeScreen({super.key, this.onTasksChanged});

  @override
  // Estado PÚBLICO para o GlobalKey do MainScreen chamar refreshData()
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  Future<dynamic>? _future;

  // ── Cache do último dado carregado com sucesso ───────────────────────────
  // Evita tela branca durante o reload: enquanto a nova request está em
  // andamento, continuamos exibindo o dado anterior.
  Map<String, dynamic>? _cachedData;

  // Controla qual painel está visível: pendentes ou concluídas
  bool _showingConcluidas = false;

  // Busca na seção de concluídas
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () =>
          setState(() => _searchQuery = _searchCtrl.text.toLowerCase().trim()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Chamado pelo MainScreen via GlobalKey após criar tarefa,
  // e internamente após editar/excluir.
  void refreshData() {
    if (!mounted) return;
    setState(() => _future = _fetchAndCache());
    // Notifica o pai (MainScreen) para que telas como o Calendário
    // possam recarregar seus dados.
    widget.onTasksChanged?.call();
  }

  Future<dynamic> _fetchAndCache() async {
    final result = await _apiService.getTarefas();
    if (result != null && mounted) {
      // Atualiza o cache assim que os dados chegam, antes do build
      setState(() => _cachedData = result as Map<String, dynamic>);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Lazy init na primeira renderização
    _future ??= _fetchAndCache();

    return FutureBuilder<dynamic>(
      future: _future,
      builder: (context, snapshot) {
        // Usa dado em cache se ainda estiver carregando (evita tela branca)
        final data = (snapshot.data as Map<String, dynamic>?) ?? _cachedData;

        // Primeira carga: sem cache ainda
        if (data == null) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
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
                  onPressed: refreshData,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        final resumo = data['resumo'] as Map<String, dynamic>;
        final tarefas = data['tarefas'] as List<dynamic>;

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSummaryCards(resumo),
                if (_showingConcluidas)
                  _buildConcluidasSection(tarefas)
                else
                  _buildPendentesSection(tarefas),
              ],
            ),
            // Indicador sutil de atualização em andamento (sem bloquear a tela)
            if (snapshot.connectionState == ConnectionState.waiting &&
                _cachedData != null)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: Color(0xFF4A47F5),
                  minHeight: 2,
                ),
              ),
          ],
        );
      },
    );
  }

  // ─────────────────────────── Cabeçalho ───────────────────────────────────

  Widget _buildHeader() {
    final agora = DateTime.now();
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoje,',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${agora.day} de ${meses[agora.month]}, ${agora.year}',
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          if (_showingConcluidas)
            TextButton.icon(
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _showingConcluidas = false);
              },
              icon: const Icon(Icons.arrow_back_ios, size: 14),
              label: const Text('Pendentes'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4A47F5),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────── Cards de Resumo ─────────────────────────────

  Widget _buildSummaryCards(Map<String, dynamic> resumo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 14, 0, 14),
      child: Row(
        children: [
          _statusCard(
            'Pendentes',
            resumo['pendentes'].toString(),
            isDark ? Colors.orange.withOpacity(0.2) : const Color(0xFFFFF3E0),
            Colors.orange,
          ),
          _statusCard(
            'Atrasadas',
            resumo['atrasadas'].toString(),
            isDark ? Colors.red.withOpacity(0.2) : const Color(0xFFFFEBEE),
            Colors.red,
          ),
          // Card de concluídas → abre o histórico inline
          GestureDetector(
            onTap: () {
              _searchCtrl.clear();
              setState(() => _showingConcluidas = !_showingConcluidas);
            },
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                _statusCard(
                  'Concluídas',
                  resumo['concluidas'].toString(),
                  _showingConcluidas
                      ? (isDark
                            ? Colors.green.withOpacity(0.3)
                            : Colors.green.withOpacity(0.25))
                      : (isDark
                            ? Colors.green.withOpacity(0.2)
                            : const Color(0xFFE8F5E9)),
                  Colors.green,
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    _showingConcluidas
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 14,
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
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
              fontSize: 10,
              color: textCol,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Painel de Pendentes ─────────────────────────

  Widget _buildPendentesSection(List<dynamic> tarefas) {
    final pendentes =
        tarefas
            .where((t) {
              final m = t as Map<String, dynamic>;
              return m['status'] != 'concluido';
            })
            .cast<Map<String, dynamic>>()
            .toList()
          ..sort(
            (a, b) => DateTime.parse(
              a['prazo'] as String,
            ).compareTo(DateTime.parse(b['prazo'] as String)),
          );

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Text(
                  'TAREFAS PENDENTES',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.black87,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                if (pendentes.isNotEmpty)
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
                      '${pendentes.length}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: pendentes.isEmpty
                ? _buildEmptyPendentes()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pendentes.length,
                    itemBuilder: (ctx, i) => _buildTaskCard(pendentes[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPendentes() {
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
            'Nenhuma tarefa pendente no momento.\nVeja o planejamento no Calendário.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Seção de Concluídas ─────────────────────────

  Widget _buildConcluidasSection(List<dynamic> tarefas) {
    final concluidas =
        tarefas
            .where((t) => (t as Map<String, dynamic>)['status'] == 'concluido')
            .cast<Map<String, dynamic>>()
            .toList()
          ..sort(
            (a, b) => DateTime.parse(
              b['prazo'] as String,
            ).compareTo(DateTime.parse(a['prazo'] as String)),
          );

    final filtradas = _searchQuery.isEmpty
        ? concluidas
        : concluidas.where((t) {
            final q = _searchQuery;
            return (t['cliente'] as String).toLowerCase().contains(q) ||
                (t['cnpj'] as String).toLowerCase().contains(q) ||
                (t['tipo'] as String).toLowerCase().contains(q) ||
                (t['observacao'] as String? ?? '').toLowerCase().contains(q);
          }).toList();

    return Expanded(
      child: Column(
        children: [
          // Barra de busca
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar concluídas...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _searchCtrl.clear,
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF0F0F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // Contador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Row(
              children: [
                Icon(Icons.history_rounded, size: 14, color: Colors.green[600]),
                const SizedBox(width: 6),
                Text(
                  _searchQuery.isEmpty
                      ? '${concluidas.length} tarefa(s) concluída(s)'
                      : '${filtradas.length} resultado(s)',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtradas.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'Nenhuma tarefa concluída ainda.'
                          : 'Nada encontrado.',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtradas.length,
                    itemBuilder: (ctx, i) => _buildConcluidaCard(filtradas[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcluidaCard(Map<String, dynamic> tarefa) {
    final partes = (tarefa['prazo'] as String).split('T')[0].split('-');
    final dataFormatada = '${partes[2]}/${partes[1]}/${partes[0]}';
    final logs = tarefa['logs'] as List<dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: Colors.green, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text(
          tarefa['cliente'] as String,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tarefa['tipo'] as String,
              style: const TextStyle(
                color: Color(0xFF4A47F5),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            Text(
              'Prazo: $dataFormatada',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Text(
                  'CNPJ: ${tarefa['cnpj']}',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Theme.of(context).textTheme.bodySmall?.color ??
                        Colors.black54,
                  ),
                ),
                if (tarefa['observacao'] != null &&
                    (tarefa['observacao'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Obs: ${tarefa['observacao']}',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).textTheme.bodySmall?.color ??
                            Colors.black54,
                      ),
                    ),
                  ),
                if (logs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'HISTÓRICO',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...logs.map(
                    (log) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        log as String,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              Theme.of(context).textTheme.bodySmall?.color ??
                              Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Card de Tarefa Urgente ──────────────────────

  Widget _buildTaskCard(Map<String, dynamic> tarefa) {
    final prazo = DateTime.parse(tarefa['prazo'] as String);
    final agora = DateTime.now();
    final isAtrasada = prazo.isBefore(agora) && tarefa['status'] != 'concluido';
    final diffDias = prazo
        .difference(DateTime(agora.year, agora.month, agora.day))
        .inDays;

    Color cor;
    String etiqueta;
    if (isAtrasada) {
      cor = Colors.red;
      etiqueta = 'ATRASADA';
    } else if (diffDias == 0) {
      cor = Colors.red;
      etiqueta = 'Vence HOJE';
    } else if (diffDias == 1) {
      cor = Colors.deepOrange;
      etiqueta = 'Vence amanhã';
    } else {
      cor = Colors.orange;
      etiqueta = 'Em $diffDias dias';
    }

    final prazoStr = (tarefa['prazo'] as String)
        .split('T')[0]
        .split('-')
        .reversed
        .join('/');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border(left: BorderSide(color: cor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                tarefa['cliente'] as String,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            if (tarefa['urgente'] == true)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.warning_rounded, color: Colors.red, size: 20),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tarefa['tipo'] as String,
              style: const TextStyle(
                color: Color(0xFF4A47F5),
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
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).textTheme.bodySmall?.color ??
                      Colors.black54,
                ),
              ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$prazoStr  •  $etiqueta',
                style: TextStyle(
                  fontSize: 11,
                  color: cor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (v) {
            if (v == 'edit') _abrirModalDetalhes(tarefa);
            if (v == 'delete') _confirmarExclusao(tarefa['id'] as int);
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem(
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

  // ─────────────────────────── Modal de Edição ─────────────────────────────

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
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (modalCtx, setModal) {
          bool isUrgente = tarefa['urgente'] == true;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
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
                    onChanged: (value) =>
                        setModal(() => isUrgente = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      disabledBackgroundColor: Colors.black38,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            String dataFormatada = tarefa['prazo'] as String;
                            if (prazoCtrl.text.length == 10) {
                              final p = prazoCtrl.text.split('/');
                              dataFormatada =
                                  '${p[2]}-${p[1]}-${p[0]}T00:00:00';
                            }

                            setModal(() => isSaving = true);

                            final ok = await _apiService
                                .atualizarTarefa(tarefa['id'] as int, {
                                  'status': statusAtual,
                                  'observacao': obsCtrl.text,
                                  'prazo': dataFormatada,
                                  'urgente': isUrgente,
                                });

                            if (ok) {
                              // ── CORREÇÃO DO REFRESH ───────────────────────
                              // Fecha o modal usando o Navigator do contexto
                              // principal (sempre montado). O context aqui se
                              // refere ao _HomeScreenState — não ao modalCtx.
                              Navigator.of(context).pop();

                              // refreshData() verifica mounted internamente
                              // e agenda o rebuild sem depender do modalCtx
                              refreshData();
                            } else {
                              setModal(() => isSaving = false);
                              if (modalCtx.mounted) {
                                ScaffoldMessenger.of(modalCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Erro ao salvar. Tente novamente.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      isSaving ? 'SALVANDO...' : 'SALVAR ALTERAÇÕES',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

  // ─────────────────────────── Diálogo de Exclusão ─────────────────────────

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
              Navigator.pop(ctx);
              final ok = await _apiService.deletarTarefa(id);
              if (ok) refreshData();
            },
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
