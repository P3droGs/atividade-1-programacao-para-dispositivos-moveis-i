import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/cache_mapa.dart';
import '../widgets/aviso_estado.dart';
import '../widgets/mapa_localizacoes.dart';

/// Mapa com as últimas 100 posições. Trata espera, erro e histórico vazio
/// antes de mostrar o mapa.
class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key});

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  final _repositorio = RepositorioLocalizacoes();

  MapCachingProvider? _cache;
  List<Localizacao>? _localizacoes;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      // O cache das imagens precisa estar pronto antes de o mapa carregá-las.
      final cache = _cache ?? await CacheMapa.preparar();
      final localizacoes = await _repositorio.listarRecentes();
      if (!mounted) return;
      setState(() {
        _cache = cache;
        _localizacoes = localizacoes;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar as localizações: $erro';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _conteudo(),
    );
  }

  Widget _conteudo() {
    final localizacoes = _localizacoes;
    final cache = _cache;
    final erro = _erro;

    if (erro != null) {
      return AvisoEstado(
        icone: Icons.error_outline,
        texto: erro,
        acao: TextButton(
          onPressed: _carregar,
          child: const Text('Tentar novamente'),
        ),
      );
    }

    if (localizacoes == null || cache == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (localizacoes.isEmpty) {
      return AvisoEstado(
        icone: Icons.location_off,
        texto:
            'Nenhuma localização registrada.\n'
            'Inicie a coleta na tela inicial.',
        acao: TextButton(
          onPressed: _carregando ? null : _carregar,
          child: const Text('Atualizar'),
        ),
      );
    }

    return Stack(
      children: [
        MapaLocalizacoes(localizacoes: localizacoes, cache: cache),
        // Ao atualizar, o mapa continua na tela com uma barra de progresso.
        if (_carregando) const LinearProgressIndicator(),
      ],
    );
  }
}
