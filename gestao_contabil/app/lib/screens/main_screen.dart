import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/api/api_service.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'concluidas_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _refreshKey = 0;
  final ApiService _apiService = ApiService();

  //Incrementar forçar rebuild nas telas filhas (via didUpdateWidget)
  void _forceRefresh() => setState(() => _refreshKey++);

  // Callback para a HomeScreen poder navegar para aba Concluídas
  void _navegarParaConcluidas() => setState(() => _currentIndex = 2);

  static const _titles = ['Gestão - NR', 'Calendário', 'Concluídas'];

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
      // IndexedStack mantém o estado de cada aba ao trocar
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            refreshKey: _refreshKey,
            onNavigateToConcluidas: _navegarParaConcluidas,
            onRefresh: _forceRefresh,
          ),
          CalendarScreen(refreshKey: _refreshKey, onRefresh: _forceRefresh),
          ConcluidasScreen(refreshKey: _refreshKey),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      // O FAB não aparece na aba de Concluídas
      floatingActionButton: _currentIndex != 2
          ? FloatingActionButton(
              onPressed: _abrirModalCadastro,
              backgroundColor: const Color(0xFF4A47F5),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

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
            _navItem(Icons.check_circle_outline_rounded, 2),
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
      onPressed: () {
        if (index == 3) return; // Settings sem ação por enquanto
        setState(() => _currentIndex = index);
      },
    );
  }

  // ───────────────────────────── Modal de Cadastro ─────────────────────────

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
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de arraste
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
              TextField(
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
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A47F5),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(
                  'SALVAR TAREFA',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  String dataFormatada = '';
                  if (prazoCtrl.text.length == 10) {
                    final p = prazoCtrl.text.split('/');
                    dataFormatada = '${p[2]}-${p[1]}-${p[0]}T00:00:00';
                  }

                  final nova = {
                    'cliente': clienteCtrl.text,
                    'cnpj': cnpjCtrl.text,
                    'tipo': tipoCtrl.text,
                    'prazo': dataFormatada.isEmpty
                        ? DateTime.now().toIso8601String()
                        : dataFormatada,
                    'observacao': obsCtrl.text,
                  };

                  final sucesso = await _apiService.criarTarefas(nova);
                  if (sucesso && ctx.mounted) {
                    Navigator.pop(ctx);
                    _forceRefresh();
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
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
