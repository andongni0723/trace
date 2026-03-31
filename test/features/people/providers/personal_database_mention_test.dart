import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/features/people/data/models/personal_database_mention.dart';
import 'package:trace/features/people/providers/personal_database_provider.dart';

void main() {
  const codec = PersonalDatabaseMentionCodec();

  group('PersonalDatabaseMentionCodec', () {
    test('encodes and decodes a mention token with special characters', () {
      const mention = PersonalDatabasePersonMention(
        personId: 'person/1?demo=ok',
        displayName: '安東尼 [Team](A)',
      );

      final token = codec.encodeMention(mention);

      expect(token, startsWith('!['));
      expect(token, contains('](person:'));
      expect(codec.decodeMentionToken(token), isNotNull);
      expect(codec.decodeMentionToken(token)?.personId, mention.personId);
      expect(codec.decodeMentionToken(token)?.displayName, mention.displayName);
      expect(mention.toToken(), token);
    });

    test('parses mixed text and mention segments', () {
      const first = PersonalDatabasePersonMention(
        personId: 'p-1',
        displayName: '安東尼',
      );
      const second = PersonalDatabasePersonMention(
        personId: 'p-2',
        displayName: '小美',
      );
      final rawText =
          'Hello ${codec.encodeMention(first)} and ${codec.encodeMention(second)}!';

      final segments = codec.parseSegments(rawText);

      expect(segments, hasLength(5));
      expect(segments[0], isA<PersonalDatabaseMentionTextSegment>());
      expect(
        (segments[0] as PersonalDatabaseMentionTextSegment).text,
        'Hello ',
      );
      expect(
        (segments[1] as PersonalDatabaseMentionPersonSegment).mention,
        isA<PersonalDatabasePersonMention>()
            .having((mention) => mention.personId, 'personId', 'p-1')
            .having((mention) => mention.displayName, 'displayName', '安東尼'),
      );
      expect((segments[2] as PersonalDatabaseMentionTextSegment).text, ' and ');
      expect(
        (segments[3] as PersonalDatabaseMentionPersonSegment).mention,
        isA<PersonalDatabasePersonMention>()
            .having((mention) => mention.personId, 'personId', 'p-2')
            .having((mention) => mention.displayName, 'displayName', '小美'),
      );
      expect((segments[4] as PersonalDatabaseMentionTextSegment).text, '!');

      expect(codec.toDisplayText(rawText), 'Hello @安東尼 and @小美!');
      expect(
        codec.extractMentions(rawText).map((mention) => mention.personId),
        ['p-1', 'p-2'],
      );
    });

    test('inserts a mention token over a selected range', () {
      const mention = PersonalDatabasePersonMention(
        personId: 'p-3',
        displayName: '阿東',
      );

      final result = codec.insertMention(
        text: 'Hello @al',
        replacementStart: 6,
        replacementEnd: 9,
        mention: mention,
      );

      expect(result.text, 'Hello ${codec.encodeMention(mention)}');
      expect(result.caretOffset, result.text.length);
      expect(codec.toDisplayText(result.text), 'Hello @阿東');
    });

    test('round trips draft text and mention ranges', () {
      const mention = PersonalDatabasePersonMention(
        personId: 'p-9',
        displayName: '安東尼',
      );
      final rawText = 'Call ${codec.encodeMention(mention)} later';

      final draft = codec.toDraft(rawText);

      expect(draft.text, 'Call @安東尼 later');
      expect(draft.mentions, hasLength(1));
      expect(draft.mentions.single.start, 5);
      expect(draft.mentions.single.end, 9);
      expect(
        codec.fromDraft(text: draft.text, mentions: draft.mentions),
        rawText,
      );
    });

    test('leaves malformed tokens as plain text', () {
      const malformed = 'start ![broken](person:token';

      final segments = codec.parseSegments(malformed);

      expect(segments, hasLength(1));
      expect(
        (segments.single as PersonalDatabaseMentionTextSegment).text,
        malformed,
      );
      expect(codec.toDisplayText(malformed), malformed);
    });

    test('provider exposes the same codec', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final codecFromProvider = container.read(
        personalDatabaseMentionCodecProvider,
      );
      const mention = PersonalDatabasePersonMention(
        personId: 'provider-1',
        displayName: 'Provider',
      );

      expect(
        codecFromProvider.encodeMention(mention),
        codec.encodeMention(mention),
      );
      expect(
        codecFromProvider.toDisplayText(codec.encodeMention(mention)),
        '@Provider',
      );
    });
  });
}
