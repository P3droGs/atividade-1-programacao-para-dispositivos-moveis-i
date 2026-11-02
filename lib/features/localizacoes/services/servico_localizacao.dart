import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Resultado da verificação feita antes de iniciar a coleta.
enum SituacaoLocalizacao {
  liberada,
  servicoDesativado,
  permissaoNegada,
  permissaoNegadaPermanentemente,
}

/// Acesso ao GPS: verifica serviço e permissões e fornece o stream de posições.
class ServicoLocalizacao {
  /// Intervalo solicitado entre as leituras. O sistema pode variar esse valor.
  static const intervalo = Duration(seconds: 20);

  /// Verifica se o GPS está ligado e pede a permissão de localização quando
  /// ela ainda não foi concedida.
  Future<SituacaoLocalizacao> verificarLocalizacao() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return SituacaoLocalizacao.servicoDesativado;
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    switch (permissao) {
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return SituacaoLocalizacao.liberada;
      case LocationPermission.deniedForever:
        return SituacaoLocalizacao.permissaoNegadaPermanentemente;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return SituacaoLocalizacao.permissaoNegada;
    }
  }

  /// No Android 13+, a notificação do serviço em primeiro plano só aparece
  /// com esta permissão. Devolve `true` se ela foi concedida.
  Future<bool> pedirPermissaoNotificacao() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Stream contínuo de posições com alta precisão. No Android, mantém um
  /// serviço em primeiro plano com notificação enquanto houver assinatura.
  Stream<Position> posicoes() {
    return Geolocator.getPositionStream(locationSettings: _configuracoes());
  }

  /// Abre a tela do sistema com as permissões deste aplicativo.
  Future<bool> abrirConfiguracoesPermissao() => Geolocator.openAppSettings();

  /// Abre a tela do sistema para ligar o serviço de localização (GPS).
  Future<bool> abrirConfiguracoesLocalizacao() =>
      Geolocator.openLocationSettings();

  LocationSettings _configuracoes() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: intervalo,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Coleta de localização ativa',
          notificationText: 'Registrando a posição do aparelho a cada 20 s.',
          notificationChannelName: 'Coleta de localização',
          notificationIcon: AndroidResource(name: 'ic_notificacao_coleta'),
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (Platform.isIOS) {
      // O iOS não aceita intervalo fixo: entrega as posições conforme o
      // sistema decide. O modo em segundo plano mantém a coleta minimizada.
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high);
  }
}
