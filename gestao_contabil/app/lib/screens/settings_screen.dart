import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _usuario = '';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ListView(
        children: [
          Text(
            'Configurações',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _usuario.isNotEmpty
                ? 'Usuário: $_usuario'
                : 'Nenhum usuário conectado',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeManager.themeMode,
            builder: (context, themeMode, child) {
              final isDark = themeMode == ThemeMode.dark;
              return SwitchListTile(
                title: const Text('Tema escuro'),
                subtitle: const Text(
                  'Ative para usar o modo escuro no aplicativo',
                ),
                secondary: const Icon(Icons.dark_mode),
                value: isDark,
                onChanged: (value) => ThemeManager.setDarkMode(value),
              );
            },
          ),
        ],
      ),
    );
  }
}
