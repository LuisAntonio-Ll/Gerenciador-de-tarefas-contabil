import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api/api_service.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'clientes_screen.dart';
import 'settings_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Altere a rota '/home' no main.dart:
//   '/home': (context) => const MainScreen(),
// ─────────────────────────────────────────────────────────────────────────────

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final ApiService _apiService = ApiService();
  String _usuario = '';
  int _calendarRefreshKey = 0;
  final ValueNotifier<int> _calendarNotifier = ValueNotifier<int>(0);

  // GlobalKey para chamar refreshData() diretamente no HomeScreen
  // sem precisar fazer setState no MainScreen inteiro
  final _homeKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final usuario = prefs.getString('usuario') ?? '';
    if (mounted) {
      setState(() => _usuario = usuario);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('usuario');
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente encerrar a sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  static const _titles = [
    'Gestão - NR',
    'Gestão - NR',
    'Gestão - NR',
    'Configurações',
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        title: Text(
          _titles[_currentIndex],
          style: GoogleFonts.poppins(
            color: const Color(0xFF4A47F5),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue[100],
                child: Icon(Icons.person, color: Colors.blue[900], size: 20),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _confirmLogout();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'user',
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 18),
                    const SizedBox(width: 8),
                    Text(_usuario.isNotEmpty ? _usuario : 'Usuário'),
                  ],
                ),
                enabled: false,
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sair', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            key: _homeKey,
            onTasksChanged: () => setState(() => _calendarRefreshKey++),
          ),
          CalendarScreen(
            refreshKey: _calendarRefreshKey,
            onRefresh: () {
              _homeKey.currentState?.refreshData();
              setState(() => _calendarRefreshKey++);
            },
          ),
          const ClientesScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 3
          ? null
          : FloatingActionButton(
              onPressed: _abrirModalCadastro,
              backgroundColor: const Color(0xFF4A47F5),
              child: const Icon(Icons.add, color: Colors.white),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // ─────────────────────────── Bottom Navigation ────────────────────────────

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.dashboard_rounded, 0),
            _navItem(Icons.calendar_month_rounded, 1),
            const SizedBox(width: 40), // espaço do FAB
            _navItem(Icons.people_rounded, 2),
            _navItem(Icons.settings_rounded, 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    final bool active = _currentIndex == index;
    return IconButton(
      icon: Icon(icon, color: active ? const Color(0xFF4A47F5) : Colors.grey),
      onPressed: index >= 0
          ? () => setState(() => _currentIndex = index)
          : null,
    );
  }

  // ─────────────────────────── Modal de Cadastro ────────────────────────────

  void _abrirModalCadastro() {
    final clienteCtrl = TextEditingController();
    final cnpjCtrl = TextEditingController();
    final tipoCtrl = TextEditingController();
    final prazoCtrl = TextEditingController();
    final obsCtrl = TextEditingController();

    final cnpjMask = MaskTextInputFormatter(
      mask: '##.###.###/####-##',
      filter: {'#': RegExp(r'[0-9]')},
    );
    final prazoMask = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {'#': RegExp(r'[0-9]')},
    );

    final clientesFuture = _apiService.getClientes();
    Map<String, dynamic>? selectedCliente;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (modalCtx) {
        bool isSaving = false;
        bool isUrgente = false;

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
                children: [
                  _dragHandle(),
                  Text(
                    'Nova Tarefa',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<dynamic>?>(
                    future: clientesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LinearProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError || snapshot.data == null) {
                        return const SizedBox.shrink();
                      }

                      final clientes = snapshot.data!
                          .cast<Map<String, dynamic>>()
                          .toList();

                      return Column(
                        children: [
                          DropdownButtonFormField<Map<String, dynamic>>(
                            decoration: InputDecoration(
                              labelText: 'Selecionar cliente existente',
                              prefixIcon: const Icon(Icons.person_search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            value: selectedCliente,
                            items: clientes.map((cliente) {
                              return DropdownMenuItem(
                                value: cliente,
                                child: Text(cliente['nome'] as String),
                              );
                            }).toList(),
                            onChanged: (cliente) {
                              setModal(() {
                                selectedCliente = cliente;
                                if (cliente != null) {
                                  clienteCtrl.text = cliente['nome'] as String;
                                  cnpjCtrl.text = cliente['cnpj'] as String;
                                }
                              });
                            },
                          ),
                          if (selectedCliente != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    setModal(() {
                                      selectedCliente = null;
                                      clienteCtrl.clear();
                                      cnpjCtrl.clear();
                                    });
                                  },
                                  child: const Text('Limpar seleção'),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                  _field(clienteCtrl, 'Cliente', Icons.business),
                  _field(
                    cnpjCtrl,
                    'CNPJ',
                    Icons.badge,
                    hint: '00.000.000/0001-00',
                    mask: cnpjMask,
                    keyboardType: TextInputType.number,
                  ),
                  _field(tipoCtrl, 'Tipo de Tarefa', Icons.assignment),
                  _field(
                    prazoCtrl,
                    'Prazo',
                    Icons.calendar_today,
                    hint: 'DD/MM/AAAA',
                    mask: prazoMask,
                    keyboardType: TextInputType.number,
                  ),
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: obsCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Observações (Opcional)',
                        prefixIcon: const Icon(Icons.notes),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A47F5),
                      disabledBackgroundColor: const Color(
                        0xFF4A47F5,
                      ).withOpacity(0.5),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (clienteCtrl.text.trim().isEmpty ||
                                tipoCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(modalCtx).showSnackBar(
                                const SnackBar(
                                  content: Text('Preencha Cliente e Tipo.'),
                                ),
                              );
                              return;
                            }

                            String dataFormatada = DateTime.now()
                                .toIso8601String();
                            if (prazoCtrl.text.length == 10) {
                              final p = prazoCtrl.text.split('/');
                              dataFormatada =
                                  '${p[2]}-${p[1]}-${p[0]}T00:00:00';
                            }

                            setModal(() => isSaving = true);

                            final sucesso = await _apiService.criarTarefas({
                              'cliente': clienteCtrl.text.trim(),
                              'cnpj': cnpjCtrl.text.trim(),
                              'tipo': tipoCtrl.text.trim(),
                              'prazo': dataFormatada,
                              'observacao': obsCtrl.text.trim(),
                              'urgente': isUrgente,
                            });

                            if (sucesso) {
                              Navigator.of(context).pop();
                              // Atualiza Home (se estiver montado) e notifica o
                              // Calendar incrementando a chave.
                              _homeKey.currentState?.refreshData();
                              setState(() => _calendarRefreshKey++);
                            } else {
                              setModal(() => isSaving = false);
                              if (modalCtx.mounted) {
                                ScaffoldMessenger.of(modalCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Erro ao criar tarefa.'),
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
                      isSaving ? 'SALVANDO...' : 'SALVAR TAREFA',
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
          ),
        );
      },
    );
  }

  // ─────────────────────────── Helpers de UI ────────────────────────────────

  Widget _dragHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? hint,
    MaskTextInputFormatter? mask,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        inputFormatters: mask != null ? [mask] : [],
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
