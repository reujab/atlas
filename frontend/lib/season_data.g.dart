// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeasonData _$SeasonDataFromJson(Map<String, dynamic> json) => SeasonData(
      number: json['number'] as int,
      episodes: (json['episodes'] as List<dynamic>)
          .map((e) => EpisodeData.fromJson(e as Map<String, dynamic>))
          .toList(),
      index: json['index'] as int? ?? 0,
    );

Map<String, dynamic> _$SeasonDataToJson(SeasonData instance) =>
    <String, dynamic>{
      'number': instance.number,
      'episodes': instance.episodes,
      'index': instance.index,
    };

EpisodeData _$EpisodeDataFromJson(Map<String, dynamic> json) => EpisodeData(
      number: json['number'] as int,
      date:
          json['date'] == null ? null : DateTime.parse(json['date'] as String),
      name: json['name'] as String,
      overview: json['overview'] as String?,
      runtime: json['runtime'] as int?,
      still: json['still'] as String?,
    );

Map<String, dynamic> _$EpisodeDataToJson(EpisodeData instance) =>
    <String, dynamic>{
      'number': instance.number,
      'date': instance.date?.toIso8601String(),
      'name': instance.name,
      'overview': instance.overview,
      'runtime': instance.runtime,
      'still': instance.still,
    };
