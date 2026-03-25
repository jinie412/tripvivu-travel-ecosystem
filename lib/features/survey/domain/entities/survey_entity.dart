import 'package:freezed_annotation/freezed_annotation.dart';

part 'survey_entity.freezed.dart';

@freezed
class SurveyEntity with _$SurveyEntity {
  const factory SurveyEntity({
    int? age,
    String? gender,
    @Default([]) List<String> interests,
  }) = _SurveyEntity;
}
