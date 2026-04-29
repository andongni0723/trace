import 'package:flutter_test/flutter_test.dart';
import 'package:trace/features/people/data/models/person_note_token.dart';
import 'package:trace/features/people/data/services/person_note_token_codec.dart';

void main() {
  const codec = PersonNoteTokenCodec();

  test('parseTokenRanges ignores malformed percent-encoded tokens', () {
    final ranges = codec.parseTokenRanges('Before ![Alice](person:%) after');

    expect(ranges, isEmpty);
  });

  test('parseTokenRanges keeps valid tokens', () {
    final ranges = codec.parseTokenRanges('Before ![Alice](person:friend)');

    expect(ranges, hasLength(1));
    expect(
      ranges.single.token,
      const PersonNoteToken.person(id: 'friend', label: 'Alice'),
    );
  });
}
