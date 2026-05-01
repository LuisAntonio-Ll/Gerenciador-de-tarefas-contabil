import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api/api_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Gestão - NR",
          style: GoogleFonts.poppins(
            color: Color(0xFF4A47F5),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.black54),
            onPressed: () {},
          ),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, color: Colors.blue[900], size: 20),
            ),
          ),
        ],
      ),
      body: FutureBuilder<dynamic>(
        future: _apiService.getTarefas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text("Erro ao carregar dados ou lista vazia"));
          }

          //extraindo dados do back end
          final data = snapshot.data;
          final resumo = data['resumo'] as Map<String, dynamic>;
          final tarefas = data['tarefas'] as List<dynamic>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              _builderSummaryCards(resumo),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  "PARA FAZER",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tarefas.length,
                  itemBuilder: (context, index) {
                    final tarefa = tarefas[index];
                    return _buildTaskCard(tarefa);
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirModalCadastro,
        backgroundColor: Color(0xFF4A47F5),
        child: Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hoje,",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "29 de Março, 2026",
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _builderSummaryCards(Map<String, dynamic> resumo) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.only(left: 20, bottom: 20),
      child: Row(
        children: [
          _statusCard(
            "Pendentes",
            resumo['pendentes'].toString(),
            Color(0xFFFFF3E0),
            Colors.orange,
          ),
          _statusCard(
            "Atrasadas",
            resumo['atrasadas'].toString(),
            Color(0xFFFFEBEE),
            Colors.red,
          ),
          _statusCard(
            "Concluídas",
            resumo['concluidas'].toString(),
            Color(0xFFE8F5E9),
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _statusCard(String label, String value, Color bg, Color textCol) {
    return Container(
      margin: EdgeInsets.only(right: 12),
      padding: EdgeInsets.all(16),
      width: 100,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textCol,
            ),
          ),
          SizedBox(height: 4),
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

  //metodo para excluir tarefa
  void _confirmarExclusao(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Exclui Tarefa?"),
        content: Text("Essa ação não pode ser desfeita."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () async {
              final sucesso = await _apiService.deletarTarefa(id);
              if (sucesso) {
                Navigator.pop(context); // Fecha o alerta
                setState(() {}); // Recarrega o FutureBuilder da Home
              } else {
                // Opcional: mostrar um SnackBar de erro
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erro ao excluir tarefa no servidor")),
                );
              }
            },
            child: Text("EXCLUIR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(dynamic tarefa) {
    final dataPrazo = DateTime.parse(tarefa['prazo']);
    final agora = DateTime.now();

    bool isAtrasada =
        dataPrazo.isBefore(agora) && tarefa['status'] != 'concluido';
    bool isUrgente = tarefa['urgente'] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          tarefa['cliente'],
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("CNPJ: ${tarefa['cnpj']}"),
            Text(
              "Serviço: ${tarefa['tipo']}",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A47F5),
              ),
            ),
            if (tarefa['observacao'] != null &&
                tarefa['observacao'].toString().isNotEmpty)
              Text(
                "Obs: ${tarefa['observacao']}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            SizedBox(height: 5),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: (isAtrasada || isUrgente) ? Colors.red : Colors.grey,
                ),
                SizedBox(width: 4),
                Text(
                  "Prazo: ${tarefa['prazo'].split('T')[0]}",
                  style: TextStyle(
                    color: (isAtrasada || isUrgente) ? Colors.red : Colors.grey,
                    fontWeight: (isAtrasada || isUrgente)
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (isAtrasada)
                  Text(
                    " (ATRASADA)",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
        // MENU DE 3 PONTINHOS
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) {
            if (value == 'edit') _abrirModalDetalhes(tarefa);
            if (value == 'delete') _confirmarExclusao(tarefa['id']);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text("Editar"),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text("Excluir", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      notchMargin: 8,
      child: Container(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.dashboard, color: Color(0xFF4A47F5)),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.assignment, color: Colors.grey),
              onPressed: () {},
            ),
            SizedBox(width: 40), // Espaço para o botão flutuante
            IconButton(
              icon: Icon(Icons.people, color: Colors.grey),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.settings, color: Colors.grey),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _abrirModalCadastro() {
    final _clienteController = TextEditingController();
    final _cnpjController = TextEditingController();
    final _tipoController = TextEditingController(); // Agora é "Tarefa"
    final _prazoController = TextEditingController();
    final _obsController = TextEditingController(); // Novo campo

    // Definindo as máscaras
    final cnpjMask = MaskTextInputFormatter(
      mask: '##.###.###/####-##',
      filter: {"#": RegExp(r'[0-9]')},
    );
    final prazoMask = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {"#": RegExp(r'[0-9]')},
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          // Para telas menores não cortarem
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Nova Tarefa",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextField(
                controller: _clienteController,
                decoration: InputDecoration(labelText: "Cliente"),
              ),
              TextField(
                controller: _cnpjController,
                inputFormatters: [cnpjMask], // Aplicando a máscara
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "CNPJ",
                  hintText: "00.000.000/0001-00",
                ),
              ),
              TextField(
                controller: _tipoController,
                decoration: InputDecoration(
                  labelText: "Tarefa",
                ), // Label alterada
              ),
              TextField(
                controller: _prazoController,
                inputFormatters: [prazoMask], // Aplicando a máscara
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Prazo",
                  hintText: "DD/MM/AAAA",
                ),
              ),
              TextField(
                controller: _obsController,
                maxLines: 3, // Campo maior para observações
                decoration: InputDecoration(
                  labelText: "Observações (Opcional)",
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4A47F5),
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () async {
                  // Inverte a data de DD/MM/AAAA para AAAA-MM-DD pro Backend
                  String dataFormatada = "";
                  if (_prazoController.text.length == 10) {
                    final partes = _prazoController.text.split('/');
                    dataFormatada =
                        '${partes[2]}-${partes[1]}-${partes[0]}T00:00:00';
                  }

                  final nova = {
                    'cliente': _clienteController.text,
                    'cnpj': _cnpjController.text,
                    'tipo': _tipoController.text,
                    'prazo': dataFormatada.isEmpty
                        ? DateTime.now().toIso8601String()
                        : dataFormatada,
                    'observacao': _obsController.text, // Enviando pro banco
                  };

                  final sucesso = await _apiService.criarTarefas(nova);
                  if (sucesso) {
                    Navigator.pop(context);
                    setState(() {}); // Recarrega a tela
                  }
                },
                child: Text(
                  "SALVAR TAREFA",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirModalDetalhes(Map<String, dynamic> tarefa) {
    final _obsController = TextEditingController(
      text: tarefa['observacao'] ?? '',
    );

    // Controller para o prazo (pegando o valor que já vem do banco)
    // Formatamos de AAAA-MM-DD para DD/MM/AAAA para o usuário editar
    String dataInicial = tarefa['prazo'].split('T')[0];
    List<String> partesData = dataInicial.split('-');
    final _prazoController = TextEditingController(
      text: "${partesData[2]}/${partesData[1]}/${partesData[0]}",
    );

    final prazoMask = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {"#": RegExp(r'[0-9]')},
    );

    String statusAtual = tarefa['status'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
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
                    tarefa['cliente'],
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "CNPJ: ${tarefa['cnpj']}",
                    style: TextStyle(color: Colors.grey),
                  ),
                  Divider(height: 30),

                  // NOVO: Edição do Prazo
                  TextField(
                    controller: _prazoController,
                    inputFormatters: [prazoMask],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Editar Prazo",
                      hintText: "DD/MM/AAAA",
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                  ),
                  SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: statusAtual,
                    decoration: InputDecoration(labelText: "Status da Tarefa"),
                    items: [
                      DropdownMenuItem(
                        value: "pendente",
                        child: Text("Pendente"),
                      ),
                      DropdownMenuItem(
                        value: "concluido",
                        child: Text("Concluída"),
                      ),
                    ],
                    onChanged: (novoStatus) {
                      if (novoStatus != null) {
                        setModalState(() => statusAtual = novoStatus);
                      }
                    },
                  ),
                  SizedBox(height: 15),

                  TextField(
                    controller: _obsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Observações",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: () async {
                      // Formata a data de volta para o padrão do Banco (ISO 8601)
                      String dataFormatada =
                          tarefa['prazo']; // Valor antigo caso falte algo
                      if (_prazoController.text.length == 10) {
                        final partes = _prazoController.text.split('/');
                        dataFormatada =
                            '${partes[2]}-${partes[1]}-${partes[0]}T00:00:00';
                      }

                      final dadosAtualizados = {
                        'status': statusAtual,
                        'observacao': _obsController.text,
                        'prazo': dataFormatada, // ENVIANDO A NOVA DATA
                      };

                      final sucesso = await _apiService.atualizarTarefa(
                        tarefa['id'],
                        dadosAtualizados,
                      );

                      if (sucesso) {
                        Navigator.pop(context);
                        setState(() {});
                      }
                    },
                    child: Text(
                      "SALVAR ALTERAÇÕES",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
