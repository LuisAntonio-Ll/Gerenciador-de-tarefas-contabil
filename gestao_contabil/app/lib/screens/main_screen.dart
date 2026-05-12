import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/api/api_service.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';

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

  // GlobalKey para chamar refreshData() diretamente no HomeScreen
  // sem precisar fazer setState no MainScreen inteiro
  final _homeKey = GlobalKey<HomeScreenState>();

  static const _titles = ['Gestão - NR', 'Calendário'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
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
            icon: const Icon(Icons.notifications_none, color: Colors.black54),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, color: Colors.blue[900], size: 20),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(key: _homeKey),
          CalendarScreen(refreshKey: 0, onRefresh: () {}),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
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
            // 3° e 4° ícones livres para futuras funcionalidades
            _navItem(Icons.people_rounded, -1),
            _navItem(Icons.settings_rounded, -1),
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
                              // ── CORREÇÃO DA TELA BRANCA ─────────────────
                              // 1. Fecha o modal pelo Navigator raiz do app,
                              //    não pelo contexto do builder (que pode já
                              //    estar desmontado após o await)
                              Navigator.of(context).pop();

                              // 2. Chama refresh diretamente no estado do
                              //    HomeScreen via GlobalKey — sem setState
                              //    no MainScreen (que causaria rebuild + tela
                              //    branca durante o carregamento)
                              _homeKey.currentState?.refreshData();
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
