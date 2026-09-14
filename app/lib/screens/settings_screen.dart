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
          const SizedBox(height: 12),
          Text(
            'Escolher cor do tema',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<MaterialColor>(
            valueListenable: ThemeManager.primarySwatch,
            builder: (context, swatch, child) {
              return Wrap(
                spacing: 12,
                children: [
                  _colorOption(
                    'indigo',
                    Colors.indigo,
                    swatch == Colors.indigo,
                  ),
                  _colorOption('green', Colors.green, swatch == Colors.green),
                  _colorOption('teal', Colors.teal, swatch == Colors.teal),
                  _colorOption(
                    'deepPurple',
                    Colors.deepPurple,
                    swatch == Colors.deepPurple,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _colorOption(String key, MaterialColor color, bool selected) {
    return GestureDetector(
      onTap: () => ThemeManager.setThemeVariant(key),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.black : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              key
                  .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
                  .toUpperCase(),
              style: GoogleFonts.poppins(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
