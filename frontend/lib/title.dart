import "package:flutter/widgets.dart";
import "package:json_annotation/json_annotation.dart";

part "title.g.dart";

@JsonSerializable()
class Title {
  const Title({
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

  factory Title.fromJson(Map<String, dynamic> json) => _$TitleFromJson(json);
}
