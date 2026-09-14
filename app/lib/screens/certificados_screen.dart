import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CertificadosScreen extends StatefulWidget {
  const CertificadosScreen({super.key});

  @override
  State<CertificadosScreen> createState() => _CertificadosScreenState();
}

class _CertificadosScreenState extends State<CertificadosScreen> {
  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('certificados') ?? '[]';
    final list = jsonDecode(raw) as List<dynamic>;
    _items
      ..clear()
      ..addAll(list.cast<Map<String, dynamic>>());
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('certificados', jsonEncode(_items));
  }

  void _abrirCadastro([Map<String, dynamic>? edit, int? index]) {
    final nomeCtrl = TextEditingController(
      text: edit?['nome'] as String? ?? '',
    );
    final idCtrl = TextEditingController(
      text: _formatarDocumento(edit?['cnpj_cpf'] as String? ?? ''),
    );
    final emissaoCtrl = TextEditingController(
      text: _formatarData(edit?['emissao'] as String?),
    );
    final validadeCtrl = TextEditingController(
      text: _formatarData(edit?['validade'] as String?),
    );
    final dataMask = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {'#': RegExp(r'[0-9]')},
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
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
                      edit != null ? 'Editar Certificado' : 'Novo Certificado',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nomeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nome da empresa',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: idCtrl,
                      inputFormatters: [_CpfCnpjInputFormatter()],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'CNPJ / CPF',
                        hintText: 'CPF ou CNPJ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emissaoCtrl,
                      inputFormatters: [dataMask],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Data de emissão (DD/MM/AAAA)',
                        hintText: 'DD/MM/AAAA',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: validadeCtrl,
                      inputFormatters: [dataMask],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Data de validade (DD/MM/AAAA)',
                        hintText: 'DD/MM/AAAA',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        backgroundColor: const Color(0xFF4A47F5),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final nome = nomeCtrl.text.trim();
                              final id = idCtrl.text.trim();
                              if (nome.isEmpty || id.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Preencha nome e CNPJ/CPF'),
                                  ),
                                );
                                return;
                              }
                              final emissao = _converterData(emissaoCtrl.text);
                              final validade = _converterData(
                                validadeCtrl.text,
                              );
                              if (emissao == null || validade == null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Informe emissão e validade no formato DD/MM/AAAA.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setModal(() => isSaving = true);
                              final item = {
                                'nome': nome,
                                'cnpj_cpf': _formatarDocumento(id),
                                'emissao': emissao,
                                'validade': validade,
                              };
                              if (edit != null && index != null) {
                                _items[index] = item;
                              } else {
                                _items.insert(0, item);
                              }
                              await _save();
                              await _load();
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            },
                      child: Text(
                        edit != null ? 'SALVAR' : 'ADICIONAR',
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
        );
      },
    );
  }

  void _remover(int idx) async {
    _items.removeAt(idx);
    await _save();
    await _load();
  }

  String _formatarData(String? valor) {
    if (valor == null || valor.isEmpty) return '';
    final data = DateTime.tryParse(valor);
    if (data == null) return valor;
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String? _converterData(String valor) {
    final partes = valor.split('/');
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

  String _formatarDocumento(String valor) {
    final digitos = valor.replaceAll(RegExp(r'\D'), '');
    if (digitos.length <= 11) {
      final cpf = digitos.length > 3
          ? '${digitos.substring(0, 3)}.${digitos.substring(3, digitos.length > 6 ? 6 : digitos.length)}'
          : digitos;
      if (digitos.length <= 6) return cpf;
      final parteFinal = digitos.substring(6);
      return '$cpf.${parteFinal.substring(0, parteFinal.length > 3 ? 3 : parteFinal.length)}'
          '${parteFinal.length > 3 ? '-${parteFinal.substring(3)}' : ''}';
    }
    final limitado = digitos.substring(
      0,
      digitos.length > 14 ? 14 : digitos.length,
    );
    final partes = [
      limitado.substring(0, limitado.length > 2 ? 2 : limitado.length),
      if (limitado.length > 2)
        limitado.substring(2, limitado.length > 5 ? 5 : limitado.length),
      if (limitado.length > 5)
        limitado.substring(5, limitado.length > 8 ? 8 : limitado.length),
      if (limitado.length > 8)
        limitado.substring(8, limitado.length > 12 ? 12 : limitado.length),
      if (limitado.length > 12) limitado.substring(12),
    ];
    return '${partes[0]}${partes.length > 1 ? '.${partes[1]}' : ''}'
        '${partes.length > 2 ? '.${partes[2]}' : ''}'
        '${partes.length > 3 ? '/${partes[3]}' : ''}'
        '${partes.length > 4 ? '-${partes[4]}' : ''}';
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
                        'Certificados',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Controle simples de validade (anotações).',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _abrirCadastro(),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A47F5),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum certificado registrado.',
                      style: GoogleFonts.poppins(),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final it = _items[i];
                      final validade = it['validade'] as String?;
                      DateTime? validadeDt;
                      try {
                        if (validade != null && validade.isNotEmpty) {
                          validadeDt = DateTime.tryParse(validade);
                        }
                      } catch (_) {
                        validadeDt = null;
                      }
                      final agora = DateTime.now();
                      final status = validadeDt == null
                          ? 'Sem data'
                          : (validadeDt.isBefore(agora)
                                ? 'Vencido'
                                : (validadeDt.isBefore(
                                        agora.add(const Duration(days: 30)),
                                      )
                                      ? 'Vence em breve'
                                      : 'Válido'));

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            it['nome'] as String,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${it['cnpj_cpf'] ?? ''}\nValidade: ${_formatarData(it['validade'] as String?)}',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          isThreeLine: true,
                          leading: CircleAvatar(
                            backgroundColor: status == 'Vencido'
                                ? Colors.red
                                : (status == 'Vence em breve'
                                      ? Colors.orange
                                      : Colors.green),
                            child: Text(status[0]),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _abrirCadastro(it, i);
                              if (v == 'delete') _remover(i);
                            },
                            itemBuilder: (ctx) => [
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
          ),
        ],
      ),
    );
  }
}

class _CpfCnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitado = digitos.length > 14 ? digitos.substring(0, 14) : digitos;
    final formatado = _formatar(limitado: limitado);
    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }

  String _formatar({required String limitado}) {
    if (limitado.length <= 11) {
      if (limitado.length <= 3) return limitado;
      final primeiro = limitado.substring(0, 3);
      if (limitado.length <= 6) {
        return '$primeiro.${limitado.substring(3)}';
      }
      final segundo = limitado.substring(3, 6);
      if (limitado.length <= 9) {
        return '$primeiro.$segundo.${limitado.substring(6)}';
      }
      return '$primeiro.$segundo.${limitado.substring(6, 9)}-'
          '${limitado.substring(9)}';
    }

    final partes = [
      limitado.substring(0, 2),
      limitado.substring(2, limitado.length > 5 ? 5 : limitado.length),
      limitado.substring(5, limitado.length > 8 ? 8 : limitado.length),
      limitado.substring(8, limitado.length > 12 ? 12 : limitado.length),
      if (limitado.length > 12) limitado.substring(12),
    ];
    return '${partes[0]}.${partes[1]}.${partes[2]}/${partes[3]}'
        '${partes.length > 4 ? '-${partes[4]}' : ''}';
  }
}
