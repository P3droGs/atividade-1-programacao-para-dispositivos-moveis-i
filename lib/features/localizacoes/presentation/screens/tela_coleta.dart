import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/servico_localizacao.dart';
import '../widgets/item_localizacao.dart';
import 'tela_localizacoes.dart';
import 'tela_mapa.dart';

/// Tela inicial: inicia e para a coleta e leva às outras telas.
///
/// É a dona da assinatura do stream de posições. Como fica embaixo das outras
/// telas na pilha de navegação, a coleta continua ao abrir o histórico ou o
/// mapa e ao minimizar o app (no Android, pelo serviço em primeiro plano).
class TelaColeta extends StatefulWidget {
  const TelaColeta({super.key});

  @override
  State<TelaColeta> createState() => _TelaColetaState();
}

class _TelaColetaState extends State<TelaColeta> {
  final _servico = ServicoLocalizacao();
  final _repositorio = RepositorioLocalizacoes();

  StreamSubscription<Position>? _assinatura;

  /// Verdadeiro enquanto inicia ou para a coleta; trava os dois botões.
  bool _ocupado = false;

  /// Verdadeiro enquanto uma posição está sendo gravada no banco.
  bool _gravando = false;

  Localizacao? _ultimaSalva;
  int _salvasNestaColeta = 0;

  bool get _coletando => _assinatura != null;

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }

  Future<void> _iniciarColeta() async {
    // Evita assinaturas duplicadas (ex.: dois toques rápidos no botão).
    if (_coletando || _ocupado) return;
    setState(() => _ocupado = true);

    try {
      final situacao = await _servico.verificarLocalizacao();
      if (!mounted) return;

      switch (situacao) {
        case SituacaoLocalizacao.servicoDesativado:
          await _orientar(
            titulo: 'Localização desligada',
            texto:
                'Ligue a localização (GPS) do aparelho para iniciar a coleta.',
            textoAcao: 'Ligar localização',
            acao: _servico.abrirConfiguracoesLocalizacao,
          );
          return;
        case SituacaoLocalizacao.permissaoNegada:
          await _orientar(
            titulo: 'Permissão negada',
            texto:
                'Sem a permissão de localização o app não consegue coletar. '
                'Toque em Iniciar coleta para pedir de novo ou libere a '
                'permissão nas configurações do aplicativo.',
            textoAcao: 'Abrir configurações',
            acao: _servico.abrirConfiguracoesPermissao,
          );
          return;
        case SituacaoLocalizacao.permissaoNegadaPermanentemente:
          await _orientar(
            titulo: 'Permissão bloqueada',
            texto:
                'A permissão de localização foi negada de forma permanente. '
                'Abra as configurações do aplicativo, entre em Permissões > '
                'Localização e escolha "Permitir durante o uso do app".',
            textoAcao: 'Abrir configurações',
            acao: _servico.abrirConfiguracoesPermissao,
          );
          return;
        case SituacaoLocalizacao.liberada:
          break;
      }

      final notificacaoLiberada = await _servico.pedirPermissaoNotificacao();
      if (!mounted) return;
      if (!notificacaoLiberada) {
        _mostrarMensagem(
          'Sem a permissão de notificação, o aviso da coleta não aparece na '
          'barra de status. A coleta funciona normalmente.',
        );
      }

      _salvasNestaColeta = 0;
      _assinatura = _servico.posicoes().listen(
        _salvarPosicao,
        onError: _tratarErroColeta,
      );
    } catch (erro) {
      if (mounted) _mostrarMensagem('Não foi possível iniciar a coleta: $erro');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _pararColeta() async {
    final assinatura = _assinatura;
    if (assinatura == null || _ocupado) return;
    setState(() => _ocupado = true);

    try {
      await assinatura.cancel();
    } finally {
      _assinatura = null;
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _salvarPosicao(Position posicao) async {
    // Se a gravação anterior ainda não terminou, descarta esta leitura para
    // não haver gravações sobrepostas.
    if (_gravando) return;
    _gravando = true;

    final localizacao = Localizacao(
      latitude: posicao.latitude,
      longitude: posicao.longitude,
      precisao: posicao.accuracy,
      instante: posicao.timestamp.toUtc(),
    );

    try {
      await _repositorio.inserir(localizacao);
      if (!mounted) return;
      setState(() {
        _ultimaSalva = localizacao;
        _salvasNestaColeta++;
      });
    } catch (erro) {
      if (mounted) _mostrarMensagem('Não foi possível salvar a posição: $erro');
    } finally {
      _gravando = false;
    }
  }

  /// Erros do stream (GPS desligado ou permissão retirada durante a coleta)
  /// encerram a coleta.
  void _tratarErroColeta(Object erro) {
    _assinatura?.cancel();
    if (!mounted) return;
    setState(() => _assinatura = null);

    final motivo = switch (erro) {
      LocationServiceDisabledException() => 'a localização foi desligada',
      PermissionDeniedException() => 'a permissão de localização foi retirada',
      _ => 'ocorreu um erro ($erro)',
    };
    _mostrarMensagem('Coleta interrompida: $motivo.');
  }

  Future<void> _abrirConfiguracoesPermissao() async {
    final abriu = await _servico.abrirConfiguracoesPermissao();
    if (!abriu && mounted) {
      _mostrarMensagem('Não foi possível abrir as configurações.');
    }
  }

  void _abrirHistorico() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TelaLocalizacoes(coletaAtiva: _coletando),
      ),
    );
  }

  void _abrirMapa() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const TelaMapa()));
  }

  Future<void> _orientar({
    required String titulo,
    required String texto,
    required String textoAcao,
    required Future<bool> Function() acao,
  }) async {
    final abrir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(textoAcao),
          ),
        ],
      ),
    );
    if (abrir == true) await acao();
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final ultima = _ultimaSalva;

    return Scaffold(
      appBar: AppBar(title: const Text('Coleta de localização')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                _coletando ? Icons.gps_fixed : Icons.gps_off,
                color: _coletando ? cores.primary : cores.outline,
                size: 32,
              ),
              title: Text(_coletando ? 'Coleta ativa' : 'Coleta parada'),
              subtitle: Text(
                _coletando
                    ? 'Intervalo solicitado: '
                          '${ServicoLocalizacao.intervalo.inSeconds} s · '
                          '$_salvasNestaColeta '
                          '${_salvasNestaColeta == 1 ? 'posição salva' : 'posições salvas'}'
                    : 'Toque em Iniciar coleta para registrar a posição.',
              ),
              trailing: _ocupado
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : null,
            ),
          ),
          if (ultima != null) ...[
            const SizedBox(height: 8),
            Text(
              'Última posição salva',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Card(child: ItemLocalizacao(localizacao: ultima)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: !_coletando && !_ocupado ? _iniciarColeta : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar coleta'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _coletando && !_ocupado ? _pararColeta : null,
            icon: const Icon(Icons.stop),
            label: const Text('Parar coleta'),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _abrirHistorico,
            icon: const Icon(Icons.history),
            label: const Text('Consultar histórico'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _abrirMapa,
            icon: const Icon(Icons.map),
            label: const Text('Ver mapa'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _abrirConfiguracoesPermissao,
            icon: const Icon(Icons.settings),
            label: const Text('Configurações de permissão'),
          ),
        ],
      ),
    );
  }
}
