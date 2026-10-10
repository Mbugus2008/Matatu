import 'package:flutter_test/flutter_test.dart';
import 'package:t_matatu/controllers/Members.dart';
import 'package:t_matatu/models/member.dart';

void main() {
  group('Member.keyTail', () {
    test('parses the trailing number of a NAV web-service key', () {
      final m = Member(Key: '24;EgAAAAJ7/0IAMQA1ADUAMw==8;322134510;');
      expect(m.keyTail, 322134510);
    });

    test('works without a trailing semicolon', () {
      expect(Member(Key: '20;x==8;339599750').keyTail, 339599750);
    });

    test('missing or unparseable keys give -1', () {
      expect(Member().keyTail, -1);
      expect(Member(Key: '').keyTail, -1);
      expect(Member(Key: 'not-a-key').keyTail, -1);
    });
  });

  group('MemberController.pickCurrentCrew', () {
    Member row(String no, Crew_type? type, String? key) =>
        Member(No: no, Key: key, Crew_Type: type);

    test('picks the row modified last (largest key tail)', () {
      final crew = [
        row('B753', Crew_type.Conductor, '20;x==8;341348310;'),
        row('B1620', Crew_type.Conductor, '20;x==8;341347950;'),
        row('B052', Crew_type.Conductor, '20;x==8;341348750;'),
      ];
      expect(MemberController.pickCurrentCrew(crew, Crew_type.Conductor)?.No,
          'B052');
    });

    test('follows the server when the just-assigned member is newest', () {
      final crew = [
        row('A903', Crew_type.Driver, '20;x==8;341322180;'),
        row('A261', Crew_type.Driver, '20;x==8;341322230;'),
      ];
      expect(
          MemberController.pickCurrentCrew(crew, Crew_type.Driver)?.No, 'A261');
    });

    test('ignores rows of the other crew type', () {
      final crew = [
        row('A999', Crew_type.Driver, '20;x==8;341000000;'),
        row('B999', Crew_type.Conductor, '20;x==8;342000000;'),
      ];
      expect(
          MemberController.pickCurrentCrew(crew, Crew_type.Driver)?.No, 'A999');
      expect(MemberController.pickCurrentCrew(crew, Crew_type.Conductor)?.No,
          'B999');
    });

    test('falls back to the first match when no keys are usable', () {
      final crew = [
        row('A903', Crew_type.Driver, null),
        row('A261', Crew_type.Driver, null),
      ];
      expect(
          MemberController.pickCurrentCrew(crew, Crew_type.Driver)?.No, 'A903');
    });

    test('returns null when nobody of that type is attached', () {
      final crew = [row('B753', Crew_type.Conductor, '20;x==8;100;')];
      expect(MemberController.pickCurrentCrew(crew, Crew_type.Driver), isNull);
      expect(MemberController.pickCurrentCrew(<Member>[], Crew_type.Driver),
          isNull);
    });
  });
}
