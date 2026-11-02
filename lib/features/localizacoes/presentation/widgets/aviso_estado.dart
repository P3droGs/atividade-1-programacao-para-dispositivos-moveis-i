import 'package:flutter/material.dart';

/// Mensagem centralizada para os estados de erro e de histórico vazio.
/// É rolável para continuar funcionando dentro de um RefreshIndicator.
class AvisoEstado extends StatelessWidget {
  const AvisoEstado({
    super.key,
    required this.icone,
    required this.texto,
    this.acao,
  });

  final IconData icone;
  final String texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: limites.maxWidth,
            minHeight: limites.maxHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icone, size: 48),
                const SizedBox(height: 12),
                Text(texto, textAlign: TextAlign.center),
                ?acao,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
