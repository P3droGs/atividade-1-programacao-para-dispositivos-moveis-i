import 'package:flutter/material.dart';

import 'features/localizacoes/presentation/screens/tela_coleta.dart';

/// Widget raiz: tema e tela inicial do aplicativo.
class App extends StatelessWidget {
  const App({super.key});

  static const corPrincipal = Color(0xFF0B6E4F);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Localizações',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: corPrincipal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: corPrincipal,
        brightness: Brightness.dark,
      ),
      home: const TelaColeta(),
    );
  }
}
