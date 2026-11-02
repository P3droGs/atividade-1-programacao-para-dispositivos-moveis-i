import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/localizacao.dart';
import 'item_localizacao.dart';

/// Mapa com as ruas do OpenStreetMap e um marcador por localização.
/// A mais recente aparece em vermelho; tocar num marcador mostra os detalhes.
class MapaLocalizacoes extends StatefulWidget {
  const MapaLocalizacoes({
    super.key,
    required this.localizacoes,
    required this.cache,
  });

  /// Registros do mais recente para o mais antigo. Não pode ser vazia.
  final List<Localizacao> localizacoes;

  final MapCachingProvider cache;

  @override
  State<MapaLocalizacoes> createState() => _MapaLocalizacoesState();
}

class _MapaLocalizacoesState extends State<MapaLocalizacoes> {
  static const _urlRuas = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static final _urlDireitos = Uri.parse(
    'https://www.openstreetmap.org/copyright',
  );

  final _controlador = MapController();

  // O TileLayer descarta este provedor quando sai da tela.
  late final _imagens = NetworkTileProvider(cachingProvider: widget.cache);

  @override
  void didUpdateWidget(MapaLocalizacoes anterior) {
    super.didUpdateWidget(anterior);
    // Registros recarregados: enquadra de novo os pontos depois de desenhar.
    if (!identical(anterior.localizacoes, widget.localizacoes)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _enquadrar();
      });
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  CameraFit get _enquadramento => CameraFit.coordinates(
    coordinates: [
      for (final l in widget.localizacoes) LatLng(l.latitude, l.longitude),
    ],
    padding: const EdgeInsets.all(64),
    maxZoom: 17,
  );

  void _enquadrar() => _controlador.fitCamera(_enquadramento);

  void _mostrarDetalhes(Localizacao localizacao, bool maisRecente) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ItemLocalizacao(
            localizacao: localizacao,
            maisRecente: maisRecente,
          ),
        ),
      ),
    );
  }

  Marker _marcador(Localizacao localizacao, bool maisRecente) {
    final ponto = LatLng(localizacao.latitude, localizacao.longitude);
    final cor = Theme.of(context).colorScheme.primary;

    if (maisRecente) {
      return Marker(
        point: ponto,
        width: 48,
        height: 48,
        alignment: Alignment.topCenter, // a ponta do pino fica no ponto
        child: GestureDetector(
          onTap: () => _mostrarDetalhes(localizacao, true),
          child: const Icon(Icons.location_on, color: Colors.red, size: 48),
        ),
      );
    }

    return Marker(
      point: ponto,
      width: 28,
      height: 28,
      child: GestureDetector(
        onTap: () => _mostrarDetalhes(localizacao, false),
        child: Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizacoes = widget.localizacoes;

    return Stack(
      children: [
        FlutterMap(
          mapController: _controlador,
          options: MapOptions(
            initialCameraFit: _enquadramento,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: _urlRuas,
              userAgentPackageName: 'br.fatec.localizacoes',
              tileProvider: _imagens,
              maxNativeZoom: 19,
            ),
            MarkerLayer(
              markers: [
                // As antigas primeiro, para a mais recente ficar por cima.
                for (final l in localizacoes.skip(1).toList().reversed)
                  _marcador(l, false),
                _marcador(localizacoes.first, true),
              ],
            ),
            // Atribuição sempre visível, como exige o OpenStreetMap.
            SimpleAttributionWidget(
              source: const Text(
                'Colaboradores do OpenStreetMap',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
              onTap: () => launchUrl(_urlDireitos),
            ),
          ],
        ),
        Positioned(
          top: 12,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: null,
            tooltip: 'Enquadrar todos os pontos',
            onPressed: _enquadrar,
            child: const Icon(Icons.fit_screen),
          ),
        ),
      ],
    );
  }
}
