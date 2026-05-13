import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/api/api_service.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FB),
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
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: ListTile(
                                title: Text(
                                  cliente['nome'] as String,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  cliente['cnpj'] as String,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[700],
                                  ),
                                ),
                                trailing: PopupMenuButton<String>(
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
