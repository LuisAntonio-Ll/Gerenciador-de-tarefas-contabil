import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/api/api_service.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  ClientesScreenState createState() => ClientesScreenState();
}

class ClientesScreenState extends State<ClientesScreen> {
  final ApiService _apiService = ApiService();
  final _searchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _clientes = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadClientes();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void refreshData() {
    if (!mounted) return;
    _refresh();
  }

  Future<void> _loadClientes() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final data = await _apiService.getClientes();
    if (data != null) {
      setState(() {
        _clientes
          ..clear()
          ..addAll(data.cast<Map<String, dynamic>>());
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _refresh() {
    _loadClientes();
  }

  void _abrirCadastroCliente([Map<String, dynamic>? cliente]) {
    final nomeCtrl = TextEditingController(
      text: cliente?['nome'] as String? ?? '',
    );
    final cnpjCtrl = TextEditingController(
      text: cliente?['cnpj'] as String? ?? '',
    );
    final cnpjMask = MaskTextInputFormatter(
      mask: '##.###.###/####-##',
      filter: {'#': RegExp(r'[0-9]')},
    );
    final isEditing = cliente != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (modalCtx) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (modalCtx, setModal) => Padding(
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
                    isEditing ? 'Editar Cliente' : 'Cadastro de Cliente',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nomeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nome do cliente',
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cnpjCtrl,
                    inputFormatters: [cnpjMask],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'CNPJ',
                      hintText: '00.000.000/0001-00',
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A47F5),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final nome = nomeCtrl.text.trim();
                            final cnpj = cnpjCtrl.text.trim();

                            if (nome.isEmpty || cnpj.isEmpty) {
                              ScaffoldMessenger.of(modalCtx).showSnackBar(
                                const SnackBar(
                                  content: Text('Preencha nome e CNPJ.'),
                                ),
                              );
                              return;
                            }

                            setModal(() => isSaving = true);
                            final sucesso = isEditing
                                ? await _apiService.atualizarCliente(
                                    cliente['id'] as int,
                                    {'nome': nome, 'cnpj': cnpj},
                                  )
                                : await _apiService.criarCliente({
                                    'nome': nome,
                                    'cnpj': cnpj,
                                  });

                            if (sucesso) {
                              Navigator.of(context).pop();
                              _refresh();
                            } else {
                              setModal(() => isSaving = false);
                              ScaffoldMessenger.of(modalCtx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEditing
                                        ? 'Erro ao atualizar cliente.'
                                        : 'Erro ao cadastrar cliente.',
                                  ),
                                ),
                              );
                            }
                          },
                    child: Text(
                      isSaving
                          ? 'SALVANDO...'
                          : isEditing
                          ? 'ATUALIZAR CLIENTE'
                          : 'CADASTRAR CLIENTE',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmarExcluirCliente(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir cliente'),
        content: const Text('Tem certeza que deseja excluir este cliente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final sucesso = await _apiService.deletarCliente(id);
              if (sucesso) {
                _refresh();
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erro ao excluir cliente.')),
                  );
                }
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _abrirPendencias(String cnpj, String nomeEmpresa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        final tituloCtrl = TextEditingController();
        final descricaoCtrl = TextEditingController();
        final fonteCtrl = TextEditingController();
        final prazoCtrl = TextEditingController();
        final prazoMask = MaskTextInputFormatter(
          mask: '##/##/####',
          filter: {'#': RegExp(r'[0-9]')},
        );
        bool temPrazo = false;
        Future<List<dynamic>?>? pendenciasFuture;

        Future<List<dynamic>?> carregar() async {
          return await _apiService.getPendencias(cnpj: cnpj);
        }

        return StatefulBuilder(
          builder: (ctx, setModal) {
            pendenciasFuture ??= carregar();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
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
                    'Pendências — $nomeEmpresa',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<dynamic>?>(
                    future: pendenciasFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final list = snapshot.data ?? [];
                      if (list.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Nenhuma pendência registrada para esta empresa.',
                            style: GoogleFonts.poppins(),
                          ),
                        );
                      }
                      return Flexible(
                        child: SizedBox(
                          height: 340,
                          child: ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (context, i) {
                              final p = list[i] as Map<String, dynamic>;
                              return _buildPendenciaCard(
                                p,
                                onEdit: () async {
                                  final atualizada = await _editarPendencia(p);
                                  if (atualizada && ctx.mounted) {
                                    setModal(
                                      () => pendenciasFuture = carregar(),
                                    );
                                  }
                                },
                                onConclude: () async {
                                  final concluida = await _concluirPendencia(
                                    p['id'] as int,
                                  );
                                  if (concluida && ctx.mounted) {
                                    setModal(
                                      () => pendenciasFuture = carregar(),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Registrar nova pendência',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: tituloCtrl,
                    decoration: InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descricaoCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: fonteCtrl,
                    decoration: InputDecoration(
                      labelText: 'Fonte / Site',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: temPrazo,
                        onChanged: (v) => setModal(() => temPrazo = v ?? false),
                      ),
                      const SizedBox(width: 8),
                      Text('Possui prazo para regularização?'),
                    ],
                  ),
                  if (temPrazo) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: prazoCtrl,
                      inputFormatters: [prazoMask],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Prazo (DD/MM/AAAA)',
                        hintText: 'DD/MM/AAAA',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A47F5),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    onPressed: () async {
                      final titulo = tituloCtrl.text.trim();
                      if (titulo.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Preencha o título.')),
                        );
                        return;
                      }
                      final prazo = temPrazo
                          ? _converterPrazoParaApi(prazoCtrl.text)
                          : null;
                      if (temPrazo && prazo == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Informe um prazo válido (DD/MM/AAAA).',
                            ),
                          ),
                        );
                        return;
                      }
                      final payload = {
                        'cliente_cnpj': cnpj,
                        'titulo': titulo,
                        'descricao': descricaoCtrl.text.trim(),
                        'fonte_site': fonteCtrl.text.trim(),
                        'tem_prazo': temPrazo,
                        'prazo': prazo,
                      };
                      final ok = await _apiService.criarPendencia(payload);
                      if (ok) {
                        // refresh clientes list and modal content
                        _loadClientes();
                        setModal(() => pendenciasFuture = carregar());
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Erro ao criar pendência.'),
                          ),
                        );
                      }
                    },
                    child: const Text('Registrar pendência'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatarPrazoParaExibicao(String? prazo) {
    if (prazo == null || prazo.isEmpty) return 'Não informado';
    final data = DateTime.tryParse(prazo);
    if (data == null) return prazo;
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  String? _converterPrazoParaApi(String prazo) {
    final partes = prazo.split('/');
    if (partes.length != 3 || partes.any((parte) => parte.isEmpty)) {
      return null;
    }

    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);
    if (dia == null || mes == null || ano == null || ano < 1900) return null;

    final data = DateTime(ano, mes, dia);
    if (data.year != ano || data.month != mes || data.day != dia) return null;
    return '${data.year.toString().padLeft(4, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';
  }

  Widget _buildPendenciaCard(
    Map<String, dynamic> pendencia, {
    required VoidCallback onEdit,
    required VoidCallback onConclude,
  }) {
    final concluida = pendencia['status'] == 'concluido';
    final descricao = (pendencia['descricao'] as String?)?.trim();
    final fonte = (pendencia['fonte_site'] as String?)?.trim();
    final prazo = pendencia['tem_prazo'] == true
        ? _formatarPrazoParaExibicao(pendencia['prazo'] as String?)
        : 'Sem prazo';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    pendencia['titulo'] as String,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                _statusChip(concluida),
              ],
            ),
            const SizedBox(height: 8),
            _pendenciaInfo(
              Icons.description_outlined,
              'Descrição',
              descricao?.isNotEmpty == true ? descricao! : 'Não informada',
            ),
            const SizedBox(height: 5),
            _pendenciaInfo(
              Icons.language,
              'Fonte / site',
              fonte?.isNotEmpty == true ? fonte! : 'Não informada',
            ),
            const SizedBox(height: 5),
            _pendenciaInfo(Icons.event_outlined, 'Prazo', prazo),
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!concluida)
                  TextButton.icon(
                    onPressed: onConclude,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Concluir'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green[700],
                    ),
                  ),
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Editar pendência',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendenciaInfo(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 7),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(bool concluida) {
    final color = concluida ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        concluida ? 'Concluída' : 'Pendente',
        style: TextStyle(
          color: color[700],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<bool> _editarPendencia(Map<String, dynamic> pendencia) async {
    final tituloCtrl = TextEditingController(
      text: pendencia['titulo'] as String? ?? '',
    );
    final descricaoCtrl = TextEditingController(
      text: pendencia['descricao'] as String? ?? '',
    );
    final fonteCtrl = TextEditingController(
      text: pendencia['fonte_site'] as String? ?? '',
    );
    final prazoCtrl = TextEditingController(
      text: _formatarPrazoParaEdicao(pendencia['prazo'] as String?),
    );
    final prazoMask = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {'#': RegExp(r'[0-9]')},
    );
    bool temPrazo = pendencia['tem_prazo'] == true;

    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (modalCtx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (modalCtx, setModal) => Padding(
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
                  Text(
                    'Editar pendência',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _pendenciaField(tituloCtrl, 'Título'),
                  const SizedBox(height: 10),
                  _pendenciaField(descricaoCtrl, 'Descrição', maxLines: 3),
                  const SizedBox(height: 10),
                  _pendenciaField(fonteCtrl, 'Fonte / Site'),
                  const SizedBox(height: 4),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: temPrazo,
                    title: const Text('Possui prazo'),
                    onChanged: (value) =>
                        setModal(() => temPrazo = value ?? false),
                  ),
                  if (temPrazo) ...[
                    const SizedBox(height: 4),
                    _pendenciaField(
                      prazoCtrl,
                      'Prazo (DD/MM/AAAA)',
                      inputFormatters: [prazoMask],
                      keyboardType: TextInputType.number,
                      hintText: 'DD/MM/AAAA',
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (tituloCtrl.text.trim().isEmpty) return;
                            final prazo = temPrazo
                                ? _converterPrazoParaApi(prazoCtrl.text)
                                : null;
                            if (temPrazo && prazo == null) {
                              ScaffoldMessenger.of(modalCtx).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Informe um prazo válido (DD/MM/AAAA).',
                                  ),
                                ),
                              );
                              return;
                            }
                            setModal(() => isSaving = true);
                            final ok = await _apiService
                                .atualizarPendencia(pendencia['id'] as int, {
                                  'titulo': tituloCtrl.text.trim(),
                                  'descricao': descricaoCtrl.text.trim(),
                                  'fonte_site': fonteCtrl.text.trim(),
                                  'tem_prazo': temPrazo,
                                  'prazo': prazo,
                                });
                            if (ok && modalCtx.mounted) {
                              Navigator.of(modalCtx).pop(true);
                            } else if (modalCtx.mounted) {
                              setModal(() => isSaving = false);
                              ScaffoldMessenger.of(modalCtx).showSnackBar(
                                const SnackBar(
                                  content: Text('Erro ao atualizar pendência.'),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A47F5),
                      minimumSize: const Size(double.infinity, 46),
                    ),
                    child: Text(
                      isSaving ? 'SALVANDO...' : 'SALVAR ALTERAÇÕES',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );

    tituloCtrl.dispose();
    descricaoCtrl.dispose();
    fonteCtrl.dispose();
    prazoCtrl.dispose();
    return resultado == true;
  }

  TextField _pendenciaField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatarPrazoParaEdicao(String? prazo) {
    if (prazo == null || prazo.isEmpty) return '';
    return _formatarPrazoParaExibicao(prazo) == 'Não informado'
        ? prazo
        : _formatarPrazoParaExibicao(prazo);
  }

  Future<bool> _concluirPendencia(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Concluir pendência?'),
        content: const Text('Ela será concluída e removida da lista.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return false;
    final ok = await _apiService.deletarPendencia(id);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao remover pendência concluída.')),
      );
    }
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clientes',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Registre e selecione CNPJs para novas tarefas.',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _abrirCadastroCliente,
                  icon: const Icon(Icons.add),
                  label: const Text('Novo'),
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(color: Colors.white),
                    backgroundColor: const Color(0xFF4A47F5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: 'Buscar cliente ou CNPJ',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? Center(
                    child: Text(
                      'Não foi possível carregar os clientes.',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final clientes = _clientes.where((cliente) {
                        final nome = (cliente['nome'] as String).toLowerCase();
                        final cnpj = (cliente['cnpj'] as String).toLowerCase();
                        return nome.contains(_query) || cnpj.contains(_query);
                      }).toList();

                      if (clientes.isEmpty) {
                        return Center(
                          child: Text(
                            _query.isEmpty
                                ? 'Nenhum cliente encontrado.'
                                : 'Nenhum cliente corresponde à busca.',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async => _refresh(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: clientes.length,
                          itemBuilder: (context, index) {
                            final cliente = clientes[index];
                            final isDark =
                                Theme.of(context).brightness == Brightness.dark;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      isDark ? 0.3 : 0.04,
                                    ),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: ListTile(
                                title: Text(
                                  cliente['nome'] as String,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cliente['cnpj'] as String,
                                      style: GoogleFonts.poppins(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.work_outline,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${cliente['tarefas_count'] ?? 0} tarefas',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.report_problem_outlined,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${cliente['pendencias_count'] ?? 0} pendências',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _abrirPendencias(
                                        cliente['cnpj'] as String,
                                        cliente['nome'] as String,
                                      ),
                                      tooltip: 'Criar pendências',
                                      icon: const Icon(
                                        Icons.assignment_late_outlined,
                                        color: Color(0xFF4A47F5),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _abrirCadastroCliente(cliente);
                                        } else if (value == 'delete') {
                                          _confirmarExcluirCliente(
                                            cliente['id'] as int,
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Editar'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Excluir'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
