import '../models/person_note_token.dart';

class PersonNoteTokenCodec {
  const PersonNoteTokenCodec();

  static const _labelPrefix = '![';
  static const _personBodyPrefix = '](person:';
  static const _mediaBodyPrefix = '](media:';
  static const _tokenSuffix = ')';

  String encodeToken(PersonNoteToken token) {
    final bodyPrefix = switch (token) {
      PersonNotePersonToken() => _personBodyPrefix,
      PersonNoteMediaToken() => _mediaBodyPrefix,
    };

    return '$_labelPrefix'
        '${Uri.encodeComponent(token.displayLabel)}'
        '$bodyPrefix'
        '${Uri.encodeComponent(token.id)}'
        '$_tokenSuffix';
  }

  List<PersonNoteSegment> parseSegments(String rawText) {
    if (rawText.isEmpty) {
      return const [];
    }

    final segments = <PersonNoteSegment>[];
    var buffer = StringBuffer();
    var index = 0;

    while (index < rawText.length) {
      final parsed = _tryParseToken(rawText, index);
      if (parsed != null) {
        if (buffer.isNotEmpty) {
          segments.add(PersonNoteSegment.text(buffer.toString()));
          buffer = StringBuffer();
        }
        segments.add(PersonNoteSegment.token(parsed.token));
        index = parsed.endIndex;
        continue;
      }

      buffer.writeCharCode(rawText.codeUnitAt(index));
      index += 1;
    }

    if (buffer.isNotEmpty) {
      segments.add(PersonNoteSegment.text(buffer.toString()));
    }

    return segments;
  }

  List<PersonNoteTokenRange> parseTokenRanges(String rawText) {
    if (rawText.isEmpty) {
      return const [];
    }

    final ranges = <PersonNoteTokenRange>[];
    var index = 0;

    while (index < rawText.length) {
      final parsed = _tryParseToken(rawText, index);
      if (parsed != null) {
        ranges.add(
          PersonNoteTokenRange(
            start: index,
            end: parsed.endIndex,
            token: parsed.token,
          ),
        );
        index = parsed.endIndex;
        continue;
      }

      index += 1;
    }

    return ranges;
  }

  ({String text, int caretOffset}) insertToken({
    required String text,
    required int replacementStart,
    required int replacementEnd,
    required PersonNoteToken token,
  }) {
    final normalizedStart = replacementStart.clamp(0, text.length).toInt();
    final normalizedEnd = replacementEnd.clamp(0, text.length).toInt();
    final start = normalizedStart <= normalizedEnd
        ? normalizedStart
        : normalizedEnd;
    final end = normalizedStart <= normalizedEnd
        ? normalizedEnd
        : normalizedStart;
    final encodedToken = encodeToken(token);
    final prefix = start > 0 && !_isWhitespace(text.codeUnitAt(start - 1))
        ? ' '
        : '';
    final suffix = end < text.length && !_isWhitespace(text.codeUnitAt(end))
        ? ' '
        : '';
    final replacement = '$prefix$encodedToken$suffix';
    final updatedText = text.replaceRange(start, end, replacement);

    return (text: updatedText, caretOffset: start + replacement.length);
  }

  ({PersonNoteToken token, int endIndex})? _tryParseToken(
    String rawText,
    int startIndex,
  ) {
    if (!rawText.startsWith(_labelPrefix, startIndex)) {
      return null;
    }

    final labelStart = startIndex + _labelPrefix.length;
    final labelEnd = rawText.indexOf(']', labelStart);
    if (labelEnd < 0) {
      return null;
    }

    final bodyStart = labelEnd;
    final isPersonToken = rawText.startsWith(_personBodyPrefix, bodyStart);
    final isMediaToken = rawText.startsWith(_mediaBodyPrefix, bodyStart);
    if (!isPersonToken && !isMediaToken) {
      return null;
    }

    final idStart =
        bodyStart +
        (isPersonToken ? _personBodyPrefix.length : _mediaBodyPrefix.length);
    final tokenEnd = rawText.indexOf(_tokenSuffix, idStart);
    if (tokenEnd < 0) {
      return null;
    }

    final String label;
    final String id;
    try {
      label = Uri.decodeComponent(rawText.substring(labelStart, labelEnd));
      id = Uri.decodeComponent(rawText.substring(idStart, tokenEnd));
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
    if (id.trim().isEmpty) {
      return null;
    }

    return (
      token: isPersonToken
          ? PersonNoteToken.person(id: id, label: label)
          : PersonNoteToken.media(id: id, label: label),
      endIndex: tokenEnd + _tokenSuffix.length,
    );
  }
}

class PersonNoteTokenRange {
  const PersonNoteTokenRange({
    required this.start,
    required this.end,
    required this.token,
  });

  final int start;
  final int end;
  final PersonNoteToken token;

  bool containsInnerOffset(int offset) {
    return offset > start && offset < end;
  }

  bool overlapsEditRange(int editStart, int editEnd) {
    return editStart < end && editEnd > start;
  }
}

bool _isWhitespace(int codeUnit) {
  return codeUnit == 0x20 || codeUnit == 0x0A || codeUnit == 0x09;
}
