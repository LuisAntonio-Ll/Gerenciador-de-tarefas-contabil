import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api/api_service.dart';

class ConcluidasScreen extends StatefulWidget {
  final int refreshKey;

  const ConcluidasScreen({super.key, required this.refreshKey});

  @override
  State<ConcluidasScreen> createState() => _ConcluidasScreenState();
}

class _ConcluidasScreenState extends State<ConcluidasScreen> {
  final ApiService _apiService = ApiService();
  Future<dynamic>? _future;

  // Controle da busca
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase().trim());
    });
  }

  @override
  void didUpdateWidget(ConcluidasScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      setState(() => _future = _apiService.getTarefas());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  'Erro ao carregar',
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
        final tarefas = data['tarefas'] as List<dynamic>;

        // Filtra apenas as concluídas
        final concluidas =
            tarefas
                .where(
                  (t) => (t as Map<String, dynamic>)['status'] == 'concluido',
                )
                .cast<Map<String, dynamic>>()
                .toList()
              ..sort(
                // Mais recente (maior prazo) primeiro
                (a, b) => DateTime.parse(
                  b['prazo'] as String,
                ).compareTo(DateTime.parse(a['prazo'] as String)),
              );

        // Filtra pelo texto de busca (cliente, CNPJ ou tipo)
        final filtradas = _query.isEmpty
            ? concluidas
            : concluidas.where((t) {
                final cliente = (t['cliente'] as String).toLowerCase();
                final cnpj = (t['cnpj'] as String).toLowerCase();
                final tipo = (t['tipo'] as String).toLowerCase();
                final obs = (t['observacao'] as String? ?? '').toLowerCase();
                return cliente.contains(_query) ||
                    cnpj.contains(_query) ||
                    tipo.contains(_query) ||
                    obs.contains(_query);
              }).toList();

        return Column(
          children: [
            // ── Barra de Busca ────────────────────────────────────────────
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar por cliente, CNPJ ou serviço...',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),

            // ── Contador de resultados ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _query.isEmpty
                        ? '${concluidas.length} tarefa${concluidas.length != 1 ? 's' : ''} concluída${concluidas.length != 1 ? 's' : ''}'
                        : '${filtradas.length} resultado${filtradas.length != 1 ? 's' : ''} para "$_query"',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // ── Lista ─────────────────────────────────────────────────────
            Expanded(
              child: filtradas.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filtradas.length,
                      itemBuilder: (context, index) =>
                          _buildCard(filtradas[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ───────────────────────── Widgets de Apoio ──────────────────────────────

  Widget _buildEmpty() {
    final semBusca = _query.isEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            semBusca ? Icons.inbox_outlined : Icons.search_off_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            semBusca ? 'Nenhuma tarefa concluída ainda' : 'Nada encontrado',
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (semBusca)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 32, right: 32),
              child: Text(
                'As tarefas marcadas como concluídas aparecerão aqui.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> tarefa) {
    // Formata data: AAAA-MM-DDTHH:mm → DD/MM/AAAA
    final partes = (tarefa['prazo'] as String).split('T')[0].split('-');
    final dataFormatada = '${partes[2]}/${partes[1]}/${partes[0]}';

    // Pega o último log (histórico da ação)
    final logs = tarefa['logs'] as List<dynamic>;

    // Destaca o termo buscado no nome do cliente
    final clienteNome = tarefa['cliente'] as String;
    final tipoDoc = tarefa['tipo'] as String;
    final cnpj = tarefa['cnpj'] as String;

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
        leading: Stack(
          alignment: Alignment.topRight,
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.15),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 22,
              ),
            ),
            if (tarefa['urgente'] == true)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.priority_high,
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: _highlightText(clienteNome, _query),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tipoDoc,
              style: const TextStyle(
                color: Color(0xFF4A47F5),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 11, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Prazo: $dataFormatada',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        // ── Detalhes ao expandir ──────────────────────────────────────────
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _detalheRow(Icons.badge, 'CNPJ', cnpj),
                if (tarefa['observacao'] != null &&
                    (tarefa['observacao'] as String).isNotEmpty)
                  _detalheRow(
                    Icons.notes,
                    'Observação',
                    tarefa['observacao'] as String,
                  ),
                const SizedBox(height: 8),
                Text(
                  'HISTÓRICO',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                // Mostra todos os logs
                ...logs.map(
                  (log) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.fiber_manual_record,
                          size: 10,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            log as String,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color ??
                                  Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detalheRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color:
                  Theme.of(context).textTheme.bodySmall?.color ??
                  Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Destaca o termo buscado no texto
  Widget _highlightText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
      );
    }
    final lower = text.toLowerCase();
    final idx = lower.indexOf(query);
    if (idx < 0) {
      return Text(
        text,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
      );
    }
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
        ),
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: TextStyle(
              backgroundColor: const Color(0xFFFFEB3B),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black87
                  : Colors.black,
            ),
          ),
          TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }
}
