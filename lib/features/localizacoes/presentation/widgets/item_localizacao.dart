import 'package:flutter/material.dart';

import '../../models/localizacao.dart';

/// Mostra os dados de uma localização: data e hora locais, coordenadas e
/// precisão. Usado na lista do histórico, na tela de coleta e no mapa.
class ItemLocalizacao extends StatelessWidget {
  const ItemLocalizacao({
    super.key,
    required this.localizacao,
    this.maisRecente = false,
  });

  final Localizacao localizacao;

  /// Destaca o registro mais recente em vermelho, como no mapa.
  final bool maisRecente;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final cor = maisRecente ? Colors.red : cores.primary;

    return ListTile(
      leading: Icon(Icons.location_on, color: cor, size: 32),
      title: Text(formatarDataHora(localizacao.instante)),
      subtitle: Text(
        'Lat: ${localizacao.latitude.toStringAsFixed(6)}\n'
        'Lon: ${localizacao.longitude.toStringAsFixed(6)}\n'
        'Precisão: ${localizacao.precisao.toStringAsFixed(1)} m',
      ),
      isThreeLine: true,
      trailing: maisRecente
          ? Chip(
              label: const Text('Mais recente'),
              labelStyle: const TextStyle(color: Colors.red),
              side: const BorderSide(color: Colors.red),
              visualDensity: VisualDensity.compact,
            )
          : null,
    );
  }
}

/// Converte o instante (UTC) para o horário local: dd/mm/aaaa hh:mm:ss.
String formatarDataHora(DateTime instante) {
  final local = instante.toLocal();
  String doisDigitos(int valor) => valor.toString().padLeft(2, '0');
  return '${doisDigitos(local.day)}/${doisDigitos(local.month)}/${local.year} '
      '${doisDigitos(local.hour)}:${doisDigitos(local.minute)}:'
      '${doisDigitos(local.second)}';
}
