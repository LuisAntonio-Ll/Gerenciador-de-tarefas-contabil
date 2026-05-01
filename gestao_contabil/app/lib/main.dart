import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const NrApp());
}

class NrApp extends StatelessWidget {
  const NrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NR',
      debugShowCheckedModeBanner: false,

      // Definimos o tema global baseado no estilo "Be Organized" da foto
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),

      // A tela que abre primeiro
      initialRoute: '/login',

      // Mapa de rotas do aplicativo
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
