import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Abre o banco SQLite `localizacoes.db` e cria a tabela na primeira vez.
///
/// A conexão é aberta uma única vez e reutilizada. Se a abertura falhar, a
/// próxima chamada a [banco] tenta abrir de novo.
class BancoLocalizacoes {
  BancoLocalizacoes._();

  static final BancoLocalizacoes instancia = BancoLocalizacoes._();

  static const nomeArquivo = 'localizacoes.db';
  static const versao = 1;
  static const tabela = 'localizacoes';

  Future<Database>? _abertura;

  Future<Database> get banco async {
    final atual = _abertura;
    if (atual != null) return atual;

    final nova = _abrir();
    _abertura = nova;
    try {
      return await nova;
    } catch (_) {
      // Descarta a tentativa que falhou para permitir uma nova.
      if (identical(_abertura, nova)) _abertura = null;
      rethrow;
    }
  }

  Future<Database> _abrir() async {
    final pasta = await getDatabasesPath();
    return openDatabase(
      join(pasta, nomeArquivo),
      version: versao,
      onCreate: _criar,
    );
  }

  Future<void> _criar(Database db, int versao) async {
    await db.execute('''
      CREATE TABLE $tabela (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        precisao REAL NOT NULL,
        instante TEXT NOT NULL
      )
    ''');
  }
}
