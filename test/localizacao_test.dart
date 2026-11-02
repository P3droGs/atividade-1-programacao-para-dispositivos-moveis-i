import 'package:flutter_test/flutter_test.dart';
import 'package:localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:localizacoes/features/localizacoes/presentation/widgets/item_localizacao.dart';

void main() {
  test('converte para mapa com o instante em UTC no formato ISO 8601', () {
    final localizacao = Localizacao(
      latitude: -23.1234567,
      longitude: -45.7654321,
      precisao: 4.25,
      instante: DateTime.utc(2026, 11, 2, 13, 5, 20),
    );

    expect(localizacao.toMap(), {
      'latitude': -23.1234567,
      'longitude': -45.7654321,
      'precisao': 4.25,
      'instante': '2026-11-02T13:05:20.000Z',
    });
  });

  test('lê uma linha do banco e mantém o instante em UTC', () {
    final localizacao = Localizacao.fromMap({
      'id': 7,
      'latitude': -23.5,
      'longitude': -46,
      'precisao': 12,
      'instante': '2026-11-02T13:05:20.000Z',
    });

    expect(localizacao.id, 7);
    expect(localizacao.longitude, -46.0);
    expect(localizacao.precisao, 12.0);
    expect(localizacao.instante, DateTime.utc(2026, 11, 2, 13, 5, 20));
    expect(localizacao.instante.isUtc, isTrue);
  });

  test('apresenta a data e a hora no horário local', () {
    final instante = DateTime.utc(2026, 11, 2, 13, 5, 20);
    final local = instante.toLocal();
    String dois(int v) => v.toString().padLeft(2, '0');

    expect(
      formatarDataHora(instante),
      '${dois(local.day)}/${dois(local.month)}/${local.year} '
      '${dois(local.hour)}:${dois(local.minute)}:${dois(local.second)}',
    );
  });
}
