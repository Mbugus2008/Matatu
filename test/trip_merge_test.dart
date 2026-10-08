import 'package:flutter_test/flutter_test.dart';
import 'package:t_matatu/models/waybill/waybill.dart';

void main() {
  WaybillTrip trip(
          {String? key, int? no, bool sent = true, bool dirty = false}) =>
      WaybillTrip(Key: key, Trip_No: no, sent: sent)..dirty = dirty;

  group('WaybillService.isTempKey', () {
    test('13-digit millisecond keys are temp', () {
      expect(WaybillService.isTempKey('1759900000000'), isTrue);
    });

    test('BC keys and nulls are not temp', () {
      expect(WaybillService.isTempKey('20;x==8;342067790;'), isFalse);
      expect(WaybillService.isTempKey('12345'), isFalse);
      expect(WaybillService.isTempKey(null), isFalse);
    });
  });

  group('WaybillService.tripDisposition', () {
    test('unsent edit of a synced trip is protected — BC copy is older', () {
      final local =
          trip(key: '20;x==8;341962650;', no: 32, sent: false, dirty: true);
      final remote = trip(key: '20;x==8;341962650;', no: 32);
      expect(
        WaybillService.tripDisposition(local: local, remote: remote),
        TripSyncDisposition.keepEdit,
      );
    });

    test('dirty row is protected even when marked sent', () {
      final local =
          trip(key: '20;x==8;341962650;', no: 32, sent: true, dirty: true);
      final remote = trip(key: '20;x==8;341962650;', no: 32);
      expect(
        WaybillService.tripDisposition(local: local, remote: remote),
        TripSyncDisposition.keepEdit,
      );
    });

    test('never-synced temp row already on BC is dropped', () {
      final local =
          trip(key: '1759900000000', no: 32, sent: false, dirty: true);
      final remote = trip(key: '20;x==8;340000000;', no: 32);
      expect(
        WaybillService.tripDisposition(local: local, remote: remote),
        TripSyncDisposition.dropTemp,
      );
    });

    test('temp row not yet on BC stays pending', () {
      final local =
          trip(key: '1759900000000', no: 41, sent: false, dirty: true);
      expect(
        WaybillService.tripDisposition(local: local, remote: null),
        TripSyncDisposition.keepEdit,
      );
      // A BC copy of a DIFFERENT trip must not make it look synced.
      expect(
        WaybillService.tripDisposition(
            local: local, remote: trip(key: '20;x==8;1;', no: 42)),
        TripSyncDisposition.keepEdit,
      );
    });

    test('synced row whose BC record moved on is stale', () {
      final local = trip(key: '20;x==8;341962650;', no: 32);
      final remote = trip(key: '20;x==8;342067790;', no: 32);
      expect(
        WaybillService.tripDisposition(local: local, remote: remote),
        TripSyncDisposition.dropStale,
      );
    });

    test('synced row matching BC is kept', () {
      final local = trip(key: '20;x==8;342067790;', no: 32);
      final remote = trip(key: '20;x==8;342067790;', no: 32);
      expect(
        WaybillService.tripDisposition(local: local, remote: remote),
        TripSyncDisposition.keep,
      );
    });

    test('synced row with no BC copy is kept', () {
      final local = trip(key: '20;x==8;342067790;', no: 32);
      expect(
        WaybillService.tripDisposition(local: local, remote: null),
        TripSyncDisposition.keep,
      );
    });
  });
}
