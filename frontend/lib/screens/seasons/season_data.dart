import "package:flutter/widgets.dart";
import "package:frontend/screens/seasons/episode.dart";
import "package:json_annotation/json_annotation.dart";

part "season_data.g.dart";

@JsonSerializable()
class SeasonData {
  SeasonData({
    required this.number,
    required this.episodes,
    this.episodeIndex = 0,
  });

  final int number;
  final List<EpisodeData> episodes;
  final ScrollController scrollController = ScrollController();

  @JsonKey(includeFromJson: false)
  int episodeIndex;

  factory SeasonData.fromJson(Map<String, dynamic> json) =>
      _$SeasonDataFromJson(json);

  Map<String, dynamic> toJson() => _$SeasonDataToJson(this);
}

@JsonSerializable()
class EpisodeData {
  EpisodeData({
    required this.number,
    required this.date,
    required this.name,
    required this.overview,
    required this.runtime,
    required this.still,
  });

  final int number;
  final DateTime? date;
  final String name;
  final String? overview;
  final int? runtime;
  final String? still;
  final key = GlobalKey<EpisodeState>();

  @JsonKey(includeFromJson: false)
  bool? available;

  factory EpisodeData.fromJson(Map<String, dynamic> json) =>
      _$EpisodeDataFromJson(json);

  Map<String, dynamic> toJson() => _$EpisodeDataToJson(this);
}
