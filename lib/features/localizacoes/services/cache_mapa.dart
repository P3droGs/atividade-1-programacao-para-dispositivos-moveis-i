import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Prepara o cache das imagens do mapa (tiles) numa pasta privada do app.
///
/// O cache segue os cabeçalhos HTTP do servidor do OpenStreetMap para saber
/// por quanto tempo cada imagem continua válida, como pede a política de uso
/// do provedor.
class CacheMapa {
  CacheMapa._();

  static const _nomePasta = 'cache_mapa';
  static const _tamanhoMaximo = 200 * 1024 * 1024; // 200 MB

  /// Cria a pasta (se ainda não existir) e devolve o cache que o mapa usa.
  /// Se não for possível preparar a pasta, o mapa funciona sem cache.
  static Future<MapCachingProvider> preparar() async {
    try {
      final suporte = await getApplicationSupportDirectory();
      final pasta = Directory(join(suporte.path, _nomePasta));
      await pasta.create(recursive: true);
      return BuiltInMapCachingProvider.getOrCreateInstance(
        cacheDirectory: pasta.path,
        maxCacheSize: _tamanhoMaximo,
      );
    } catch (_) {
      return const DisabledMapCachingProvider();
    }
  }
}
