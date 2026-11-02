import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../widgets/aviso_estado.dart';
import '../widgets/item_localizacao.dart';

/// Histórico: últimas 100 localizações, da mais recente para a mais antiga.
class TelaLocalizacoes extends StatefulWidget {
  const TelaLocalizacoes({super.key, required this.coletaAtiva});

  /// Usado para avisar, na limpeza, que novos registros continuarão chegando.
  final bool coletaAtiva;

  @override
  State<TelaLocalizacoes> createState() => _TelaLocalizacoesState();
}

class _TelaLocalizacoesState extends State<TelaLocalizacoes> {
  final _repositorio = RepositorioLocalizacoes();

  List<Localizacao> _localizacoes = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  /// Consulta o banco de novo. Não mexe na coleta, que segue gravando.
  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final localizacoes = await _repositorio.listarRecentes();
      if (!mounted) return;
      setState(() {
        _localizacoes = localizacoes;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar o histórico: $erro';
        _carregando = false;
      });
    }
  }

  Future<void> _limparHistorico() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar histórico?'),
        content: Text(
          'Todas as localizações salvas serão apagadas, inclusive as '
          'anteriores às 100 exibidas. Esta operação é permanente e não pode '
          'ser desfeita.'
          '${widget.coletaAtiva ? '\n\nA coleta está ativa: novos registros '
                    'continuarão sendo salvos depois da limpeza.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar histórico'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    try {
      final apagadas = await _repositorio.excluirTodas();
      if (!mounted) return;
      await _carregar();
      if (!mounted) return;
      _mostrarMensagem(
        apagadas == 1
            ? 'Histórico limpo: 1 registro apagado.'
            : 'Histórico limpo: $apagadas registros apagados.',
      );
    } catch (erro) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível limpar o histórico: $erro');
    }
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Limpar histórico',
            onPressed: _carregando || _localizacoes.isEmpty
                ? null
                : _limparHistorico,
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _carregar, child: _conteudo()),
    );
  }

  Widget _conteudo() {
    if (_carregando && _localizacoes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

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

    if (_localizacoes.isEmpty) {
      return const AvisoEstado(
        icone: Icons.location_off,
        texto:
            'Nenhuma localização registrada.\n'
            'Inicie a coleta na tela inicial.',
      );
    }

    return ListView.separated(
      // Mantém o "puxar para atualizar" mesmo com poucos itens.
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _localizacoes.length + 1,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, indice) {
        if (indice == 0) {
          final total = _localizacoes.length;
          const limite = RepositorioLocalizacoes.limiteConsulta;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              total == 1
                  ? '1 localização (até $limite)'
                  : 'Últimas $total localizações (até $limite)',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          );
        }
        return ItemLocalizacao(
          localizacao: _localizacoes[indice - 1],
          maisRecente: indice == 1,
        );
      },
    );
  }
}
