import 'package:freezed_annotation/freezed_annotation.dart';

part 'person_note_token.freezed.dart';

@freezed
sealed class PersonNoteToken with _$PersonNoteToken {
  const PersonNoteToken._();

  const factory PersonNoteToken.person({
    required String id,
    required String label,
  }) = PersonNotePersonToken;

  const factory PersonNoteToken.media({
    required String id,
    required String label,
  }) = PersonNoteMediaToken;

  String get displayLabel {
    return switch (this) {
      PersonNotePersonToken(:final label) => label,
      PersonNoteMediaToken(:final label) => label,
    };
  }
}

@freezed
sealed class PersonNoteSegment with _$PersonNoteSegment {
  const PersonNoteSegment._();

  const factory PersonNoteSegment.text(String text) = PersonNoteTextSegment;

  const factory PersonNoteSegment.token(PersonNoteToken token) =
      PersonNoteTokenSegment;
}
