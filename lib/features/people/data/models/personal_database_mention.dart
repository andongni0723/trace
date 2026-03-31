class PersonalDatabasePersonMention {
  const PersonalDatabasePersonMention({
    required this.personId,
    required this.displayName,
  });

  final String personId;
  final String displayName;

  String get displayLabel => '@$displayName';

  String toToken() {
    return const PersonalDatabaseMentionCodec().encodeMention(this);
  }
}

class PersonalDatabaseMentionDraft {
  const PersonalDatabaseMentionDraft({
    required this.text,
    this.mentions = const [],
  });

  final String text;
  final List<PersonalDatabaseDraftMention> mentions;
}

class PersonalDatabaseDraftMention {
  const PersonalDatabaseDraftMention({
    required this.start,
    required this.end,
    required this.mention,
  });

  final int start;
  final int end;
  final PersonalDatabasePersonMention mention;

  String get displayText => mention.displayLabel;
}

abstract class PersonalDatabaseMentionSegment {
  const PersonalDatabaseMentionSegment();

  String get displayText;

  bool get isMention => this is PersonalDatabaseMentionPersonSegment;
}

class PersonalDatabaseMentionTextSegment
    extends PersonalDatabaseMentionSegment {
  const PersonalDatabaseMentionTextSegment(this.text);

  final String text;

  @override
  String get displayText => text;
}

class PersonalDatabaseMentionPersonSegment
    extends PersonalDatabaseMentionSegment {
  const PersonalDatabaseMentionPersonSegment(this.mention);

  final PersonalDatabasePersonMention mention;

  @override
  String get displayText => mention.displayLabel;
}

class PersonalDatabaseMentionCodec {
  const PersonalDatabaseMentionCodec();

  static const _tokenPrefix = '!';
  static const _labelPrefix = '![';
  static const _tokenBodyPrefix = '](person:';
  static const _tokenSuffix = ')';

  String encodeMention(PersonalDatabasePersonMention mention) {
    return '$_labelPrefix'
        '${Uri.encodeComponent(mention.displayName)}'
        '$_tokenBodyPrefix'
        '${Uri.encodeComponent(mention.personId)}'
        '$_tokenSuffix';
  }

  PersonalDatabasePersonMention? decodeMentionToken(String token) {
    final parsed = _tryParseMention(token, 0);
    if (parsed == null || parsed.endIndex != token.length) {
      return null;
    }
    return parsed.mention;
  }

  List<PersonalDatabaseMentionSegment> parseSegments(String rawText) {
    if (rawText.isEmpty) {
      return const [];
    }

    final segments = <PersonalDatabaseMentionSegment>[];
    var buffer = StringBuffer();
    var index = 0;

    while (index < rawText.length) {
      final parsed = _tryParseMention(rawText, index);
      if (parsed != null) {
        if (buffer.isNotEmpty) {
          segments.add(PersonalDatabaseMentionTextSegment(buffer.toString()));
          buffer = StringBuffer();
        }
        segments.add(PersonalDatabaseMentionPersonSegment(parsed.mention));
        index = parsed.endIndex;
        continue;
      }

      buffer.writeCharCode(rawText.codeUnitAt(index));
      index += 1;
    }

    if (buffer.isNotEmpty) {
      segments.add(PersonalDatabaseMentionTextSegment(buffer.toString()));
    }

    return segments;
  }

  String toDisplayText(String rawText) {
    return parseSegments(rawText).map((segment) => segment.displayText).join();
  }

  List<PersonalDatabasePersonMention> extractMentions(String rawText) {
    return parseSegments(rawText)
        .whereType<PersonalDatabaseMentionPersonSegment>()
        .map((segment) => segment.mention)
        .toList(growable: false);
  }

  PersonalDatabaseMentionDraft toDraft(String rawText) {
    final segments = parseSegments(rawText);
    if (segments.isEmpty) {
      return const PersonalDatabaseMentionDraft(text: '');
    }

    final buffer = StringBuffer();
    final mentions = <PersonalDatabaseDraftMention>[];
    var offset = 0;

    for (final segment in segments) {
      final displayText = segment.displayText;
      buffer.write(displayText);
      if (segment is PersonalDatabaseMentionPersonSegment) {
        mentions.add(
          PersonalDatabaseDraftMention(
            start: offset,
            end: offset + displayText.length,
            mention: segment.mention,
          ),
        );
      }
      offset += displayText.length;
    }

    return PersonalDatabaseMentionDraft(
      text: buffer.toString(),
      mentions: mentions,
    );
  }

  String fromDraft({
    required String text,
    required List<PersonalDatabaseDraftMention> mentions,
  }) {
    if (text.isEmpty || mentions.isEmpty) {
      return text;
    }

    final sortedMentions = [...mentions]
      ..sort((left, right) => left.start.compareTo(right.start));
    final buffer = StringBuffer();
    var cursor = 0;

    for (final draftMention in sortedMentions) {
      final normalizedStart = draftMention.start.clamp(0, text.length).toInt();
      final normalizedEnd = draftMention.end.clamp(0, text.length).toInt();
      if (normalizedStart < cursor || normalizedStart >= normalizedEnd) {
        continue;
      }

      final actualText = text.substring(normalizedStart, normalizedEnd);
      if (actualText != draftMention.displayText) {
        continue;
      }

      buffer.write(text.substring(cursor, normalizedStart));
      buffer.write(encodeMention(draftMention.mention));
      cursor = normalizedEnd;
    }

    buffer.write(text.substring(cursor));
    return buffer.toString();
  }

  ({String text, int caretOffset}) insertMention({
    required String text,
    required int replacementStart,
    required int replacementEnd,
    required PersonalDatabasePersonMention mention,
  }) {
    final normalizedStart = replacementStart.clamp(0, text.length).toInt();
    final normalizedEnd = replacementEnd.clamp(0, text.length).toInt();
    final start = normalizedStart <= normalizedEnd
        ? normalizedStart
        : normalizedEnd;
    final end = normalizedStart <= normalizedEnd
        ? normalizedEnd
        : normalizedStart;
    final token = encodeMention(mention);
    final updatedText = text.replaceRange(start, end, token);
    return (text: updatedText, caretOffset: start + token.length);
  }

  ({PersonalDatabasePersonMention mention, int endIndex})? _tryParseMention(
    String text,
    int index,
  ) {
    if (index + _tokenPrefix.length > text.length) {
      return null;
    }
    if (!text.startsWith(_tokenPrefix, index)) {
      return null;
    }
    if (!text.startsWith(_labelPrefix, index)) {
      return null;
    }

    final bodyStart = index + _labelPrefix.length;
    final bodyPrefixIndex = text.indexOf(_tokenBodyPrefix, bodyStart);
    if (bodyPrefixIndex == -1) {
      return null;
    }

    final encodedDisplayName = text.substring(bodyStart, bodyPrefixIndex);
    final personIdStart = bodyPrefixIndex + _tokenBodyPrefix.length;
    final tokenEnd = text.indexOf(_tokenSuffix, personIdStart);
    if (tokenEnd == -1) {
      return null;
    }

    try {
      final displayName = Uri.decodeComponent(encodedDisplayName);
      final personId = Uri.decodeComponent(
        text.substring(personIdStart, tokenEnd),
      );
      return (
        mention: PersonalDatabasePersonMention(
          personId: personId,
          displayName: displayName,
        ),
        endIndex: tokenEnd + _tokenSuffix.length,
      );
    } catch (_) {
      return null;
    }
  }
}
