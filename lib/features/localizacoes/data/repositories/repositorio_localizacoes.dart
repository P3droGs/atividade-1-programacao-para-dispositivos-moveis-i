import '../../models/localizacao.dart';
import '../database/banco_localizacoes.dart';

/// Único ponto de acesso aos registros salvos. As telas usam esta classe e
/// nunca executam SQL diretamente.
class RepositorioLocalizacoes {
  RepositorioLocalizacoes({BancoLocalizacoes? banco})
    : _banco = banco ?? BancoLocalizacoes.instancia;

  final BancoLocalizacoes _banco;

  /// Quantidade de registros mostrada no histórico e no mapa.
  static const limiteConsulta = 100;

  /// Salva uma posição e devolve o id gerado.
  Future<int> inserir(Localizacao localizacao) async {
    final db = await _banco.banco;
    return db.insert(BancoLocalizacoes.tabela, localizacao.toMap());
  }

  /// Últimos registros, do mais recente para o mais antigo. O limite vale só
  /// para a consulta: os registros antigos continuam no banco.
  Future<List<Localizacao>> listarRecentes({
    int limite = limiteConsulta,
  }) async {
    final db = await _banco.banco;
    final linhas = await db.query(
      BancoLocalizacoes.tabela,
      orderBy: 'instante DESC, id DESC',
      limit: limite,
    );
    return linhas.map(Localizacao.fromMap).toList();
  }

  /// Apaga todas as linhas da tabela, mantendo a tabela e o arquivo do banco.
  /// Devolve quantos registros foram apagados.
  Future<int> excluirTodas() async {
    final db = await _banco.banco;
    return db.delete(BancoLocalizacoes.tabela);
  }
}
