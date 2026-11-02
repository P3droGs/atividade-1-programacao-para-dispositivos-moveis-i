# Localizações

Atividade 1 – Coleta e visualização de localizações
Programação para Dispositivos Móveis I – Prof. Arley – Fatec

## Integrantes

- NOME COMPLETO DO INTEGRANTE 1
- NOME COMPLETO DO INTEGRANTE 2 (se for em dupla)

## O que o app faz

- **Coleta:** inicia e para a coleta da posição do aparelho. Usa um stream de
  posições com alta precisão e intervalo solicitado de 20 segundos. No Android,
  a coleta roda num serviço em primeiro plano, com uma notificação visível, e
  continua ao trocar de tela ou minimizar o app.
- **Histórico:** mostra as últimas 100 localizações, da mais recente para a
  mais antiga, com data e hora locais, latitude e longitude (6 casas) e
  precisão em metros (1 casa). Permite atualizar sem parar a coleta e limpar
  todo o histórico, com confirmação.
- **Mapa:** mostra as últimas 100 posições sobre as ruas do OpenStreetMap. A
  mais recente fica em vermelho. Os pontos são enquadrados ao abrir, e há
  botões para enquadrar de novo e para atualizar. Tocar num marcador mostra os
  detalhes do registro.
- **Persistência:** banco SQLite `localizacoes.db`, tabela `localizacoes`
  (`id`, `latitude`, `longitude`, `precisao`, `instante` em UTC no formato ISO
  8601). O limite de 100 vale só para a consulta.

## Como rodar

Requisitos: Flutter 3.47 ou mais novo e Android SDK com a plataforma 37
(exigida pelo `permission_handler`).

```bash
flutter pub get
flutter run
```

Verificações usadas na entrega:

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

No emulador, a posição pode ser simulada pelos controles estendidos (⋮ >
Location) ou por `adb emu geo fix <longitude> <latitude>`.

## Estrutura

```
lib/
├── main.dart                         # inicia o Flutter e executa o App
├── app.dart                          # MaterialApp, tema e tela inicial
└── features/localizacoes/
    ├── models/localizacao.dart       # registro tipado e conversão de/para Map
    ├── data/
    │   ├── database/banco_localizacoes.dart        # abre o banco e cria a tabela
    │   └── repositories/repositorio_localizacoes.dart  # inserir, consultar, excluir
    ├── services/
    │   ├── servico_localizacao.dart  # GPS, permissões, stream e configurações
    │   └── cache_mapa.dart           # cache das imagens do mapa em pasta privada
    └── presentation/
        ├── screens/
        │   ├── tela_coleta.dart      # botões e assinatura do stream
        │   ├── tela_localizacoes.dart  # histórico e limpeza
        │   └── tela_mapa.dart        # estados de espera, erro e vazio
        └── widgets/
            ├── item_localizacao.dart # dados de um registro (lista, coleta e mapa)
            ├── mapa_localizacoes.dart  # ruas, marcadores e botões do mapa
            └── aviso_estado.dart     # mensagem de erro/vazio usada pelas telas
```

## Decisões técnicas

| Necessidade | Escolha | Por quê |
|---|---|---|
| Stream de posições e serviço em primeiro plano | `geolocator` | `getPositionStream` com `AndroidSettings(intervalDuration: 20 s)` e `ForegroundNotificationConfig` sobe o serviço com notificação sem código nativo. |
| Permissão de notificação (Android 13+) | `permission_handler` | O `geolocator` não pede essa permissão; sem ela a notificação da coleta não aparece. |
| Banco local | `sqflite` + `path` | SQLite exigido pela atividade. |
| Mapa | `flutter_map` + `latlong2` | Mapa com camada de ruas do OpenStreetMap, sem chave de API. |
| Cache do mapa | `path_provider` + cache embutido do `flutter_map` | As imagens ficam na pasta de suporte do app (privada), limitadas a 200 MB, respeitando os cabeçalhos HTTP do servidor. |
| Link da atribuição | `url_launcher` | Abre a página de direitos autorais do OpenStreetMap. |

Outros pontos:

- **Sem assinaturas duplicadas:** o botão de iniciar só fica habilitado sem
  assinatura ativa, e um indicador `_ocupado` trava os botões enquanto a coleta
  inicia ou para.
- **Sem gravações sobrepostas:** se uma posição chega enquanto a anterior ainda
  está sendo gravada, ela é descartada (`_gravando`).
- **Erros do stream** (GPS desligado ou permissão retirada durante a coleta)
  encerram a coleta e mostram o motivo.
- **Banco:** a conexão é aberta uma vez e reaproveitada; se a abertura falhar,
  a próxima chamada tenta de novo.
- **Atribuição do mapa** sempre visível ("© Colaboradores do OpenStreetMap"),
  `User-Agent` com o pacote do app e nenhum download em massa de imagens,
  conforme a política de uso dos tiles do OpenStreetMap.
- Bancos `.db` estão no `.gitignore` para não publicar coordenadas pessoais.

## Ícone

- Imagem original: `assets/icons/localizacoes.png` (1024 × 1024).
- Android: ícone adaptativo em `res/mipmap-anydpi-v26/ic_localizacoes.xml`, com
  a imagem `res/drawable-nodpi/icone_localizacoes.png` e a cor de fundo em
  `res/values/icone_localizacoes.xml`; versões legadas em `res/mipmap-*/`.
  O `AndroidManifest.xml` aponta para `@mipmap/ic_localizacoes`.
- Notificação da coleta: `res/drawable/ic_notificacao_coleta.xml`.
- iOS: as imagens do `AppIcon.appiconset` também foram substituídas.

## iOS

O projeto também foi configurado para iOS (não testado, pois o build exige um
Mac): descrições de uso da localização no `Info.plist`, modo em segundo plano
`location` e posições em segundo plano pelo `AppleSettings` do `geolocator`. O
iOS não aceita intervalo fixo; as posições chegam conforme o sistema decide.
