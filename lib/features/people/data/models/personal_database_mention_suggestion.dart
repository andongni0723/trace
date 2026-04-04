import 'package:freezed_annotation/freezed_annotation.dart';

part 'personal_database_mention_suggestion.freezed.dart';

@freezed
abstract class PersonalDatabaseMentionSuggestion
    with _$PersonalDatabaseMentionSuggestion {
  const factory PersonalDatabaseMentionSuggestion({
    required String id,
    required String name,
    required int colorValue,
    String? avatarPath,
  }) = _PersonalDatabaseMentionSuggestion;
}
