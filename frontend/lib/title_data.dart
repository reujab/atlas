import "package:json_annotation/json_annotation.dart";

part "title_data.g.dart";

@JsonSerializable()
class TitleData {
  const TitleData({
    required this.id,
    required this.type,
    required this.title,
    required this.genres,
    required this.overview,
    required this.released,
    required this.trailer,
    required this.rating,
    required this.poster,
  });

  final int id;
  final String type;
  final String title;
  final List<String> genres;
  final String overview;
  final DateTime? released;
  final String? trailer;
  final String? rating;
  final String poster;

  factory TitleData.fromJson(Map<String, dynamic> json) =>
      _$TitleDataFromJson(json);

  Map<String, dynamic> toJson() => _$TitleDataToJson(this);
}
